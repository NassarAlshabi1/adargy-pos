// customer_database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:alhaytham_trade/models/customer.dart';

class CustomerDatabaseHelper {
  static final CustomerDatabaseHelper _instance =
      CustomerDatabaseHelper._internal();
  factory CustomerDatabaseHelper() => _instance;
  CustomerDatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'accounting.db');

    return await openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE customers(
        id INTEGER PRIMARY KEY,
        name TEXT,
        balance REAL,
        isSettled INTEGER DEFAULT 0,
         currency TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER,
        date TEXT,
        item TEXT,
        amount REAL,
        currency TEXT,
        isCredit INTEGER,
        FOREIGN KEY(customerId) REFERENCES customers(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE settlements(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER,
        customerName TEXT,
        settledAmount REAL,
        currency TEXT,
        settlementDate TEXT,
        FOREIGN KEY(customerId) REFERENCES customers(id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE transactions(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customerId INTEGER,
          date TEXT,
          item TEXT,
          amount REAL,
          currency TEXT,
          isCredit INTEGER,
          FOREIGN KEY(customerId) REFERENCES customers(id)
        )
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE settlements(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customerId INTEGER,
          customerName TEXT,
          settledAmount REAL,
          currency TEXT,
          settlementDate TEXT,
          FOREIGN KEY(customerId) REFERENCES customers(id)
        )
      ''');
    }

    if (oldVersion < 4) {
      await db.execute('''
        ALTER TABLE customers ADD COLUMN isSettled INTEGER DEFAULT 0
      ''');
    }

    // إضافة عمود currency إذا لم يكن موجوداً (نسخة 5)
    if (oldVersion < 5) {
      try {
        await db.execute('''
          ALTER TABLE customers ADD COLUMN currency TEXT
        ''');
      } catch (e) {
        // تجاهل الخطأ إذا كان العمود موجود بالفعل
        if (!e.toString().contains('duplicate column name')) {
          rethrow;
        }
      }
    }
  }

  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert('customers', customer.toMap());
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'isSettled = ?',
      whereArgs: [0], // إظهار العملاء غير المسددين فقط
    );
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  Future<List<Customer>> getSettledCustomers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'customers',
      where: 'isSettled = ?',
      whereArgs: [1], // إظهار العملاء المسددين فقط
    );
    return List.generate(maps.length, (i) => Customer.fromMap(maps[i]));
  }

  // تحديث رصيد العميل بناءً على معاملاته
  // الصافي المالي للعميل: يمثل إجمالي المبالغ التي هي "له" (دائن) مطروحًا منها إجمالي المبالغ التي هي "عليه" (مدين)
  Future<void> updateCustomerBalance(int customerId) async {
    final db = await database;
    final transactions = await getTransactions(customerId);

    // حساب إجمالي المبالغ "له" (دائن)
    final double totalCredit = transactions
        .where((t) => t.isCredit)
        .fold(0.0, (sum, t) => sum + t.amount);

    // حساب إجمالي المبالغ "عليه" (مدين)
    final double totalDebit = transactions
        .where((t) => !t.isCredit)
        .fold(0.0, (sum, t) => sum + t.amount);

    // الصافي المالي = له - عليه
    final double netBalance = totalCredit - totalDebit;

    // تحديث الرصيد في قاعدة البيانات
    await db.update(
      'customers',
      {'balance': netBalance},
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }

  Future<void> deleteCustomer(int id) async {
    final db = await database;
    // حذف العميل وجميع البيانات المرتبطة به
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
    await db.delete('transactions', where: 'customerId = ?', whereArgs: [id]);
    await db.delete('settlements', where: 'customerId = ?', whereArgs: [id]);
  }

  Future<int> insertTransaction(TransactionEntry transaction) async {
    final db = await database;
    final id = await db.insert('transactions', transaction.toMap());
    // تحديث رصيد العميل بعد إضافة معاملة جديدة
    await updateCustomerBalance(transaction.customerId);
    return id;
  }

  Future<List<TransactionEntry>> getTransactions(int customerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'date DESC', // الترتيب تنازلي حسب التاريخ
    );
    return List.generate(maps.length, (i) => TransactionEntry.fromMap(maps[i]));
  }

  // تحديث معاملة
  Future<int> updateTransaction(TransactionEntry transaction) async {
    final db = await database;
    final result = await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
    // تحديث رصيد العميل بعد تعديل المعاملة
    await updateCustomerBalance(transaction.customerId);
    return result;
  }

  // حذف معاملة
  Future<int> deleteTransaction(int transactionId) async {
    final db = await database;

    // الحصول على معرف العميل قبل حذف المعاملة
    final List<Map<String, dynamic>> transactionData = await db.query(
      'transactions',
      columns: ['customerId'],
      where: 'id = ?',
      whereArgs: [transactionId],
    );

    if (transactionData.isEmpty) {
      return 0; // المعاملة غير موجودة
    }

    final int customerId = transactionData.first['customerId'];

    // حذف المعاملة
    final result = await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );

    // تحديث رصيد العميل بعد حذف المعاملة
    await updateCustomerBalance(customerId);
    return result;
  }

  // حفظ معلومات السداد
  Future<int> insertSettlement(Map<String, dynamic> settlement) async {
    final db = await database;
    return await db.insert('settlements', settlement);
  }

  // الحصول على جميع السدادات
  Future<List<Map<String, dynamic>>> getAllSettlements() async {
    final db = await database;
    return await db.query('settlements', orderBy: 'settlementDate DESC');
  }

  // الحصول على السدادات لعميل معين
  Future<List<Map<String, dynamic>>> getCustomerSettlements(
      int customerId) async {
    final db = await database;
    return await db.query(
      'settlements',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'settlementDate DESC',
    );
  }

  // تحديد العميل كمسدد
  Future<int> markCustomerAsSettled(int customerId) async {
    final db = await database;
    return await db.update(
      'customers',
      {'isSettled': 1},
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }

  // إلغاء تحديد العميل كمسدد (إعادته للعملاء)
  Future<int> unmarkCustomerAsSettled(int customerId) async {
    final db = await database;
    return await db.update(
      'customers',
      {'isSettled': 0},
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }

  // حذف جميع البيانات (للاستعادة من النسخة الاحتياطية)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('settlements');
    await db.delete('transactions');
    await db.delete('customers');
  }

  // استعادة البيانات من النسخة الاحتياطية
  Future<void> restoreBackupData({
    required List<Map<String, dynamic>> customers,
    required List<Map<String, dynamic>> transactions,
    required List<Map<String, dynamic>> settlements,
  }) async {
    final db = await database;

    // حذف البيانات الحالية
    await clearAllData();

    // استعادة العملاء
    for (var customerData in customers) {
      await db.insert('customers', customerData);
    }

    // استعادة المعاملات
    for (var transactionData in transactions) {
      await db.insert('transactions', transactionData);
    }

    // استعادة السدادات
    for (var settlementData in settlements) {
      await db.insert('settlements', settlementData);
    }
  }

  // جلب العملاء مع معاملاتهم في استعلام واحد محسن
  Future<Map<String, dynamic>> getCustomersWithTransactions() async {
    final db = await database;

    // جلب جميع العملاء غير المسددين
    final List<Map<String, dynamic>> customerMaps = await db.query(
      'customers',
      where: 'isSettled = ?',
      whereArgs: [0],
      orderBy: 'name ASC', // ترتيب حسب الاسم لتحسين الأداء
    );

    final customers = List.generate(
        customerMaps.length, (i) => Customer.fromMap(customerMaps[i]));

    // جلب جميع المعاملات في استعلام واحد محسن
    final List<Map<String, dynamic>> transactionMaps = await db.rawQuery('''
      SELECT t.*, c.name as customerName 
      FROM transactions t 
      INNER JOIN customers c ON t.customerId = c.id 
      WHERE c.isSettled = 0 
      ORDER BY t.date DESC, t.id DESC
    ''');

    // تجميع المعاملات حسب العميل بشكل محسن
    final Map<int, List<TransactionEntry>> transactionsMap = {};
    for (var transactionMap in transactionMaps) {
      final transaction = TransactionEntry.fromMap(transactionMap);
      final customerId = transaction.customerId;

      if (!transactionsMap.containsKey(customerId)) {
        transactionsMap[customerId] = [];
      }
      transactionsMap[customerId]!.add(transaction);
    }

    return {
      'customers': customers,
      'transactions': transactionsMap,
    };
  }
}
