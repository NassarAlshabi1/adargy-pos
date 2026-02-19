import 'package:sqflite/sqflite.dart';

/// ملف يحتوي على دوال إنشاء الجداول والفهارس والبيانات الافتراضية
class DatabaseSchema {
  /// إنشاء جميع الجداول
  static Future<void> createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon INTEGER,
        color INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE group_permissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        section TEXT NOT NULL,
        permission TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(group_id) REFERENCES groups(id) ON DELETE CASCADE,
        UNIQUE(group_id, section, permission)
      );
    ''');

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT CHECK(role IN ('manager','supervisor','employee')),
        group_id INTEGER REFERENCES groups(id),
        employee_code TEXT UNIQUE NOT NULL,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        barcode TEXT UNIQUE,
        price REAL NOT NULL,
        cost REAL NOT NULL DEFAULT 0,
        quantity INTEGER NOT NULL DEFAULT 0,
        min_quantity INTEGER NOT NULL DEFAULT 1,
        category_id INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        total_debt REAL NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        total_payable REAL NOT NULL DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        total REAL NOT NULL,
        profit REAL NOT NULL DEFAULT 0,
        type TEXT NOT NULL CHECK(type IN ('cash','installment','credit')),
        created_at TEXT NOT NULL,
        due_date TEXT,
        down_payment REAL DEFAULT 0,
        FOREIGN KEY(customer_id) REFERENCES customers(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        price REAL NOT NULL,
        cost REAL NOT NULL,
        quantity INTEGER NOT NULL,
        discount_percent REAL NOT NULL DEFAULT 0,
        FOREIGN KEY(sale_id) REFERENCES sales(id),
        FOREIGN KEY(product_id) REFERENCES products(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE installments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        due_date TEXT NOT NULL,
        amount REAL NOT NULL,
        paid INTEGER NOT NULL DEFAULT 0,
        paid_at TEXT,
        FOREIGN KEY(sale_id) REFERENCES sales(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL DEFAULT 'عام',
        description TEXT,
        expense_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shop_name TEXT,
        phone TEXT,
        address TEXT,
        logo_path TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(customer_id) REFERENCES customers(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE supplier_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(supplier_id) REFERENCES suppliers(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE event_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_type TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id INTEGER,
        user_id INTEGER,
        username TEXT,
        description TEXT NOT NULL,
        details TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(user_id) REFERENCES users(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE deleted_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entity_type TEXT NOT NULL,
        entity_id INTEGER NOT NULL,
        original_data TEXT NOT NULL,
        deleted_by_user_id INTEGER,
        deleted_by_username TEXT,
        deleted_at TEXT NOT NULL,
        can_restore INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY(deleted_by_user_id) REFERENCES users(id)
      );
    ''');

    // جدول خصومات المنتجات
    await db.execute('''
      CREATE TABLE IF NOT EXISTS product_discounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        discount_percent REAL NOT NULL DEFAULT 0,
        discount_amount REAL,
        start_date TEXT,
        end_date TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
      );
    ''');

    // جدول كوبونات الخصم
    await db.execute('''
      CREATE TABLE IF NOT EXISTS discount_coupons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        discount_type TEXT NOT NULL CHECK(discount_type IN ('percent','amount')),
        discount_value REAL NOT NULL,
        min_purchase_amount REAL DEFAULT 0,
        max_discount_amount REAL,
        usage_limit INTEGER,
        used_count INTEGER NOT NULL DEFAULT 0,
        start_date TEXT,
        end_date TEXT,
        active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      );
    ''');

    // جدول المرتجعات
    await db.execute('''
      CREATE TABLE IF NOT EXISTS returns (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        reason TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY(sale_id) REFERENCES sales(id),
        FOREIGN KEY(product_id) REFERENCES products(id)
      );
    ''');
  }

  /// إنشاء الفهارس لتحسين الأداء
  static Future<void> createIndexes(Database db) async {
    // Products
    if (await _tableExists(db, 'products')) {
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode)');
      // فهرس للبحث في الأسماء (لتحسين LIKE queries)
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_products_name ON products(name)');
      // فهرس للترتيب حسب التاريخ
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_products_created_at ON products(created_at)');
    }

    // Sales
    if (await _tableExists(db, 'sales')) {
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_sales_customer ON sales(customer_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_sales_created_at ON sales(created_at)');
      await db
          .execute('CREATE INDEX IF NOT EXISTS idx_sales_type ON sales(type)');
    }

    // Sale Items
    if (await _tableExists(db, 'sale_items')) {
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON sale_items(sale_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_sale_items_product ON sale_items(product_id)');
    }

    // Installments
    if (await _tableExists(db, 'installments')) {
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_installments_sale ON installments(sale_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_installments_due_date ON installments(due_date)');
    }

    // Payments
    if (await _tableExists(db, 'payments')) {
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_payments_customer ON payments(customer_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_payments_date ON payments(payment_date)');
    }

    // Customers - فهارس للبحث
    if (await _tableExists(db, 'customers')) {
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone)');
    }

    // Suppliers - فهارس للبحث
    if (await _tableExists(db, 'suppliers')) {
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_suppliers_name ON suppliers(name)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_suppliers_phone ON suppliers(phone)');
    }

    // Event Log
    if (await _tableExists(db, 'event_log')) {
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_event_log_created_at ON event_log(created_at)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_event_log_event_type ON event_log(event_type)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_event_log_entity_type ON event_log(entity_type)');
      final hasUserId = await _columnExists(db, 'event_log', 'user_id');
      if (hasUserId) {
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_event_log_user_id ON event_log(user_id)');
      }
    }
  }

  /// إنشاء البيانات الافتراضية
  static Future<void> seedData(
      Database db, String Function(String) sha256Hex) async {
    // التأكد من عدم وجود المستخدم الموحد القديم للتوافق مع الإصدارات القديمة
    final existingAdmin = await db.query('users',
        where: 'username = ?', whereArgs: ['admin'], limit: 1);

    if (existingAdmin.isNotEmpty) {
      // حذف المستخدم القديم "admin" لأنه يسبب تضارب
      await db.delete('users', where: 'username = ?', whereArgs: ['admin']);
    }
  }

  /// التحقق من وجود عمود في جدول
  static Future<bool> _columnExists(
      Database db, String tableName, String columnName) async {
    try {
      final columns = await db.rawQuery("PRAGMA table_info('$tableName')");
      return columns.any((col) => col['name']?.toString() == columnName);
    } catch (e) {
      return false;
    }
  }

  /// التحقق من وجود جدول
  static Future<bool> _tableExists(Database db, String tableName) async {
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [tableName],
      );
      return tables.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
