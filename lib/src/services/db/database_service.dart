import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/user_model.dart';
import 'database_schema.dart';
import 'database_migrations.dart';

class DatabaseService {
  static const String _dbName = 'pos_office.db';
  static const int _dbVersion = 15;

  late Database _db;
  late String _dbPath;

  Database get database => _db;
  String get databasePath => _dbPath;

  Future<void> initialize() async {
    // تهيئة قاعدة البيانات حسب المنصة
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // للمنصات المكتبية - استخدم sqflite_common_ffi
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    } else {
      // للمنصات المحمولة (Android/iOS) - استخدم sqflite العادي
    }

    final Directory appDir = await getApplicationDocumentsDirectory();
    final String dbPath = p.join(appDir.path, _dbName);
    _dbPath = dbPath;
    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await DatabaseSchema.createSchema(db);
        await DatabaseSchema.seedData(db, _sha256Hex);
        await DatabaseSchema.createIndexes(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // تشغيل جميع الترحيلات المطلوبة
        await DatabaseMigrations.runMigrations(db, oldVersion, newVersion);
        await DatabaseSchema.createIndexes(db);
      },
      onOpen: (db) async {
        // التحقق من وجود الجداول المهمة عند فتح قاعدة البيانات
        await _ensureEventLogTable(db);
        await _ensureReturnsTable(db);
        // التأكد من أن جدول returns يحتوي على جميع الأعمدة المطلوبة
        await _ensureReturnsTableColumns(db);
        // التأكد من وجود حقل status
        await _ensureReturnsStatusColumn(db);
        // التأكد من وجود جدول deleted_items
        await _ensureDeletedItemsTable(db);
        // التأكد من وجود عمود expense_date في جدول expenses
        await _ensureExpensesTableColumns(db);
        // التأكد من وجود جداول الخصومات والكوبونات
        await _ensureDiscountTables(db);
        // التأكد من وجود جدول supplier_payments
        await _ensureSupplierPaymentsTable(db);
      },
    );
    // إعدادات أساسية فقط
    await _db.execute('PRAGMA foreign_keys = ON');

    // التحقق من وجود الجداول المهمة وإنشائها إذا لم تكن موجودة
    await _ensureEventLogTable(_db);
    await _ensureReturnsTable();
    // التأكد من أن جدول returns يحتوي على جميع الأعمدة المطلوبة
    await _ensureReturnsTableColumns(_db);
    // التأكد من وجود حقل status
    await _ensureReturnsStatusColumn(_db);
    // التأكد من وجود جدول deleted_items
    await _ensureDeletedItemsTable(_db);
    // التأكد من وجود عمود expense_date في جدول expenses
    await _ensureExpensesTableColumns(_db);
    // التأكد من وجود جداول الخصومات والكوبونات
    await _ensureDiscountTables(_db);
    // التأكد من وجود جدول supplier_payments
    await _ensureSupplierPaymentsTable(_db);

    await DatabaseSchema.createIndexes(_db);

    // فحص وإصلاح المستخدمين الافتراضيين فقط
    await _checkAndFixDefaultUsers();
  }

  Future<void> reopen() async {
    await _db.close();
    _db = await openDatabase(_dbPath, version: _dbVersion);
    await _db.execute('PRAGMA foreign_keys = ON');

    // التحقق من وجود جدول event_log وإنشاؤه إذا لم يكن موجوداً
    await _ensureEventLogTable(_db);
    await _ensureReturnsTable();
    await _ensureReturnsTableColumns(_db);
    await _ensureReturnsStatusColumn(_db);
    await _ensureDeletedItemsTable(_db);
    // التأكد من وجود جداول الخصومات والكوبونات
    await _ensureDiscountTables(_db);
    // التأكد من وجود جدول supplier_payments
    await _ensureSupplierPaymentsTable(_db);

    await DatabaseSchema.createIndexes(_db);
    await _cleanupOrphanObjects(_db);
    await _ensureCategorySchemaOn(_db);
    await _ensureSaleItemsDiscountColumn(_db);
    await _checkAndFixDefaultUsers();
    await cleanupSalesOldReferences();
  }

  /// فحص وإصلاح المستخدمين الافتراضيين (manager/supervisor/employee)
  Future<void> _checkAndFixDefaultUsers() async {
    try {
      debugPrint('بدء فحص المستخدمين الافتراضيين...');

      final now = DateTime.now().toIso8601String();

      // جلب جميع المستخدمين الحاليين
      final existingUsers = await _db.query('users');

      // تحويلهم إلى خريطة حسب الدور
      final Map<String, Map<String, Object?>> byRole = {};
      for (final u in existingUsers) {
        final role = (u['role'] ?? '').toString();
        if (role.isEmpty) continue;
        // نأخذ أول مستخدم لكل دور فقط
        byRole.putIfAbsent(role, () => u);
      }

      // بيانات المستخدمين الافتراضية (بدون كلمة مرور)
      final defaultUsers = DefaultUsers.getUsersForDatabase();

      Future<void> ensureUser({
        required String role,
        required String defaultUsername,
        required String defaultPassword,
      }) async {
        final existing = byRole[role];
        if (existing == null) {
          // لا يوجد مستخدم بهذا الدور -> إنشاء مستخدم جديد
          final template = defaultUsers.firstWhere((u) => u['role'] == role,
              orElse: () => {});
          if (template.isEmpty) return;

          final data = Map<String, Object?>.from(template);
          data['username'] = defaultUsername;
          data['password'] = _sha256Hex(defaultPassword);
          data['created_at'] = now;
          data['updated_at'] = now;
          data['active'] = 1;

          await _db.insert('users', data);
          debugPrint('تم إنشاء مستخدم جديد للدور: $role');
        } else {
          // يوجد مستخدم -> نضمن على الأقل اسم المستخدم وكلمة المرور الافتراضية
          final id = existing['id'];
          if (id == null) return;

          final updates = <String, Object?>{
            'updated_at': now,
            'active': 1,
          };

          // توحيد اسم المستخدم إلى القيمة الافتراضية (لتطابق شاشة الدخول)
          updates['username'] = defaultUsername;

          // فرض كلمة المرور الافتراضية المطلوبة
          updates['password'] = _sha256Hex(defaultPassword);

          await _db.update(
            'users',
            updates,
            where: 'id = ?',
            whereArgs: [id],
          );
          debugPrint('تم تحديث مستخدم: $role');
        }
      }

      // المدير
      await ensureUser(
        role: 'manager',
        defaultUsername: 'manager',
        defaultPassword: 'man2026',
      );

      // المشرف
      await ensureUser(
        role: 'supervisor',
        defaultUsername: 'supervisor',
        defaultPassword: 'sup2026',
      );

      // الموظف
      await ensureUser(
        role: 'employee',
        defaultUsername: 'employee',
        defaultPassword: 'emp2026',
      );

      debugPrint('انتهى فحص وإصلاح المستخدمين الافتراضيين');
    } catch (e) {
      // في حال حدوث خطأ، لا نمنع التطبيق من العمل
      debugPrint('فشل فحص/إصلاح المستخدمين الافتراضيين: $e');
    }
  }

  /// Ensure discount_percent column exists on sale_items
  Future<void> _ensureSaleItemsDiscountColumn(DatabaseExecutor db) async {
    try {
      final cols = await db.rawQuery("PRAGMA table_info('sale_items')");
      final hasDiscount =
          cols.any((c) => (c['name']?.toString() ?? '') == 'discount_percent');
      if (!hasDiscount) {
        await db.execute(
            "ALTER TABLE sale_items ADD COLUMN discount_percent REAL NOT NULL DEFAULT 0");
      }
    } catch (e) {
      // ignore
    }
  }

  /// Ensure discount tables exist
  Future<void> ensureDiscountTables() async {
    await _ensureDiscountTables(_db);
  }

  /// Ensure discount tables exist (internal)
  Future<void> _ensureDiscountTables(DatabaseExecutor db) async {
    try {
      // التحقق من وجود الجدول أولاً
      final productDiscountsTable = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='product_discounts'");
      if (productDiscountsTable.isEmpty) {
        // إنشاء جدول خصومات المنتجات
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
      }

      final discountCouponsTable = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='discount_coupons'");
      if (discountCouponsTable.isEmpty) {
        // إنشاء جدول كوبونات الخصم
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
      }

      // إضافة حقول الكوبون إلى جدول sales إن لم تكن موجودة
      try {
        final salesCols = await db.rawQuery("PRAGMA table_info('sales')");
        final hasCouponId =
            salesCols.any((c) => (c['name']?.toString() ?? '') == 'coupon_id');
        if (!hasCouponId) {
          await db.execute('ALTER TABLE sales ADD COLUMN coupon_id INTEGER');
        }
        final hasCouponDiscount = salesCols
            .any((c) => (c['name']?.toString() ?? '') == 'coupon_discount');
        if (!hasCouponDiscount) {
          await db.execute(
              'ALTER TABLE sales ADD COLUMN coupon_discount REAL DEFAULT 0');
        }
      } catch (e) {
        // تجاهل الأخطاء في إضافة الأعمدة
      }

      // إنشاء الفهارس
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_product_discounts_product_id ON product_discounts(product_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_product_discounts_active ON product_discounts(active)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_discount_coupons_code ON discount_coupons(code)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_discount_coupons_active ON discount_coupons(active)');
    } catch (e) {
      // لا نعيد throw لأننا نريد أن يستمر التطبيق حتى لو فشل إنشاء الجداول
    }
  }

  /// Ensure event_log table exists
  Future<void> _ensureEventLogTable(DatabaseExecutor db) async {
    try {
      // التحقق من وجود الجدول
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='event_log'");

      if (tables.isEmpty) {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS event_log (
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

        // إنشاء الفهارس
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_event_log_created_at ON event_log(created_at)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_event_log_event_type ON event_log(event_type)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_event_log_entity_type ON event_log(entity_type)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_event_log_user_id ON event_log(user_id)');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Force a complete cleanup of orphaned database objects
  /// This method can be called to resolve database corruption issues
  Future<void> forceCleanup() async {
    try {
      await DatabaseMigrations.runMigrations(_db, 1, _dbVersion);
      await DatabaseSchema.createIndexes(_db);
    } catch (e) {
      rethrow;
    }
  }

  /// إصلاح جدول installments إذا كان يحتوي على مراجع خاطئة
  Future<void> fixInstallmentsTable() async {
    try {
      await _db.execute('PRAGMA foreign_keys = OFF');

      final installmentsSchema = await _db.rawQuery(
          "SELECT sql FROM sqlite_master WHERE type='table' AND name='installments'");
      if (installmentsSchema.isNotEmpty) {
        final schema = installmentsSchema.first['sql']?.toString() ?? '';
        if (schema.contains('sales_old')) {
          // حفظ البيانات الموجودة
          final existingData = await _db.rawQuery('SELECT * FROM installments');

          // حذف الجدول القديم
          await _db.execute('DROP TABLE installments');

          // إنشاء الجدول الجديد
          await _db.execute('''
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

          // استعادة البيانات
          for (final row in existingData) {
            await _db.insert('installments', {
              'id': row['id'],
              'sale_id': row['sale_id'],
              'due_date': row['due_date'],
              'amount': row['amount'],
              'paid': row['paid'],
              'paid_at': row['paid_at'],
            });
          }
        } else {}
      } else {}

      await _db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      await _db.execute('PRAGMA foreign_keys = ON');
      rethrow;
    }
  }

  /// Clean up sales_old references specifically
  Future<void> cleanupSalesOldReferences() async {
    try {
      await _db.execute('PRAGMA foreign_keys = OFF');

      // Drop sales_old table if exists
      await _db.execute('DROP TABLE IF EXISTS sales_old');

      // Find and drop all objects referencing sales_old
      final orphanObjects = await _db.rawQuery('''
        SELECT type, name FROM sqlite_master 
        WHERE type IN ('trigger', 'view', 'index') 
        AND (IFNULL(sql,'') LIKE '%sales_old%' OR name LIKE '%sales_old%')
      ''');

      for (final row in orphanObjects) {
        final type = row['type']?.toString();
        final name = row['name']?.toString();
        if (type != null && name != null && name.isNotEmpty) {
          try {
            String dropCommand;
            switch (type) {
              case 'view':
                dropCommand = 'DROP VIEW IF EXISTS $name';
                break;
              case 'index':
                dropCommand = 'DROP INDEX IF EXISTS $name';
                break;
              case 'trigger':
                dropCommand = 'DROP TRIGGER IF EXISTS $name';
                break;
              default:
                continue;
            }
            await _db.execute(dropCommand);
          } catch (e) {
            // Continue with other objects even if one fails
          }
        }
      }

      await _db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      await _db.execute('PRAGMA foreign_keys = ON');
      rethrow;
    }
  }

  /// Debug function to check customer deletion status
  Future<Map<String, dynamic>> debugCustomerDeletion(int customerId) async {
    final result = <String, dynamic>{};

    try {
      // Check if customer exists
      final customer = await _db
          .query('customers', where: 'id = ?', whereArgs: [customerId]);
      result['customer_exists'] = customer.isNotEmpty;

      if (customer.isNotEmpty) {
        result['customer_data'] = customer.first;
      }

      // Check related sales
      final sales = await _db
          .query('sales', where: 'customer_id = ?', whereArgs: [customerId]);
      result['sales_count'] = sales.length;
      result['sales_data'] = sales;

      // Check related payments
      final payments = await _db
          .query('payments', where: 'customer_id = ?', whereArgs: [customerId]);
      result['payments_count'] = payments.length;
      result['payments_data'] = payments;

      // Check related installments
      final installments = await _db.rawQuery('''
        SELECT i.* FROM installments i
        JOIN sales s ON s.id = i.sale_id
        WHERE s.customer_id = ?
      ''', [customerId]);
      result['installments_count'] = installments.length;
      result['installments_data'] = installments;

      // Check related sale_items
      final saleItems = await _db.rawQuery('''
        SELECT si.* FROM sale_items si
        JOIN sales s ON s.id = si.sale_id
        WHERE s.customer_id = ?
      ''', [customerId]);
      result['sale_items_count'] = saleItems.length;
      result['sale_items_data'] = saleItems;
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

  /// Aggressive cleanup that rebuilds sale_items table if necessary
  Future<void> aggressiveCleanup() async {
    try {
      await _db.execute('PRAGMA foreign_keys = OFF');

      // First, try the normal cleanup
      await _cleanupOrphanObjects(_db);

      // Clean up orphaned records in sale_items
      try {
        await _db.execute('''
          DELETE FROM sale_items 
          WHERE sale_id NOT IN (SELECT id FROM sales)
          OR product_id NOT IN (SELECT id FROM products)
        ''');
      } catch (e) {}

      // If that doesn't work, completely rebuild sale_items
      try {
        // Check if sale_items exists and is corrupted
        final saleItemsCheck = await _db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='sale_items'");

        if (saleItemsCheck.isNotEmpty) {
          // Backup existing data
          final existingData = await _db.rawQuery('SELECT * FROM sale_items');

          // Drop and recreate the table
          await _db.execute('DROP TABLE sale_items');

          // Recreate with proper structure
          await _db.execute('''
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

          // Restore data if any
          if (existingData.isNotEmpty) {
            for (final row in existingData) {
              await _db.insert('sale_items', {
                'sale_id': row['sale_id'],
                'product_id': row['product_id'],
                'price': row['price'],
                'cost': row['cost'],
                'quantity': row['quantity'],
              });
            }
          }
        }
      } catch (e) {
        // If even this fails, we might be in a bad state
        // Consider logging or notifying the user
      }

      // Ensure all core tables exist
      await _db.execute('''
        CREATE TABLE IF NOT EXISTS sales (
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

      await _db.execute('''
        CREATE TABLE IF NOT EXISTS sale_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sale_id INTEGER NOT NULL,
          product_id INTEGER NOT NULL,
          price REAL NOT NULL,
          cost REAL NOT NULL,
          quantity INTEGER NOT NULL,
          FOREIGN KEY(sale_id) REFERENCES sales(id),
          FOREIGN KEY(product_id) REFERENCES products(id)
        );
      ''');

      // Recreate indexes
      await DatabaseSchema.createIndexes(_db);

      // Re-enable foreign keys
      await _db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      // Ensure foreign keys are re-enabled
      try {
        await _db.execute('PRAGMA foreign_keys = ON');
      } catch (_) {}
      rethrow;
    }
  }

  /// Check database integrity and return any issues found
  Future<List<String>> checkDatabaseIntegrity() async {
    final issues = <String>[];

    try {
      // Check for sales_old table
      final salesOldCheck = await _db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='sales_old'");
      if (salesOldCheck.isNotEmpty) {
        issues.add('Found orphaned sales_old table');
      }

      // Check for objects referencing sales_old in main schema
      final salesOldRefs = await _db.rawQuery('''
        SELECT type, name FROM sqlite_master 
        WHERE type IN ('trigger', 'view', 'index') 
        AND IFNULL(sql,'') LIKE '%sales_old%'
      ''');
      if (salesOldRefs.isNotEmpty) {
        issues.add(
            'Found ${salesOldRefs.length} objects referencing sales_old in main schema');
      }

      // Check for objects referencing sales_old in temp schema
      final tempSalesOldRefs = await _db.rawQuery('''
        SELECT type, name FROM sqlite_temp_master 
        WHERE type IN ('trigger', 'view', 'index') 
        AND IFNULL(sql,'') LIKE '%sales_old%'
      ''');
      if (tempSalesOldRefs.isNotEmpty) {
        issues.add(
            'Found ${tempSalesOldRefs.length} objects referencing sales_old in temp schema');
      }

      // Check if sale_items is a view instead of table
      final saleItemsType = await _db.rawQuery(
          "SELECT type FROM sqlite_master WHERE name='sale_items' LIMIT 1");
      if (saleItemsType.isNotEmpty && saleItemsType.first['type'] == 'view') {
        issues.add('sale_items is a view instead of a table');
      }

      // Check if sale_items table exists
      final saleItemsExists = await _db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='sale_items'");
      if (saleItemsExists.isEmpty) {
        issues.add('sale_items table is missing');
      }

      // Check foreign key constraints
      final fkCheck = await _db.rawQuery('PRAGMA foreign_key_check');
      if (fkCheck.isNotEmpty) {
        issues.add('Found ${fkCheck.length} foreign key constraint violations');
      }

      // Check for orphaned records in sale_items
      final orphanedSaleItems = await _db.rawQuery('''
        SELECT COUNT(*) as count FROM sale_items si
        LEFT JOIN sales s ON si.sale_id = s.id
        WHERE s.id IS NULL
      ''');
      final orphanedCount = orphanedSaleItems.first['count'] as int;
      if (orphanedCount > 0) {
        issues.add('Found $orphanedCount orphaned sale_items records');
      }

      // Check for orphaned records in sale_items with products
      final orphanedProductItems = await _db.rawQuery('''
        SELECT COUNT(*) as count FROM sale_items si
        LEFT JOIN products p ON si.product_id = p.id
        WHERE p.id IS NULL
      ''');
      final orphanedProductCount = orphanedProductItems.first['count'] as int;
      if (orphanedProductCount > 0) {
        issues.add(
            'Found $orphanedProductCount sale_items with missing products');
      }
    } catch (e) {
      issues.add('Error checking database integrity: $e');
    }

    return issues;
  }

  /// Debug method to find all references to sales_old
  Future<Map<String, dynamic>> debugSalesOldReferences() async {
    final result = <String, dynamic>{};

    try {
      // Get all objects in main schema
      final mainObjects = await _db.rawQuery('''
        SELECT type, name, sql FROM sqlite_master 
        WHERE IFNULL(sql,'') LIKE '%sales_old%' OR name LIKE '%sales_old%'
        ORDER BY type, name
      ''');
      result['main_schema'] = mainObjects;

      // Get all objects in temp schema
      final tempObjects = await _db.rawQuery('''
        SELECT type, name, sql FROM sqlite_temp_master 
        WHERE IFNULL(sql,'') LIKE '%sales_old%' OR name LIKE '%sales_old%'
        ORDER BY type, name
      ''');
      result['temp_schema'] = tempObjects;

      // Get all triggers
      final allTriggers = await _db.rawQuery('''
        SELECT name, sql FROM sqlite_master WHERE type='trigger'
        UNION ALL
        SELECT name, sql FROM sqlite_temp_master WHERE type='trigger'
      ''');
      result['all_triggers'] = allTriggers;

      // Get table info for sale_items
      final saleItemsInfo = await _db.rawQuery('''
        SELECT * FROM sqlite_master WHERE name='sale_items'
      ''');
      result['sale_items_info'] = saleItemsInfo;

      // Get foreign key info
      final fkInfo = await _db.rawQuery('PRAGMA foreign_key_list(sale_items)');
      result['sale_items_fk'] = fkInfo;
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

  /// Emergency method to completely reset sale_items table
  /// Use this only if all other cleanup methods fail
  Future<void> emergencyResetSaleItems() async {
    try {
      await _db.execute('PRAGMA foreign_keys = OFF');

      // Get all existing data
      final existingData = await _db.rawQuery('SELECT * FROM sale_items');

      // Drop the table completely
      await _db.execute('DROP TABLE IF EXISTS sale_items');

      // Recreate with clean structure
      await _db.execute('''
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

      // Restore data
      for (final row in existingData) {
        await _db.insert('sale_items', {
          'sale_id': row['sale_id'],
          'product_id': row['product_id'],
          'price': row['price'],
          'cost': row['cost'],
          'quantity': row['quantity'],
        });
      }

      // Re-enable foreign keys
      await _db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      try {
        await _db.execute('PRAGMA foreign_keys = ON');
      } catch (_) {}
      rethrow;
    }
  }

  // تم نقل _migrateToV2 إلى database_migrations.dart

  Future<void> _cleanupOrphanObjects(Database db) async {
    try {
      // Disable foreign keys temporarily for cleanup
      await db.execute('PRAGMA foreign_keys = OFF');

      // Drop leftover temporary renamed table if present
      try {
        await db.execute('DROP TABLE IF EXISTS sales_old');
      } catch (_) {}

      // إصلاح جدول installments إذا كان يحتوي على مراجع خاطئة
      try {
        final installmentsSchema = await db.rawQuery(
            "SELECT sql FROM sqlite_master WHERE type='table' AND name='installments'");
        if (installmentsSchema.isNotEmpty) {
          final schema = installmentsSchema.first['sql']?.toString() ?? '';
          if (schema.contains('sales_old')) {
            // حفظ البيانات الموجودة
            final existingData =
                await db.rawQuery('SELECT * FROM installments');

            // حذف الجدول القديم
            await db.execute('DROP TABLE installments');

            // إنشاء الجدول الجديد
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

            // استعادة البيانات
            for (final row in existingData) {
              await db.insert('installments', {
                'id': row['id'],
                'sale_id': row['sale_id'],
                'due_date': row['due_date'],
                'amount': row['amount'],
                'paid': row['paid'],
                'paid_at': row['paid_at'],
              });
            }
          }
        }
      } catch (e) {
        // ignore
      }

      // Get all database objects that might reference sales_old
      final allObjects = await db.rawQuery('''
        SELECT type, name, sql FROM sqlite_master 
        WHERE type IN ('trigger', 'view', 'index', 'table') 
        AND (IFNULL(sql,'') LIKE '%sales_old%' OR name = 'sales_old')
        UNION ALL
        SELECT type, name, sql FROM sqlite_temp_master 
        WHERE type IN ('trigger', 'view', 'index', 'table') 
        AND (IFNULL(sql,'') LIKE '%sales_old%' OR name = 'sales_old')
      ''');

      for (final row in allObjects) {
        final type = row['type']?.toString();
        final name = row['name']?.toString();
        if (type != null && name != null && name.isNotEmpty) {
          try {
            String dropCommand;
            switch (type) {
              case 'view':
                dropCommand = 'DROP VIEW IF EXISTS $name';
                break;
              case 'index':
                dropCommand = 'DROP INDEX IF EXISTS $name';
                break;
              case 'trigger':
                dropCommand = 'DROP TRIGGER IF EXISTS $name';
                break;
              case 'table':
                if (name == 'sales_old') {
                  dropCommand = 'DROP TABLE IF EXISTS $name';
                } else {
                  continue; // Skip other tables
                }
                break;
              default:
                continue;
            }
            await db.execute(dropCommand);
          } catch (_) {}
        }
      }

      // Drop any triggers on sale_items (we don't use triggers in current schema)
      final saleItemsTriggers = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='trigger' AND tbl_name='sale_items'");
      for (final row in saleItemsTriggers) {
        final name = row['name']?.toString();
        if (name != null && name.isNotEmpty) {
          try {
            await db.execute('DROP TRIGGER IF EXISTS $name');
          } catch (_) {}
        }
      }

      // Ensure sale_items is a real table (not a leftover view)
      final saleItemsObj = await db.rawQuery(
          "SELECT type FROM sqlite_master WHERE name='sale_items' LIMIT 1");
      if (saleItemsObj.isNotEmpty && saleItemsObj.first['type'] == 'view') {
        try {
          await db.execute('DROP VIEW IF EXISTS sale_items');
        } catch (_) {}
      }

      // Re-ensure core tables exist with proper structure
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sales (
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
        CREATE TABLE IF NOT EXISTS sale_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sale_id INTEGER NOT NULL,
          product_id INTEGER NOT NULL,
          price REAL NOT NULL,
          cost REAL NOT NULL,
          quantity INTEGER NOT NULL,
          FOREIGN KEY(sale_id) REFERENCES sales(id),
          FOREIGN KEY(product_id) REFERENCES products(id)
        );
      ''');

      // Re-enable foreign keys
      await db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      // Ensure foreign keys are re-enabled even if cleanup fails
      try {
        await db.execute('PRAGMA foreign_keys = ON');
      } catch (_) {}
      // best-effort cleanup
    }
  }

  /// التحقق من وجود عمود في جدول
  Future<bool> _columnExists(
      Database db, String tableName, String columnName) async {
    try {
      final columns = await db.rawQuery("PRAGMA table_info('$tableName')");
      return columns.any((col) => col['name']?.toString() == columnName);
    } catch (e) {
      return false;
    }
  }

  // تم نقل _createIndexes و _createSchema إلى database_schema.dart

  Future<void> _ensureCategorySchemaOn(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon INTEGER,
        color INTEGER
      );
    ''');

    // التحقق من وجود العمود قبل إضافته
    try {
      final cols = await db.rawQuery("PRAGMA table_info('products')");
      final hasCategoryId =
          cols.any((c) => (c['name']?.toString() ?? '') == 'category_id');

      if (!hasCategoryId) {
        await db.execute('ALTER TABLE products ADD COLUMN category_id INTEGER');
        print('Added category_id column to products table');
      } else {
        print('category_id column already exists in products table');
      }
    } catch (e) {
      print('Error checking/adding category_id column: $e');
      // column already exists or other error
    }
  }

  // تم نقل جميع دوال _migrateToV* و _seedData إلى database_migrations.dart و database_schema.dart

  // Simple helpers for common queries used early in development
  Future<Map<String, Object?>?> findUserByCredentials(
      String username, String password) async {
    // جلب المستخدم بالاسم والتأكد من كونه فعّالاً
    final result = await _db.query(
      'users',
      where: 'username = ? AND active = 1',
      whereArgs: [username],
      limit: 1,
    );

    if (result.isEmpty) {
      debugPrint('لم يتم العثور على مستخدم فعّال بهذا الاسم');
      return null;
    }

    final user = result.first;
    final stored = (user['password'] ?? '').toString();

    // تحقق كلمة المرور: دعم نص صريح تاريخي أو SHA-256 سداسي حديث
    bool matches = false;
    try {
      // حساب SHA-256 للنص المدخل
      // ملاحظة: نستخدم crypto في طبقة أعلى لتجنّب استيراد هنا إذا لم يكن ضرورياً،
      // لكن لأجل الاكتفاء الذاتي سنحوّل هنا باستخدام صيغة بسيطة عبر دارت.
      // سنستخدم صيغة مقارنة ثنائية: إذا تخزين سداسي بطول 64 ويماثل هاش الإدخال.
      final hashed = _sha256Hex(password);
      final isHex64 =
          RegExp(r'^[a-f0-9]{64} ?$', caseSensitive: false).hasMatch(stored);
      if (stored == password) {
        matches = true; // توافق نص صريح قديم
      } else if (isHex64 && stored.toLowerCase() == hashed) {
        matches = true; // توافق كلمة مرور مهدّدة SHA-256
      } else {
        matches = false;
      }
    } catch (_) {
      matches = stored == password;
    }

    if (!matches) {
      debugPrint('بيانات الدخول غير صحيحة للمستخدم: $username');
      return null;
    }

    return user;
  }

  // حساب SHA-256 وإرجاعه كنص سداسي صغير الأحرف
  String _sha256Hex(String input) {
    // تجنّب إضافة تبعية مباشرة هنا: سنستدعي crypto عبر MethodChannel ليس مناسباً.
    // لذلك سنستخدم dart:convert و package:crypto في أعلى الملف إن كانت مستوردة.
    // لضمان العمل حتى إن لم تتوفر، نتحقق ديناميكياً عبر try/catch في الاستدعاء.
    // هنا نفترض تواجد crypto حسب pubspec.
    // ignore: avoid_print
    try {
      // سيستبدل Dart المحوّل عند البناء حسب الاستيراد أعلى الملف
      // نكتب الاستدعاءات بشكل منعزل لتجنب أخطاء إن لم تتوفر.
      // سيتم حقن الدوال فعلياً عبر imports الموجودة في الملف.
    } catch (_) {}
    // تنفيذ فعلي باستخدام crypto
    // سيتم حقنه عبر imports أعلى الملف: import 'dart:convert'; import 'package:crypto/crypto.dart';
    // نستخدم dynamic للسلامة في التحويل بدون إنكسار عند تحليل ثابت
    final dynamic utf8Dyn = utf8;
    final dynamic sha256Dyn = sha256;
    final bytes = utf8Dyn.encode(input) as List<int>;
    final digest = sha256Dyn.convert(bytes);
    return digest.toString();
  }

  // updateUserPassword removed: password changes are disabled

  Future<List<Map<String, Object?>>> getAllProducts({
    String? query,
    int? categoryId,
    int? limit,
    int? offset,
  }) async {
    final where = <String>[];
    final args = <Object?>[];
    if (query != null && query.trim().isNotEmpty) {
      final like = '%${query.trim()}%';
      where.add('(name LIKE ? OR barcode LIKE ?)');
      args.addAll([like, like]);
    }
    if (categoryId != null) {
      where.add('category_id = ?');
      args.add(categoryId);
    }
    return _db.query(
      'products',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: where.isEmpty ? null : args,
      orderBy: 'id DESC',
      limit: limit,
      offset: offset,
    );
  }

  /// الحصول على عدد المنتجات (للمساعدة في pagination)
  Future<int> getProductsCount({String? query, int? categoryId}) async {
    final where = <String>[];
    final args = <Object?>[];
    if (query != null && query.trim().isNotEmpty) {
      final like = '%${query.trim()}%';
      where.add('(name LIKE ? OR barcode LIKE ?)');
      args.addAll([like, like]);
    }
    if (categoryId != null) {
      where.add('category_id = ?');
      args.add(categoryId);
    }
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM products ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}',
      where.isEmpty ? [] : args,
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> insertProduct(Map<String, Object?> values,
      {int? userId, String? username}) async {
    // التحقق من صحة البيانات
    if (values['name'] == null ||
        (values['name'] as String?)?.trim().isEmpty == true) {
      throw Exception('اسم المنتج مطلوب');
    }
    final price = (values['price'] as num?)?.toDouble() ?? 0.0;
    if (values['price'] == null || price < 0) {
      throw Exception('السعر يجب أن يكون أكبر من أو يساوي صفر');
    }
    final quantity = (values['quantity'] as int?) ?? 0;
    if (values['quantity'] == null || quantity < 0) {
      throw Exception('الكمية يجب أن تكون أكبر من أو تساوي صفر');
    }

    // التحقق من الباركود إذا كان موجوداً
    if (values['barcode'] != null &&
        (values['barcode'] as String?)?.trim().isNotEmpty == true) {
      final barcode = (values['barcode'] as String).trim();
      if (await isBarcodeExists(barcode)) {
        throw Exception('الباركود موجود بالفعل');
      }
    }

    values['created_at'] = DateTime.now().toIso8601String();
    final productId = await _db.insert('products', values,
        conflictAlgorithm: ConflictAlgorithm.abort);

    // تسجيل حدث إضافة المنتج
    try {
      final name = values['name'] as String? ?? '';
      final price = (values['price'] as num?)?.toDouble() ?? 0.0;
      final quantity = (values['quantity'] as int?) ?? 0;
      await logEvent(
        eventType: 'create',
        entityType: 'product',
        entityId: productId,
        userId: userId,
        username: username,
        description: 'إضافة منتج جديد: $name',
        details: 'السعر: ${price.toStringAsFixed(2)}\nالكمية: $quantity',
      );
    } catch (e) {
      debugPrint('خطأ في تسجيل حدث إضافة المنتج: $e');
    }

    return productId;
  }

  /// التحقق من وجود باركود في قاعدة البيانات
  Future<bool> isBarcodeExists(String barcode) async {
    if (barcode.trim().isEmpty) return false;
    final result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM products WHERE barcode = ?',
        [barcode.trim()]);
    return (result.first['count'] as int) > 0;
  }

  Future<int> updateProduct(int id, Map<String, Object?> values,
      {int? userId, String? username}) async {
    // التحقق من وجود المنتج
    final product =
        await _db.query('products', where: 'id = ?', whereArgs: [id], limit: 1);
    if (product.isEmpty) {
      throw Exception('المنتج غير موجود');
    }

    // التحقق من صحة البيانات
    if (values['name'] != null &&
        (values['name'] as String?)?.trim().isEmpty == true) {
      throw Exception('اسم المنتج لا يمكن أن يكون فارغاً');
    }
    if (values['price'] != null) {
      final price = (values['price'] as num?)?.toDouble() ?? 0.0;
      if (price < 0) {
        throw Exception('السعر يجب أن يكون أكبر من أو يساوي صفر');
      }
    }
    if (values['quantity'] != null) {
      final quantity = (values['quantity'] as int?) ?? 0;
      if (quantity < 0) {
        throw Exception('الكمية يجب أن تكون أكبر من أو تساوي صفر');
      }
    }

    // التحقق من الباركود إذا كان موجوداً
    if (values['barcode'] != null &&
        (values['barcode'] as String?)?.trim().isNotEmpty == true) {
      final barcode = (values['barcode'] as String).trim();
      final existing = await _db.query('products',
          where: 'barcode = ? AND id != ?', whereArgs: [barcode, id], limit: 1);
      if (existing.isNotEmpty) {
        throw Exception('الباركود موجود بالفعل لمنتج آخر');
      }
    }

    // الحصول على البيانات القديمة قبل التحديث
    final oldProduct = product.first;
    final oldQuantity = oldProduct['quantity'] as int? ?? 0;
    final oldPrice = (oldProduct['price'] as num?)?.toDouble() ?? 0.0;
    final oldCost = (oldProduct['cost'] as num?)?.toDouble() ?? 0.0;
    final oldName = oldProduct['name'] as String? ?? '';
    final oldBarcode = oldProduct['barcode'] as String? ?? '';
    final oldCategoryId = oldProduct['category_id'] as int?;
    final oldMinQuantity = oldProduct['min_quantity'] as int? ?? 1;

    values['updated_at'] = DateTime.now().toIso8601String();
    final updatedRows =
        await _db.update('products', values, where: 'id = ?', whereArgs: [id]);

    // تسجيل حدث تحديث المنتج
    if (updatedRows > 0) {
      try {
        final newName = values['name'] as String? ?? oldName;
        final newPrice = (values['price'] as num?)?.toDouble() ?? oldPrice;
        final newQuantity = (values['quantity'] as int? ?? oldQuantity);
        final newCost = (values['cost'] as num?)?.toDouble() ?? oldCost;
        final newBarcode = values['barcode'] as String? ?? oldBarcode;
        final newCategoryId = values['category_id'] as int? ?? oldCategoryId;
        final newMinQuantity = values['min_quantity'] as int? ?? oldMinQuantity;

        final changes = <String>[];

        // تتبع التغييرات
        bool hasQuantityChange = false;
        bool hasPriceChange = false;
        bool hasOtherChanges = false;

        if (values['name'] != null && oldName != newName) {
          changes.add('الاسم القديم: $oldName\nالاسم الجديد: $newName');
          hasOtherChanges = true;
        }

        if (values['price'] != null && oldPrice != newPrice) {
          changes.add(
              'السعر القديم: ${oldPrice.toStringAsFixed(2)}\nالسعر الجديد: ${newPrice.toStringAsFixed(2)}');
          hasPriceChange = true;
        }

        if (values['cost'] != null && oldCost != newCost) {
          changes.add(
              'التكلفة القديمة: ${oldCost.toStringAsFixed(2)}\nالتكلفة الجديدة: ${newCost.toStringAsFixed(2)}');
          hasOtherChanges = true;
        }

        if (values['quantity'] != null && oldQuantity != newQuantity) {
          changes.add(
              'الكمية القديمة: $oldQuantity\nالكمية الجديدة: $newQuantity');
          hasQuantityChange = true;
        }

        if (values['barcode'] != null && oldBarcode != newBarcode) {
          changes.add(
              'الباركود القديم: ${oldBarcode.isEmpty ? 'لا يوجد' : oldBarcode}\nالباركود الجديد: ${newBarcode.isEmpty ? 'لا يوجد' : newBarcode}');
          hasOtherChanges = true;
        }

        if (values['category_id'] != null && oldCategoryId != newCategoryId) {
          changes.add(
              'القسم القديم: ${oldCategoryId ?? 'غير محدد'}\nالقسم الجديد: ${newCategoryId ?? 'غير محدد'}');
          hasOtherChanges = true;
        }

        if (values['min_quantity'] != null &&
            oldMinQuantity != newMinQuantity) {
          changes.add(
              'الحد الأدنى للكمية القديم: $oldMinQuantity\nالحد الأدنى للكمية الجديد: $newMinQuantity');
          hasOtherChanges = true;
        }

        // بناء الوصف والتفاصيل
        String description;
        String eventType;

        if (hasQuantityChange && !hasOtherChanges && !hasPriceChange) {
          // تغيير الكمية فقط
          description = 'تغيير كمية المنتج: $newName';
          eventType = 'quantity_change';
        } else if (hasPriceChange && !hasOtherChanges && !hasQuantityChange) {
          // تغيير السعر فقط
          description = 'تغيير سعر المنتج: $newName';
          eventType =
              'update'; // يمكن استخدام 'price_change' إذا أردت نوع حدث منفصل
        } else {
          // تغييرات متعددة
          description = 'تحديث منتج: $newName';
          eventType = 'update';
        }

        final details =
            changes.isEmpty ? 'لا توجد تغييرات' : changes.join('\n\n');

        // تسجيل الحدث
        await logEvent(
          eventType: eventType,
          entityType: 'product',
          entityId: id,
          userId: userId,
          username: username,
          description: description,
          details: details,
        );
      } catch (e) {
        debugPrint('خطأ في تسجيل حدث تحديث المنتج: $e');
      }
    }

    return updatedRows;
  }

  Future<int> deleteProduct(int id,
      {int? userId, String? username, String? name}) async {
    try {
      // التحقق من وجود المنتج أولاً
      final product = await _db.query('products',
          where: 'id = ?', whereArgs: [id], limit: 1);
      if (product.isEmpty) {
        return 0; // المنتج غير موجود
      }

      final productData = product.first;
      final productName = productData['name'] as String? ?? '';

      // حفظ بيانات المنتج في سلة المحذوفات قبل الحذف
      try {
        await _db.insert('deleted_items', {
          'entity_type': 'product',
          'entity_id': id,
          'original_data': jsonEncode(productData),
          'deleted_by_user_id': userId,
          'deleted_by_username': username,
          'deleted_by_name': name,
          'deleted_at': DateTime.now().toIso8601String(),
          'can_restore': 1,
        });
      } catch (e) {
        debugPrint('خطأ في حفظ المنتج في سلة المحذوفات: $e');
        // نتابع الحذف حتى لو فشل الحفظ في سلة المحذوفات
      }

      // تعطيل المفاتيح الخارجية قبل بدء المعاملة (يجب أن يكون خارج المعاملة)
      await _db.execute('PRAGMA foreign_keys = OFF');

      try {
        return await _db.transaction<int>((txn) async {
          try {
            // حذف sale_items المرتبطة بالمنتج
            try {
              await txn.delete('sale_items',
                  where: 'product_id = ?', whereArgs: [id]);
            } catch (e) {
              debugPrint('خطأ في حذف sale_items المرتبطة بالمنتج: $e');
              // نتابع حتى لو فشل حذف sale_items
            }

            // الحصول على المبيعات التي كانت تحتوي على هذا المنتج فقط
            try {
              final salesWithProduct = await txn.rawQuery('''
                SELECT DISTINCT s.id FROM sales s
                JOIN sale_items si ON s.id = si.sale_id
                WHERE si.product_id = ?
              ''', [id]);

              // حذف الأقساط والمبيعات التي لم يعد لديها عناصر
              for (final sale in salesWithProduct) {
                final saleId = sale['id'] as int;

                // التحقق من وجود عناصر متبقية في البيع
                final remainingItems = await txn.rawQuery('''
                  SELECT COUNT(*) as count FROM sale_items WHERE sale_id = ?
                ''', [saleId]);

                final itemCount = remainingItems.first['count'] as int;

                // إذا لم يعد هناك عناصر، احذف البيع وأقساطه
                if (itemCount == 0) {
                  try {
                    await txn.delete('installments',
                        where: 'sale_id = ?', whereArgs: [saleId]);
                  } catch (e) {
                    debugPrint('خطأ في حذف installments للبيع $saleId: $e');
                  }
                  try {
                    await txn
                        .delete('sales', where: 'id = ?', whereArgs: [saleId]);
                  } catch (e) {
                    debugPrint('خطأ في حذف البيع $saleId: $e');
                  }
                }
              }
            } catch (e) {
              debugPrint('خطأ في معالجة المبيعات المرتبطة: $e');
              // نتابع حذف المنتج حتى لو فشلت معالجة المبيعات
            }

            // حذف الخصومات المرتبطة بالمنتج
            try {
              await txn.delete('product_discounts',
                  where: 'product_id = ?', whereArgs: [id]);
            } catch (e) {
              debugPrint('خطأ في حذف الخصومات المرتبطة بالمنتج: $e');
              // نتابع حتى لو فشل حذف الخصومات
            }

            // حذف المنتج
            final deletedRows =
                await txn.delete('products', where: 'id = ?', whereArgs: [id]);

            // تسجيل حدث حذف المنتج (باستخدام transaction لتجنب deadlock)
            if (deletedRows > 0) {
              try {
                await logEvent(
                  eventType: 'delete',
                  entityType: 'product',
                  entityId: id,
                  userId: userId,
                  username: username,
                  description: 'حذف منتج: $productName',
                  details: 'تم حذف المنتج رقم $id',
                  transaction: txn,
                );
              } catch (e) {
                debugPrint('خطأ في تسجيل حدث حذف المنتج: $e');
              }
            }

            return deletedRows;
          } catch (e) {
            debugPrint('خطأ في حذف المنتج داخل المعاملة: $e');
            rethrow;
          }
        });
      } finally {
        // إعادة تفعيل المفاتيح الخارجية دائماً
        try {
          await _db.execute('PRAGMA foreign_keys = ON');
        } catch (e) {
          debugPrint('خطأ في إعادة تفعيل المفاتيح الخارجية: $e');
        }
      }
    } catch (e) {
      // التأكد من إعادة تفعيل المفاتيح الخارجية في حالة الخطأ
      try {
        await _db.execute('PRAGMA foreign_keys = ON');
      } catch (_) {}
      debugPrint('خطأ في حذف المنتج: $e');
      rethrow;
    }
  }

  /// Delete product with cascade option - removes related sale_items first
  Future<int> deleteProductWithCascade(int id) async {
    return _db.transaction<int>((txn) async {
      // First delete all sale_items that reference this product
      await txn.delete('sale_items', where: 'product_id = ?', whereArgs: [id]);

      // Delete product discounts associated with this product
      await txn.delete('product_discounts',
          where: 'product_id = ?', whereArgs: [id]);

      // Then delete the product
      return txn.delete('products', where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Get count of sale_items that reference a product
  Future<int> getProductSaleItemsCount(int productId) async {
    final result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM sale_items WHERE product_id = ?',
        [productId]);
    return result.first['count'] as int;
  }

  /// Clean up orphaned installments (installments without valid sales)
  Future<int> cleanupOrphanedInstallments() async {
    try {
      // Delete installments that reference non-existent sales
      final result = await _db.rawDelete('''
        DELETE FROM installments 
        WHERE sale_id NOT IN (SELECT id FROM sales)
      ''');

      return result;
    } catch (e) {
      return 0;
    }
  }

  // Categories
  Future<List<Map<String, Object?>>> getCategories({String? query}) async {
    if (query == null || query.trim().isEmpty) {
      return _db.query('categories', orderBy: 'name ASC');
    }
    final like = '%${query.trim()}%';
    return _db.query('categories',
        where: 'name LIKE ?', whereArgs: [like], orderBy: 'name ASC');
  }

  Future<int> upsertCategory(Map<String, Object?> values, {int? id}) async {
    if (id == null) return _db.insert('categories', values);
    return _db.update('categories', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCategory(int id) async {
    return _db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // Customers
  Future<List<Map<String, Object?>>> getCustomers({
    String? query,
    int? limit,
    int? offset,
  }) async {
    List<Map<String, Object?>> allCustomers;
    if (query == null || query.trim().isEmpty) {
      allCustomers = await _db.query(
        'customers',
        orderBy: 'id DESC',
        limit: limit,
        offset: offset,
      );
    } else {
      final like = '%${query.trim()}%';
      allCustomers = await _db.query(
        'customers',
        where: 'name LIKE ? OR phone LIKE ?',
        whereArgs: [like, like],
        orderBy: 'id DESC',
        limit: limit,
        offset: offset,
      );
    }

    // تجميع العملاء المكررين بالاسم (تطبيع الاسم)
    final Map<String, Map<String, Object?>> uniqueCustomers = {};
    final Map<String, List<int>> customerIdsByNormalizedName = {};

    for (final customer in allCustomers) {
      final name = customer['name']?.toString() ?? '';
      final normalizedName =
          name.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

      if (normalizedName.isEmpty) continue;

      if (!uniqueCustomers.containsKey(normalizedName)) {
        // استخدام أول عميل كأساس
        uniqueCustomers[normalizedName] = Map<String, Object?>.from(customer);
        customerIdsByNormalizedName[normalizedName] = [customer['id'] as int];
      } else {
        // دمج البيانات: استخدام البيانات الأكثر اكتمالاً
        final existing = uniqueCustomers[normalizedName]!;
        customerIdsByNormalizedName[normalizedName]!.add(customer['id'] as int);

        // تحديث الهاتف إذا كان فارغاً في العميل الأساسي
        if ((existing['phone'] == null ||
                existing['phone'].toString().trim().isEmpty) &&
            customer['phone'] != null &&
            customer['phone'].toString().trim().isNotEmpty) {
          existing['phone'] = customer['phone'];
        }

        // تحديث العنوان إذا كان فارغاً في العميل الأساسي
        if ((existing['address'] == null ||
                existing['address'].toString().trim().isEmpty) &&
            customer['address'] != null &&
            customer['address'].toString().trim().isNotEmpty) {
          existing['address'] = customer['address'];
        }

        // جمع إجمالي الدين من جميع العملاء المكررين
        final existingDebt =
            (existing['total_debt'] as num?)?.toDouble() ?? 0.0;
        final customerDebt =
            (customer['total_debt'] as num?)?.toDouble() ?? 0.0;
        existing['total_debt'] = existingDebt + customerDebt;
      }
    }

    // حساب إجمالي الدين الفعلي من المبيعات والمدفوعات للعملاء المكررين
    final duplicateGroups = customerIdsByNormalizedName.entries
        .where((e) => e.value.length > 1)
        .toList();

    if (duplicateGroups.isNotEmpty) {
      // جمع جميع IDs للعملاء المكررين
      final allDuplicateIds = <int>[];
      for (final group in duplicateGroups) {
        allDuplicateIds.addAll(group.value);
      }

      // حساب الدين لجميع العملاء المكررين في استعلامات مجمعة
      final placeholders = allDuplicateIds.map((_) => '?').join(',');
      final salesResult = await _db.rawQuery(
          'SELECT customer_id, SUM(total) as total FROM sales WHERE customer_id IN ($placeholders) AND type IN ("credit", "installment") GROUP BY customer_id',
          allDuplicateIds);
      final paymentsResult = await _db.rawQuery(
          'SELECT customer_id, SUM(amount) as total FROM payments WHERE customer_id IN ($placeholders) GROUP BY customer_id',
          allDuplicateIds);
      final installmentsResult = await _db.rawQuery(
          'SELECT s.customer_id, SUM(i.amount) as total FROM installments i JOIN sales s ON i.sale_id = s.id WHERE s.customer_id IN ($placeholders) GROUP BY s.customer_id',
          allDuplicateIds);

      // إنشاء maps للبحث السريع
      final salesByCustomer = <int, double>{};
      for (final row in salesResult) {
        salesByCustomer[row['customer_id'] as int] =
            (row['total'] as num?)?.toDouble() ?? 0.0;
      }
      final paymentsByCustomer = <int, double>{};
      for (final row in paymentsResult) {
        paymentsByCustomer[row['customer_id'] as int] =
            (row['total'] as num?)?.toDouble() ?? 0.0;
      }
      final installmentsByCustomer = <int, double>{};
      for (final row in installmentsResult) {
        installmentsByCustomer[row['customer_id'] as int] =
            (row['total'] as num?)?.toDouble() ?? 0.0;
      }

      // تحديث الدين لكل مجموعة من العملاء المكررين
      for (final group in duplicateGroups) {
        double totalDebt = 0.0;
        for (final id in group.value) {
          final salesTotal = salesByCustomer[id] ?? 0.0;
          final paymentsTotal = paymentsByCustomer[id] ?? 0.0;
          final installmentsPaid = installmentsByCustomer[id] ?? 0.0;
          totalDebt += salesTotal - paymentsTotal - installmentsPaid;
        }
        uniqueCustomers[group.key]!['total_debt'] = totalDebt;
      }
    }

    // إرجاع القائمة مع الحفاظ على الاسم الأصلي (غير normalized)
    return uniqueCustomers.values.toList();
  }

  Future<int> upsertCustomer(Map<String, Object?> values, {int? id}) async {
    // التحقق من صحة البيانات
    if (values['name'] == null ||
        (values['name'] as String?)?.trim().isEmpty == true) {
      throw Exception('اسم العميل مطلوب');
    }

    // التحقق من total_debt إذا كان موجوداً
    if (values['total_debt'] != null) {
      final totalDebt = (values['total_debt'] as num?)?.toDouble() ?? 0.0;
      if (totalDebt < 0) {
        throw Exception('إجمالي الدين يجب أن يكون أكبر من أو يساوي صفر');
      }
    }

    if (id == null) {
      // إضافة عميل جديد - التحقق من وجود عميل بنفس الاسم
      final customerName = values['name']?.toString().trim() ?? '';
      final normalizedName = customerName.replaceAll(RegExp(r'\s+'), ' ');
      final existing = await _db.query('customers',
          where: "TRIM(REPLACE(REPLACE(name, '\t', ' '), '  ', ' ')) = ?",
          whereArgs: [normalizedName],
          limit: 1);

      if (existing.isNotEmpty) {
        // تحديث العميل الموجود بدلاً من إنشاء جديد
        final existingId = existing.first['id'] as int;
        // دمج البيانات: تحديث الحقول الفارغة فقط
        final updateData = Map<String, Object?>.from(values);
        if (existing.first['phone']?.toString().trim().isNotEmpty == true &&
            (updateData['phone'] == null ||
                updateData['phone'].toString().trim().isEmpty)) {
          updateData['phone'] = existing.first['phone'];
        }
        if (existing.first['address']?.toString().trim().isNotEmpty == true &&
            (updateData['address'] == null ||
                updateData['address'].toString().trim().isEmpty)) {
          updateData['address'] = existing.first['address'];
        }
        // الحفاظ على total_debt الموجود
        if (updateData['total_debt'] == null) {
          updateData['total_debt'] = existing.first['total_debt'];
        }
        await _db.update('customers', updateData,
            where: 'id = ?', whereArgs: [existingId]);
        return existingId;
      } else {
        // إضافة عميل جديد
        values['name'] = normalizedName; // استخدام الاسم المطبيع
        return _db.insert('customers', values);
      }
    } else {
      // تحديث عميل موجود - التحقق من وجوده
      final customer = await _db.query('customers',
          where: 'id = ?', whereArgs: [id], limit: 1);
      if (customer.isEmpty) {
        throw Exception('العميل غير موجود');
      }
      // تطبيع الاسم عند التحديث أيضاً
      if (values['name'] != null) {
        values['name'] =
            (values['name'] as String).trim().replaceAll(RegExp(r'\s+'), ' ');
      }
      return _db.update('customers', values, where: 'id = ?', whereArgs: [id]);
    }
  }

  /// التحقق من وجود بيانات مرتبطة بالعميل
  Future<Map<String, int>> getCustomerRelatedDataCount(int customerId) async {
    final salesCount = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM sales WHERE customer_id = ?',
        [customerId]);
    final paymentsCount = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM payments WHERE customer_id = ?',
        [customerId]);

    return {
      'sales': salesCount.first['count'] as int,
      'payments': paymentsCount.first['count'] as int,
    };
  }

  /// التحقق من وجود مدفوعات مرتبطة بدين معين
  Future<bool> hasPaymentsForCreditSale(int saleId, int customerId) async {
    final result = await _db.rawQuery('''
      SELECT COUNT(*) as count FROM payments
      WHERE customer_id = ? AND payment_date >= (
        SELECT created_at FROM sales WHERE id = ?
      )
    ''', [customerId, saleId]);

    return (result.first['count'] as int) > 0;
  }

  /// الحصول على إجمالي المدفوعات المرتبطة بدين معين
  Future<double> getPaymentsForCreditSale(int saleId, int customerId) async {
    final result = await _db.rawQuery('''
      SELECT IFNULL(SUM(amount), 0) as total FROM payments
      WHERE customer_id = ? AND payment_date >= (
        SELECT created_at FROM sales WHERE id = ?
      )
    ''', [customerId, saleId]);

    return (result.first['total'] as num).toDouble();
  }

  Future<int> deleteCustomer(int id,
      {int? userId, String? username, String? name}) async {
    return _db.transaction<int>((txn) async {
      try {
        // التحقق من وجود العميل أولاً
        final customer = await txn.query('customers',
            where: 'id = ?', whereArgs: [id], limit: 1);
        if (customer.isEmpty) {
          return 0;
        }

        // التحقق من وجود بيانات مرتبطة بالعميل
        final salesCount = await txn.rawQuery(
            'SELECT COUNT(*) as count FROM sales WHERE customer_id = ?', [id]);
        final paymentsCount = await txn.rawQuery(
            'SELECT COUNT(*) as count FROM payments WHERE customer_id = ?',
            [id]);

        final sales = salesCount.first['count'] as int;
        final payments = paymentsCount.first['count'] as int;

        // إذا كان هناك بيانات مرتبطة، منع الحذف
        if (sales > 0 || payments > 0) {
          final List<String> relatedData = [];
          if (sales > 0) {
            relatedData.add('$sales عملية بيع');
          }
          if (payments > 0) {
            relatedData.add('$payments دفعة');
          }

          throw Exception(
              'لا يمكن حذف العميل لأنه مرتبط ببيانات مهمة:\n${relatedData.join('\n')}\n\n'
              'لحماية السجلات المالية والتاريخية، يجب حذف جميع المبيعات والمدفوعات المرتبطة بهذا العميل أولاً.');
        }

        // حفظ البيانات الأصلية في سلة المحذوفات
        final customerData = customer.first;
        await txn.insert('deleted_items', {
          'entity_type': 'customer',
          'entity_id': id,
          'original_data': jsonEncode(customerData),
          'deleted_by_user_id': userId,
          'deleted_by_username': username,
          'deleted_by_name': name,
          'deleted_at': DateTime.now().toIso8601String(),
          'can_restore': 1,
        });

        // حذف العميل
        final deletedRows =
            await txn.delete('customers', where: 'id = ?', whereArgs: [id]);

        return deletedRows;
      } catch (e) {
        rethrow;
      }
    });
  }

  // Suppliers
  Future<List<Map<String, Object?>>> getSuppliers({
    String? query,
    int? limit,
    int? offset,
  }) async {
    final limitClause = limit != null ? 'LIMIT $limit' : '';
    final offsetClause = offset != null ? 'OFFSET $offset' : '';

    if (query == null || query.trim().isEmpty) {
      return _db.rawQuery('''
        SELECT s.*, IFNULL(s.total_payable, 0) as total_payable
        FROM suppliers s
        ORDER BY s.id DESC
        $limitClause $offsetClause
      ''');
    }
    final like = '%${query.trim()}%';
    return _db.rawQuery('''
      SELECT s.*, IFNULL(s.total_payable, 0) as total_payable
      FROM suppliers s
      WHERE s.name LIKE ? OR s.phone LIKE ?
      ORDER BY s.id DESC
      $limitClause $offsetClause
    ''', [like, like]);
  }

  /// الحصول على عدد الموردين (للمساعدة في pagination)
  Future<int> getSuppliersCount({String? query}) async {
    if (query == null || query.trim().isEmpty) {
      final result =
          await _db.rawQuery('SELECT COUNT(*) as count FROM suppliers');
      return (result.first['count'] as int?) ?? 0;
    }
    final like = '%${query.trim()}%';
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM suppliers WHERE name LIKE ? OR phone LIKE ?',
      [like, like],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  /// الحصول على عدد العملاء (للمساعدة في pagination)
  Future<int> getCustomersCount({String? query}) async {
    if (query == null || query.trim().isEmpty) {
      final result =
          await _db.rawQuery('SELECT COUNT(*) as count FROM customers');
      return (result.first['count'] as int?) ?? 0;
    }
    final like = '%${query.trim()}%';
    final result = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM customers WHERE name LIKE ? OR phone LIKE ?',
      [like, like],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> upsertSupplier(Map<String, Object?> values, {int? id}) async {
    // التحقق من صحة البيانات
    if (values['name'] == null ||
        (values['name'] as String?)?.trim().isEmpty == true) {
      throw Exception('اسم المورد مطلوب');
    }

    // التحقق من total_payable إذا كان موجوداً
    if (values['total_payable'] != null) {
      final totalPayable = (values['total_payable'] as num?)?.toDouble() ?? 0.0;
      if (totalPayable < 0) {
        throw Exception('إجمالي المستحقات يجب أن يكون أكبر من أو يساوي صفر');
      }
    }

    if (id == null) {
      // إضافة مورد جديد
      values['name'] = (values['name'] as String).trim();
      return _db.insert('suppliers', values);
    } else {
      // تحديث مورد موجود
      if (values['name'] != null) {
        values['name'] = (values['name'] as String).trim();
      }
      return _db.update('suppliers', values, where: 'id = ?', whereArgs: [id]);
    }
  }

  Future<int> deleteSupplier(int id,
      {int? userId, String? username, String? name}) async {
    // التأكد من وجود جدول supplier_payments قبل الاستخدام
    await _ensureSupplierPaymentsTable(_db);

    return _db.transaction<int>((txn) async {
      try {
        // التحقق من وجود المورد أولاً
        final supplier = await txn.query('suppliers',
            where: 'id = ?', whereArgs: [id], limit: 1);
        if (supplier.isEmpty) {
          return 0;
        }

        // التحقق من وجود بيانات مرتبطة بالمورد
        // استخدام try-catch للتعامل مع حالة عدم وجود الجدول
        int payments = 0;
        try {
          final paymentsCount = await txn.rawQuery(
              'SELECT COUNT(*) as count FROM supplier_payments WHERE supplier_id = ?',
              [id]);
          payments = paymentsCount.first['count'] as int;
        } catch (e) {
          // إذا كان الجدول غير موجود، نعتبر أن لا توجد مدفوعات
          debugPrint(
              'تحذير: جدول supplier_payments غير موجود أو خطأ في الاستعلام: $e');
          payments = 0;
        }

        // إذا كان هناك مدفوعات مرتبطة، منع الحذف
        if (payments > 0) {
          throw Exception(
              'لا يمكن حذف المورد لأنه مرتبط ببيانات مهمة:\n• $payments دفعة\n\n'
              'لحماية السجلات المالية والتاريخية، يجب حذف جميع المدفوعات المرتبطة بهذا المورد أولاً.');
        }

        // حفظ البيانات الأصلية في سلة المحذوفات
        final supplierData = supplier.first;
        await txn.insert('deleted_items', {
          'entity_type': 'supplier',
          'entity_id': id,
          'original_data': jsonEncode(supplierData),
          'deleted_by_user_id': userId,
          'deleted_by_username': username,
          'deleted_by_name': name,
          'deleted_at': DateTime.now().toIso8601String(),
          'can_restore': 1,
        });

        // حذف المورد
        final deletedRows =
            await txn.delete('suppliers', where: 'id = ?', whereArgs: [id]);

        return deletedRows;
      } catch (e) {
        rethrow;
      }
    });
  }

  /// إضافة دفعة للمورد (تقليل total_payable)
  Future<int> addSupplierPayment({
    required int supplierId,
    required double amount,
    required DateTime paymentDate,
    String? notes,
  }) async {
    return _db.transaction<int>((txn) async {
      // التحقق من وجود المورد
      final supplier = await txn.query('suppliers',
          where: 'id = ?', whereArgs: [supplierId], limit: 1);
      if (supplier.isEmpty) {
        throw Exception('المورد غير موجود');
      }

      // التحقق من أن المبلغ أكبر من صفر
      if (amount <= 0) {
        throw Exception('المبلغ يجب أن يكون أكبر من صفر');
      }

      // إضافة سجل الدفعة
      final paymentId = await txn.insert('supplier_payments', {
        'supplier_id': supplierId,
        'amount': amount,
        'payment_date': paymentDate.toIso8601String(),
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      });

      // تقليل المستحقات (total_payable)
      await txn.rawUpdate(
        'UPDATE suppliers SET total_payable = MAX(IFNULL(total_payable, 0) - ?, 0) WHERE id = ?',
        [amount, supplierId],
      );

      return paymentId;
    });
  }

  /// الحصول على مدفوعات المورد
  Future<List<Map<String, Object?>>> getSupplierPayments({
    int? supplierId,
    DateTime? from,
    DateTime? to,
  }) async {
    final where = <String>[];
    final args = <Object?>[];

    if (supplierId != null) {
      where.add('sp.supplier_id = ?');
      args.add(supplierId);
    }

    if (from != null && to != null) {
      where.add('sp.payment_date BETWEEN ? AND ?');
      args.addAll([from.toIso8601String(), to.toIso8601String()]);
    }

    final whereClause = where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';

    return _db.rawQuery('''
      SELECT 
        sp.*,
        s.name as supplier_name,
        s.phone as supplier_phone
      FROM supplier_payments sp
      JOIN suppliers s ON s.id = sp.supplier_id
      $whereClause
      ORDER BY sp.payment_date DESC, sp.created_at DESC
    ''', args);
  }

  /// تحديث دفعة مورد
  Future<bool> updateSupplierPayment({
    required int paymentId,
    required double newAmount,
    required DateTime newPaymentDate,
    String? newNotes,
  }) async {
    return _db.transaction<bool>((txn) async {
      try {
        // الحصول على تفاصيل الدفعة القديمة
        final oldPayment = await txn.query('supplier_payments',
            where: 'id = ?', whereArgs: [paymentId], limit: 1);

        if (oldPayment.isEmpty) {
          throw Exception('السجل غير موجود');
        }

        final oldP = oldPayment.first;
        final supplierId = oldP['supplier_id'] as int;
        final oldAmount = (oldP['amount'] as num).toDouble();
        final isPayable = oldAmount == 0;

        // إذا كان سجل مستحقات (amount = 0)، لا يمكن تعديله كدفعة
        if (isPayable && newAmount > 0) {
          throw Exception('لا يمكن تحويل سجل المستحقات إلى دفعة');
        }

        // تحديث السجل
        final updatedRows = await txn.update(
          'supplier_payments',
          {
            'amount': newAmount,
            'payment_date': newPaymentDate.toIso8601String(),
            'notes': newNotes,
          },
          where: 'id = ?',
          whereArgs: [paymentId],
        );

        if (updatedRows > 0) {
          // تحديث total_payable للمورد
          // نستعيد المبلغ القديم ثم نطبق المبلغ الجديد
          if (oldAmount > 0) {
            // استرجاع المبلغ القديم
            await txn.rawUpdate(
              'UPDATE suppliers SET total_payable = IFNULL(total_payable, 0) + ? WHERE id = ?',
              [oldAmount, supplierId],
            );
          }

          // تطبيق المبلغ الجديد
          if (newAmount > 0) {
            await txn.rawUpdate(
              'UPDATE suppliers SET total_payable = MAX(IFNULL(total_payable, 0) - ?, 0) WHERE id = ?',
              [newAmount, supplierId],
            );
          }
        }

        return updatedRows > 0;
      } catch (e) {
        rethrow;
      }
    });
  }

  /// إعادة حساب total_payable للمورد من جميع السجلات
  Future<void> _recalculateSupplierPayable(
      DatabaseExecutor txn, int supplierId) async {
    // حساب total_payable من جميع السجلات المتبقية
    // total_payable = مجموع المستحقات المضافة - مجموع الدفعات المدفوعة

    // الحصول على جميع السجلات للمورد
    final payments = await txn.query('supplier_payments',
        where: 'supplier_id = ?', whereArgs: [supplierId]);

    double totalPayable = 0.0;

    for (final payment in payments) {
      final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
      final notes = payment['notes']?.toString() ?? '';

      if (amount > 0) {
        // دفعة - ننقص من total_payable
        totalPayable -= amount;
      } else if (notes.contains('إضافة مستحقات:')) {
        // مستحقات مضافة - نحاول استخراج المبلغ من notes
        try {
          // تنسيق: "إضافة مستحقات: X.XX د.ع - ملاحظات" أو "إضافة مستحقات: X.XX د.ع"
          // نبحث عن رقم بعد "إضافة مستحقات:" وقبل "د.ع"
          final match =
              RegExp(r'إضافة مستحقات:\s*([\d,]+\.?\d*)').firstMatch(notes);
          if (match != null) {
            // إزالة الفواصل من الرقم (مثل 1,000,000)
            final amountStr = match.group(1)!.replaceAll(',', '');
            final payableAmount = double.parse(amountStr);
            totalPayable += payableAmount;
          }
        } catch (e) {
          // إذا فشل استخراج المبلغ، نتجاهل هذا السجل
          debugPrint('خطأ في استخراج المبلغ من السجل: $e');
        }
      }
    }

    // تحديث total_payable (يجب أن يكون >= 0)
    await txn.rawUpdate(
      'UPDATE suppliers SET total_payable = MAX(?, 0) WHERE id = ?',
      [totalPayable, supplierId],
    );
  }

  /// حذف دفعة مورد
  Future<bool> deleteSupplierPayment(int paymentId,
      {int? userId, String? username, String? name}) async {
    return _db.transaction<bool>((txn) async {
      try {
        // الحصول على تفاصيل الدفعة
        final payment = await txn.query('supplier_payments',
            where: 'id = ?', whereArgs: [paymentId], limit: 1);

        if (payment.isEmpty) return false;

        final p = payment.first;
        final supplierId = p['supplier_id'] as int;

        // حفظ بيانات الدفعة في سلة المحذوفات قبل الحذف
        await txn.insert('deleted_items', {
          'entity_type': 'supplier_payment',
          'entity_id': paymentId,
          'original_data': jsonEncode(p),
          'deleted_by_user_id': userId,
          'deleted_by_username': username,
          'deleted_by_name': name,
          'deleted_at': DateTime.now().toIso8601String(),
          'can_restore': 1,
        });

        // حذف الدفعة
        final deletedRows = await txn.delete('supplier_payments',
            where: 'id = ?', whereArgs: [paymentId]);

        if (deletedRows > 0) {
          // إعادة حساب total_payable من جميع السجلات المتبقية
          await _recalculateSupplierPayable(txn, supplierId);
        }

        return deletedRows > 0;
      } catch (e) {
        return false;
      }
    });
  }

  /// إضافة مستحقات جديدة للمورد (زيادة total_payable)
  Future<void> addSupplierPayable({
    required int supplierId,
    required double amount,
    String? notes,
  }) async {
    if (amount <= 0) {
      throw Exception('المبلغ يجب أن يكون أكبر من صفر');
    }

    await _db.transaction((txn) async {
      // التحقق من وجود المورد
      final supplier = await txn.query('suppliers',
          where: 'id = ?', whereArgs: [supplierId], limit: 1);
      if (supplier.isEmpty) {
        throw Exception('المورد غير موجود');
      }

      // زيادة المستحقات
      await txn.rawUpdate(
        'UPDATE suppliers SET total_payable = IFNULL(total_payable, 0) + ? WHERE id = ?',
        [amount, supplierId],
      );

      // إضافة سجل في supplier_payments كسجل إضافة مستحقات
      // نستخدم amount = 0 لأننا لا نضيف دفعة، فقط نزيد المستحقات
      // ويمكننا استخدام notes لتوضيح أن هذا إضافة مستحقات
      final formattedAmount = amount.toStringAsFixed(2);
      final noteText = notes?.isNotEmpty == true
          ? 'إضافة مستحقات: $formattedAmount د.ع - $notes'
          : 'إضافة مستحقات: $formattedAmount د.ع';

      await txn.insert('supplier_payments', {
        'supplier_id': supplierId,
        'amount': 0, // لا نضيف دفعة فعلية
        'payment_date': DateTime.now().toIso8601String(),
        'notes': noteText,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  // Expenses - تم نقل الدوال إلى قسم "دوال إدارة المصروفات" أدناه
  // الدوال القديمة تم استبدالها بدوال محسنة مع دعم الفئات والوصف

  // إدارة الأقساط
  Future<List<Map<String, Object?>>> getInstallments({
    int? customerId,
    int? saleId,
    bool overdueOnly = false,
  }) async {
    final where = <String>[];
    final args = <Object?>[];

    if (customerId != null) {
      where.add('s.customer_id = ?');
      args.add(customerId);
    }

    if (saleId != null) {
      where.add('i.sale_id = ?');
      args.add(saleId);
    }

    if (overdueOnly) {
      where.add('i.due_date < ? AND i.paid = 0');
      args.add(DateTime.now().toIso8601String());
    }

    final sql = '''
      SELECT 
        i.*,
        s.customer_id,
        c.name as customer_name,
        c.phone as customer_phone,
        s.total as sale_total,
        s.type as sale_type
      FROM installments i
      JOIN sales s ON s.id = i.sale_id
      JOIN customers c ON c.id = s.customer_id
      ${where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : ''}
      ORDER BY i.due_date ASC
    ''';

    return _db.rawQuery(sql, args);
  }

  Future<int> payInstallment(int installmentId, double amount,
      {String? notes}) async {
    return _db.transaction<int>((txn) async {
      // الحصول على بيانات القسط
      final installment = await txn.query(
        'installments',
        where: 'id = ?',
        whereArgs: [installmentId],
      );

      if (installment.isEmpty) {
        throw Exception('القسط غير موجود');
      }

      final installmentData = installment.first;
      final saleId = installmentData['sale_id'] as int;
      final installmentAmount = (installmentData['amount'] as num).toDouble();
      final isPaid = (installmentData['paid'] as int?) == 1;

      // التحقق من أن القسط غير مدفوع
      if (isPaid) {
        throw Exception('القسط مدفوع بالفعل ولا يمكن دفعه مرة أخرى');
      }

      // التحقق من أن المبلغ المدفوع لا يتجاوز مبلغ القسط
      if (amount > installmentAmount) {
        throw Exception(
            'المبلغ المدفوع ($amount) يتجاوز مبلغ القسط ($installmentAmount)');
      }

      final customerId = await txn.query(
        'sales',
        columns: ['customer_id'],
        where: 'id = ?',
        whereArgs: [saleId],
      );

      if (customerId.isEmpty) {
        throw Exception('البيع غير موجود');
      }

      final customerIdValue = customerId.first['customer_id'] as int;

      // تحديث حالة القسط
      await txn.update(
        'installments',
        {
          'paid': 1,
          'paid_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [installmentId],
      );

      // إضافة سجل الدفع
      final paymentId = await txn.insert('payments', {
        'customer_id': customerIdValue,
        'amount': amount,
        'payment_date': DateTime.now().toIso8601String(),
        'notes': notes ?? 'دفع قسط',
        'created_at': DateTime.now().toIso8601String(),
      });

      // تقليل دين العميل
      await txn.rawUpdate(
        'UPDATE customers SET total_debt = MAX(IFNULL(total_debt, 0) - ?, 0) WHERE id = ?',
        [amount, customerIdValue],
      );

      return paymentId;
    });
  }

  Future<Map<String, dynamic>> getInstallmentSummary(int customerId) async {
    final installments = await getInstallments(customerId: customerId);

    double totalInstallments = 0;
    double paidInstallments = 0;
    double overdueAmount = 0;
    int overdueCount = 0;
    int totalCount = 0;
    int paidCount = 0;

    for (final installment in installments) {
      final amount = (installment['amount'] as num).toDouble();
      final paid = (installment['paid'] as int) == 1;
      final dueDate = DateTime.parse(installment['due_date'] as String);

      totalInstallments += amount;
      totalCount++;

      if (paid) {
        paidInstallments += amount;
        paidCount++;
      } else if (dueDate.isBefore(DateTime.now())) {
        overdueAmount += amount;
        overdueCount++;
      }
    }

    return {
      'totalInstallments': totalInstallments,
      'paidInstallments': paidInstallments,
      'remainingInstallments': totalInstallments - paidInstallments,
      'overdueAmount': overdueAmount,
      'overdueCount': overdueCount,
      'totalCount': totalCount,
      'paidCount': paidCount,
      'remainingCount': totalCount - paidCount,
    };
  }

  /// الحصول على تفاصيل الأقساط مع المبالغ المحدثة
  Future<List<Map<String, dynamic>>> getInstallmentDetails(
      int customerId) async {
    final installments = await _db.rawQuery('''
      SELECT 
        i.id,
        i.sale_id,
        i.due_date,
        i.amount,
        i.paid,
        i.paid_at,
        s.created_at as sale_date,
        s.total as sale_total,
        s.type as sale_type
      FROM installments i
      JOIN sales s ON s.id = i.sale_id
      WHERE s.customer_id = ?
      ORDER BY i.due_date ASC
    ''', [customerId]);

    return installments.map((installment) {
      final dueDate = DateTime.parse(installment['due_date'] as String);
      final isOverdue = !(installment['paid'] as int == 1) &&
          dueDate.isBefore(DateTime.now());

      return {
        ...installment,
        'is_overdue': isOverdue,
        'days_overdue':
            isOverdue ? DateTime.now().difference(dueDate).inDays : 0,
      };
    }).toList();
  }

  // Sales and installments (simplified version)
  Future<int> createSale(
      {int? customerId,
      String? customerName,
      String? customerPhone,
      String? customerAddress,
      DateTime? dueDate,
      required String type,
      required List<Map<String, Object?>> items,
      bool decrementStock = true,
      // إضافة معاملات الأقساط
      int? installmentCount,
      double? downPayment,
      DateTime? firstInstallmentDate,
      // معاملات الكوبون
      int? couponId,
      double? couponDiscount,
      // Event logging parameters
      int? userId,
      String? username}) async {
    return _db.transaction<int>((txn) async {
      try {
        // التحقق من أن قائمة العناصر ليست فارغة
        if (items.isEmpty) {
          throw Exception('لا يمكن إنشاء بيع بدون منتجات');
        }

        // التحقق من صحة البيانات والكميات المتاحة
        for (final it in items) {
          final productId = it['product_id'] as int?;
          if (productId == null) {
            throw Exception('معرف المنتج مطلوب');
          }

          // التحقق من وجود المنتج
          final product = await txn.query('products',
              where: 'id = ?', whereArgs: [productId], limit: 1);
          if (product.isEmpty) {
            throw Exception('المنتج غير موجود');
          }

          final quantity = (it['quantity'] as num?)?.toInt() ?? 0;
          if (quantity <= 0) {
            throw Exception('الكمية يجب أن تكون أكبر من صفر');
          }

          // التحقق من الكمية المتاحة إذا كان decrementStock مفعلاً
          if (decrementStock) {
            final availableQty = product.first['quantity'] as int? ?? 0;
            if (quantity > availableQty) {
              throw Exception(
                  'الكمية المطلوبة ($quantity) أكبر من الكمية المتاحة ($availableQty)');
            }
          }
        }

        // حساب الإجمالي والربح
        double total = 0;
        double profit = 0;
        for (final it in items) {
          final rawPrice = (it['price'] as num).toDouble();
          final discountPercent =
              ((it['discount_percent'] ?? 0) as num).toDouble();
          final price = rawPrice * (1 - (discountPercent.clamp(0, 100) / 100));
          final cost = (it['cost'] as num).toDouble();
          final quantity = (it['quantity'] as num).toDouble();

          if (price.isFinite && quantity.isFinite && quantity > 0) {
            final qty = quantity.toInt();
            total += price * qty;
            profit += (price - cost) * qty;
          }
        }

        // تطبيق خصم الكوبون
        if (couponDiscount != null && couponDiscount > 0) {
          total = (total - couponDiscount).clamp(0.0, double.infinity);
        }

        // التحقق من أن الإجمالي أكبر من صفر
        if (total <= 0) {
          throw Exception('إجمالي البيع يجب أن يكون أكبر من صفر');
        }

        // إنشاء أو العثور على العميل
        int? ensuredCustomerId = customerId;
        if (ensuredCustomerId == null &&
            customerName?.trim().isNotEmpty == true) {
          // البحث عن العميل بالاسم فقط (تطبيع الاسم بإزالة المسافات الزائدة)
          final normalizedName =
              customerName!.trim().replaceAll(RegExp(r'\s+'), ' ');
          final existing = await txn.query('customers',
              where: "TRIM(REPLACE(REPLACE(name, '\t', ' '), '  ', ' ')) = ?",
              whereArgs: [normalizedName]);
          if (existing.isNotEmpty) {
            ensuredCustomerId = existing.first['id'] as int;
            // تحديث معلومات العميل إذا كانت هناك معلومات جديدة (هاتف أو عنوان)
            final updateData = <String, Object?>{};
            if (customerPhone?.trim().isNotEmpty == true) {
              final existingPhone = existing.first['phone']?.toString().trim();
              if (existingPhone == null || existingPhone.isEmpty) {
                updateData['phone'] = customerPhone!.trim();
              }
            }
            if (customerAddress?.trim().isNotEmpty == true) {
              final existingAddress =
                  existing.first['address']?.toString().trim();
              if (existingAddress == null || existingAddress.isEmpty) {
                updateData['address'] = customerAddress!.trim();
              }
            }
            if (updateData.isNotEmpty) {
              await txn.update('customers', updateData,
                  where: 'id = ?', whereArgs: [ensuredCustomerId]);
            }
          } else {
            ensuredCustomerId = await txn.insert('customers', {
              'name': normalizedName,
              'phone': customerPhone?.trim(),
              'address': customerAddress?.trim(),
              'total_debt': 0,
            });
          }
        }

        // إنشاء البيع
        final saleId = await txn.insert('sales', {
          'customer_id': ensuredCustomerId,
          'total': total,
          'profit': profit,
          'type': type,
          'created_at': DateTime.now().toIso8601String(),
          'due_date': dueDate?.toIso8601String(),
          'down_payment': downPayment ?? 0.0,
          'coupon_id': couponId,
          'coupon_discount': couponDiscount ?? 0.0,
        });

        // زيادة عدد استخدامات الكوبون إذا كان موجوداً
        if (couponId != null) {
          await txn.rawUpdate(
            'UPDATE discount_coupons SET used_count = used_count + 1 WHERE id = ?',
            [couponId],
          );
        }

        // إضافة عناصر البيع
        for (final it in items) {
          final rawPrice = (it['price'] as num).toDouble();
          final discountPercent =
              ((it['discount_percent'] ?? 0) as num).toDouble();
          final effectivePrice =
              rawPrice * (1 - (discountPercent.clamp(0, 100) / 100));
          final cost = (it['cost'] as num).toDouble();
          final quantity = (it['quantity'] as num).toDouble();

          await txn.insert('sale_items', {
            'sale_id': saleId,
            'product_id': it['product_id'],
            'price': effectivePrice,
            'cost': cost,
            'quantity': quantity.toInt(),
            'discount_percent': discountPercent,
          });

          if (decrementStock) {
            final qty = (it['quantity'] as num).toInt();
            final productId = it['product_id'] as int;
            // التحقق من أن الكمية لن تصبح سالبة
            final product = await txn.query('products',
                where: 'id = ?', whereArgs: [productId], limit: 1);
            if (product.isNotEmpty) {
              final currentQty = product.first['quantity'] as int? ?? 0;
              if (currentQty < qty) {
                throw Exception(
                    'الكمية المتاحة غير كافية للمنتج ${it['name'] ?? productId}');
              }
              await txn.rawUpdate(
                  'UPDATE products SET quantity = quantity - ? WHERE id = ?',
                  [qty, productId]);
            }
          }
        }

        // تسجيل حدث البيع
        try {
          final itemsCount = items.length;
          final itemsSummary =
              items.take(3).map((it) => it['name'] ?? 'منتج').join(', ');
          final description =
              'إنشاء بيع جديد - النوع: ${type == 'cash' ? 'نقدي' : type == 'credit' ? 'دين' : 'أقساط'} - الإجمالي: ${total.toStringAsFixed(2)}';
          final details =
              'عدد المنتجات: $itemsCount\nالمنتجات: $itemsSummary${itemsCount > 3 ? '...' : ''}\nالعميل: ${customerName ?? 'غير محدد'}';
          await logEvent(
            eventType: 'sale',
            entityType: 'sale',
            entityId: saleId,
            userId: userId,
            username: username,
            description: description,
            details: details,
            transaction: txn,
          );
        } catch (e) {
          debugPrint('خطأ في تسجيل حدث البيع: $e');
        }

        // معالجة الديون والأقساط (مبسط)
        if (ensuredCustomerId != null) {
          if (type == 'credit') {
            // دين مباشر
            await txn.rawUpdate(
                'UPDATE customers SET total_debt = IFNULL(total_debt,0) + ? WHERE id = ?',
                [total, ensuredCustomerId]);
          } else if (type == 'installment' &&
              installmentCount != null &&
              installmentCount > 0) {
            // بيع بالأقساط
            final downPaymentAmount = downPayment ?? 0.0;
            final remainingAmount = total - downPaymentAmount;
            final installmentAmount = remainingAmount / installmentCount;

            // إضافة المبلغ المتبقي للديون
            await txn.rawUpdate(
                'UPDATE customers SET total_debt = IFNULL(total_debt,0) + ? WHERE id = ?',
                [remainingAmount, ensuredCustomerId]);

            // إنشاء الأقساط
            DateTime currentDate = firstInstallmentDate ?? DateTime.now();
            for (int i = 0; i < installmentCount; i++) {
              await txn.insert('installments', {
                'sale_id': saleId,
                'due_date': currentDate.toIso8601String(),
                'amount': installmentAmount,
                'paid': 0,
                'paid_at': null,
              });
              currentDate = DateTime(
                  currentDate.year, currentDate.month + 1, currentDate.day);
            }
          }
        }

        return saleId;
      } catch (e) {
        debugPrint('خطأ في إنشاء البيع: $e');
        rethrow;
      }
    });
  }

  Future<void> adjustProductQuantity(int productId, int delta) async {
    await _db.rawUpdate(
        'UPDATE products SET quantity = quantity + ? WHERE id = ?',
        [delta, productId]);
  }

  Future<List<Map<String, Object?>>> getLowStock() async {
    return _db.query('products',
        where: 'quantity <= min_quantity', orderBy: 'quantity ASC');
  }

  Future<List<Map<String, Object?>>> getOutOfStock() async {
    return _db.query(
      'products',
      where: 'quantity <= 0',
      orderBy: 'updated_at IS NULL DESC, updated_at ASC',
    );
  }

  Future<List<Map<String, Object?>>> slowMovingProducts({int days = 30}) async {
    // products with no sales in X days
    final since =
        DateTime.now().subtract(Duration(days: days)).toIso8601String();
    return _db.rawQuery('''
      SELECT p.* FROM products p
      LEFT JOIN sale_items si ON si.product_id = p.id
      LEFT JOIN sales s ON s.id = si.sale_id AND s.created_at >= ?
      GROUP BY p.id
      HAVING COUNT(s.id) = 0
      ORDER BY p.updated_at IS NULL DESC, p.updated_at ASC
    ''', [since]);
  }

  Future<Map<String, double>> profitAndLoss(
      {DateTime? from, DateTime? to}) async {
    // التأكد من وجود الأعمدة المطلوبة
    await _ensureExpensesTableColumns(_db);

    // التحقق من وجود عمود expense_date
    final hasExpenseDate = await _columnExists(_db, 'expenses', 'expense_date');
    final dateColumn = hasExpenseDate ? 'expense_date' : 'created_at';

    final String where = (from != null && to != null)
        ? "WHERE s.created_at BETWEEN ? AND ?"
        : '';
    final args = (from != null && to != null)
        ? [from.toIso8601String(), to.toIso8601String()]
        : <Object?>[];
    final sales = await _db.rawQuery(
        'SELECT IFNULL(SUM(total),0) t, IFNULL(SUM(profit),0) p FROM sales s $where',
        args);
    // استخدام expense_date أو created_at حسب التوفر
    final expensesWhere =
        (from != null && to != null) ? 'WHERE $dateColumn BETWEEN ? AND ?' : '';
    final expensesArgs = (from != null && to != null)
        ? [from.toIso8601String(), to.toIso8601String()]
        : <Object?>[];
    final expenses = await _db.rawQuery(
        'SELECT IFNULL(SUM(amount),0) e FROM expenses $expensesWhere',
        expensesArgs);
    final totalSales = (sales.first['t'] as num?)?.toDouble() ?? 0.0;
    final totalProfit = (sales.first['p'] as num?)?.toDouble() ?? 0.0;
    final totalExpenses = (expenses.first['e'] as num?)?.toDouble() ?? 0.0;
    return {
      'sales': totalSales,
      'profit': totalProfit,
      'expenses': totalExpenses,
      'net': totalProfit - totalExpenses,
    };
  }

  // Sales History
  Future<List<Map<String, Object?>>> getSalesHistory({
    DateTime? from,
    DateTime? to,
    String? type,
    String? query,
    bool sortDescending = true,
    int? limit,
    int? offset,
  }) async {
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (from != null && to != null) {
      whereClause += 's.created_at BETWEEN ? AND ?';
      whereArgs.addAll([from.toIso8601String(), to.toIso8601String()]);
    }

    if (type != null && type.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 's.type = ?';
      whereArgs.add(type);
    }

    if (query != null && query.trim().isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += '(c.name LIKE ? OR p.name LIKE ? OR s.id LIKE ?)';
      final likeQuery = '%${query.trim()}%';
      whereArgs.addAll([likeQuery, likeQuery, likeQuery]);
    }

    final limitClause = limit != null ? 'LIMIT $limit' : '';
    final offsetClause = offset != null ? 'OFFSET $offset' : '';

    final sales = await _db.rawQuery('''
      SELECT 
        s.*,
        c.name as customer_name,
        c.phone as customer_phone,
        GROUP_CONCAT(p.name || ' (' || si.quantity || 'x' || si.price || ')') as items_summary
      FROM sales s
      LEFT JOIN customers c ON s.customer_id = c.id
      LEFT JOIN sale_items si ON s.id = si.sale_id
      LEFT JOIN products p ON si.product_id = p.id
      ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
      GROUP BY s.id
      ORDER BY s.id ${sortDescending ? 'DESC' : 'ASC'}
      $limitClause $offsetClause
    ''', whereArgs);

    return sales;
  }

  Future<List<Map<String, Object?>>> getSaleItems(int saleId) async {
    return await _db.rawQuery('''
      SELECT 
        si.*,
        p.name as product_name,
        p.barcode
      FROM sale_items si
      JOIN products p ON si.product_id = p.id
      WHERE si.sale_id = ?
      ORDER BY si.id
    ''', [saleId]);
  }

  Future<Map<String, Object?>?> getSaleDetails(int saleId) async {
    final result = await _db.rawQuery('''
      SELECT 
        s.*,
        c.name as customer_name,
        c.phone as customer_phone,
        c.address as customer_address
      FROM sales s
      LEFT JOIN customers c ON s.customer_id = c.id
      WHERE s.id = ?
    ''', [saleId]);

    return result.isNotEmpty ? result.first : null;
  }

  Future<bool> deleteSale(int saleId,
      {int? userId, String? username, String? name}) async {
    return await _db.transaction<bool>((txn) async {
      try {
        // Get sale to adjust debts if needed
        final sale = await txn.query('sales',
            where: 'id = ?', whereArgs: [saleId], limit: 1);

        if (sale.isEmpty) {
          debugPrint('البيع غير موجود: $saleId');
          return false;
        }

        // Get sale items to restore stock
        final saleItems = await txn.query(
          'sale_items',
          where: 'sale_id = ?',
          whereArgs: [saleId],
        );

        // Restore stock for each item
        for (final item in saleItems) {
          try {
            await txn.rawUpdate(
              'UPDATE products SET quantity = quantity + ? WHERE id = ?',
              [item['quantity'], item['product_id']],
            );
          } catch (e) {
            debugPrint('خطأ في إرجاع المخزون للمنتج ${item['product_id']}: $e');
            // نتابع حتى لو فشل إرجاع المخزون
          }
        }

        // حفظ بيانات البيع في سلة المحذوفات قبل الحذف
        final saleData = sale.first;
        await txn.insert('deleted_items', {
          'entity_type': 'sale',
          'entity_id': saleId,
          'original_data': jsonEncode(saleData),
          'deleted_by_user_id': userId,
          'deleted_by_username': username,
          'deleted_by_name': name,
          'deleted_at': DateTime.now().toIso8601String(),
          'can_restore': 1,
        });

        // Delete sale items
        try {
          await txn
              .execute('DELETE FROM sale_items WHERE sale_id = ?', [saleId]);
        } catch (e) {
          debugPrint('خطأ في حذف sale_items: $e');
          rethrow;
        }

        // Delete any related installments
        try {
          await txn
              .execute('DELETE FROM installments WHERE sale_id = ?', [saleId]);
        } catch (e) {
          debugPrint('خطأ في حذف installments: $e');
          // نتابع حتى لو فشل حذف الأقساط
        }

        // Delete the sale
        final deletedRows = await txn.rawDelete(
          'DELETE FROM sales WHERE id = ?',
          [saleId],
        );

        // تسجيل حدث حذف البيع (باستخدام transaction لتجنب deadlock)
        if (deletedRows > 0) {
          try {
            final saleData = sale.first;
            final total = (saleData['total'] as num).toDouble();
            final type = saleData['type'] as String? ?? '';
            await logEvent(
              eventType: 'delete',
              entityType: 'sale',
              entityId: saleId,
              userId: userId,
              username: username,
              description:
                  'حذف بيع - النوع: ${type == 'cash' ? 'نقدي' : type == 'credit' ? 'دين' : 'أقساط'} - الإجمالي: ${total.toStringAsFixed(2)}',
              details: 'تم حذف البيع رقم $saleId',
              transaction: txn,
            );
          } catch (e) {
            debugPrint('خطأ في تسجيل حدث حذف البيع: $e');
          }
        }

        // Adjust customer debt if the deleted sale was credit
        if (deletedRows > 0 && sale.isNotEmpty) {
          final s = sale.first;
          if (s['type'] == 'credit' && s['customer_id'] != null) {
            try {
              await txn.rawUpdate(
                'UPDATE customers SET total_debt = MAX(IFNULL(total_debt,0) - ?, 0) WHERE id = ?',
                [(s['total'] as num).toDouble(), s['customer_id']],
              );
            } catch (e) {
              debugPrint('خطأ في تعديل دين العميل: $e');
              // لا نرمي الخطأ هنا لأن الحذف تم بنجاح
            }
          }
        }

        return deletedRows > 0;
      } catch (e) {
        debugPrint('خطأ في حذف البيع $saleId: $e');
        return false;
      }
    });
  }

  // Receivables and credit tracking (includes installments)
  Future<List<Map<String, Object?>>> receivablesByCustomer(
      {String? query}) async {
    final where = <String>[];
    final args = <Object?>[];
    if (query != null && query.trim().isNotEmpty) {
      final like = '%${query.trim()}%';
      where.add('(c.name LIKE ? OR c.phone LIKE ?)');
      args.addAll([like, like]);
    }
    final sql = '''
      SELECT 
        c.id,
        c.name,
        c.phone,
        IFNULL(c.total_debt, 0) AS total_debt,
        IFNULL((
          SELECT SUM(s.total) FROM sales s 
          WHERE s.customer_id = c.id AND s.type = 'credit'
        ), 0) AS credit_debt,
        IFNULL((
          SELECT SUM(s.total - COALESCE(s.down_payment, 0)) FROM sales s 
          WHERE s.customer_id = c.id AND s.type = 'installment'
        ), 0) AS installment_debt,
        (
          SELECT MIN(s2.due_date) FROM sales s2 
          WHERE s2.customer_id = c.id AND s2.type = 'credit' AND s2.due_date IS NOT NULL
        ) AS next_credit_due_date,
        (
          SELECT MIN(i.due_date) FROM installments i
          JOIN sales s ON s.id = i.sale_id
          WHERE s.customer_id = c.id AND i.paid = 0
        ) AS next_installment_due_date,
        (
          SELECT COUNT(*) FROM installments i
          JOIN sales s ON s.id = i.sale_id
          WHERE s.customer_id = c.id AND i.paid = 0 AND i.due_date < ?
        ) AS overdue_installments_count
      FROM customers c
      WHERE IFNULL(c.total_debt, 0) > 0
      ${where.isNotEmpty ? 'AND ${where.join(' AND ')}' : ''}
      ORDER BY 
        (CASE WHEN next_credit_due_date IS NULL AND next_installment_due_date IS NULL THEN 1 ELSE 0 END),
        COALESCE(next_credit_due_date, next_installment_due_date) ASC,
        c.name ASC
    ''';
    args.insert(0, DateTime.now().toIso8601String());
    return _db.rawQuery(sql, args);
  }

  Future<List<Map<String, Object?>>> creditSales(
      {bool overdueOnly = false,
      int? customerId,
      DateTime? from,
      DateTime? to}) async {
    final where = <String>['s.type = "credit"'];
    final args = <Object?>[];
    if (customerId != null) {
      where.add('s.customer_id = ?');
      args.add(customerId);
    }
    if (from != null && to != null) {
      where.add('s.created_at BETWEEN ? AND ?');
      args.addAll([from.toIso8601String(), to.toIso8601String()]);
    }
    if (overdueOnly) {
      where.add('s.due_date IS NOT NULL AND s.due_date < ?');
      args.add(DateTime.now().toIso8601String());
    }
    final sql = '''
      SELECT s.*, c.name AS customer_name, c.phone AS customer_phone
      FROM sales s
      LEFT JOIN customers c ON c.id = s.customer_id
      WHERE ${where.join(' AND ')}
      ORDER BY (CASE WHEN s.due_date IS NULL THEN 1 ELSE 0 END), s.due_date ASC, s.created_at DESC
    ''';
    return _db.rawQuery(sql, args);
  }

  // Payment collection system
  Future<int> addPayment({
    required int customerId,
    required double amount,
    required DateTime paymentDate,
    String? notes,
  }) async {
    return _db.transaction<int>((txn) async {
      // Insert payment record
      final paymentId = await txn.insert('payments', {
        'customer_id': customerId,
        'amount': amount,
        'payment_date': paymentDate.toIso8601String(),
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Reduce customer debt
      await txn.rawUpdate(
        'UPDATE customers SET total_debt = MAX(IFNULL(total_debt, 0) - ?, 0) WHERE id = ?',
        [amount, customerId],
      );

      // تقليل الأقساط المتبقية
      await _reduceInstallmentsFromPayment(txn, customerId, amount);

      return paymentId;
    });
  }

  /// تقليل الأقساط المتبقية عند الدفع الإضافي بالتساوي
  Future<void> _reduceInstallmentsFromPayment(
      DatabaseExecutor txn, int customerId, double paymentAmount) async {
    try {
      // الحصول على الأقساط المتبقية للعميل
      final unpaidInstallments = await txn.rawQuery('''
        SELECT i.* FROM installments i
        JOIN sales s ON s.id = i.sale_id
        WHERE s.customer_id = ? AND i.paid = 0 AND i.amount > 0
        ORDER BY i.due_date ASC
      ''', [customerId]);

      if (unpaidInstallments.isEmpty) {
        return;
      }

      final installmentCount = unpaidInstallments.length;
      final amountPerInstallment = paymentAmount / installmentCount;

      for (final installment in unpaidInstallments) {
        final installmentId = installment['id'] as int;
        final currentAmount = (installment['amount'] as num).toDouble();
        final newAmount =
            (currentAmount - amountPerInstallment).clamp(0.0, double.infinity);

        if (newAmount <= 0) {
          // القسط مدفوع بالكامل
          await txn.update(
            'installments',
            {
              'amount': 0.0,
              'paid': 1,
              'paid_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [installmentId],
          );
        } else {
          // تقليل مبلغ القسط
          await txn.update(
            'installments',
            {'amount': newAmount},
            where: 'id = ?',
            whereArgs: [installmentId],
          );
        }
      }
    } catch (e) {
      // لا نريد إيقاف العملية إذا فشل تقليل الأقساط
    }
  }

  Future<List<Map<String, Object?>>> getCustomerPayments({
    int? customerId,
    DateTime? from,
    DateTime? to,
  }) async {
    final where = <String>[];
    final args = <Object?>[];

    if (customerId != null) {
      where.add('p.customer_id = ?');
      args.add(customerId);
    }

    if (from != null && to != null) {
      where.add('p.payment_date BETWEEN ? AND ?');
      args.addAll([from.toIso8601String(), to.toIso8601String()]);
    }

    final sql = '''
      SELECT 
        p.*,
        c.name as customer_name,
        c.phone as customer_phone
      FROM payments p
      JOIN customers c ON c.id = p.customer_id
      ${where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : ''}
      ORDER BY p.payment_date DESC, p.created_at DESC
    ''';

    return _db.rawQuery(sql, args);
  }

  // Debt statistics and analytics
  Future<Map<String, double>> getDebtStatistics() async {
    final totalDebt = await _db.rawQuery('''
      SELECT IFNULL(SUM(total_debt), 0) as total FROM customers
    ''');

    final overdueDebt = await _db.rawQuery('''
      SELECT IFNULL(SUM(s.total), 0) as overdue
      FROM sales s
      WHERE s.type = 'credit' 
        AND s.due_date IS NOT NULL 
        AND s.due_date < ?
    ''', [DateTime.now().toIso8601String()]);

    final totalPayments = await _db.rawQuery('''
      SELECT IFNULL(SUM(amount), 0) as total FROM payments
    ''');

    final customersWithDebt = await _db.rawQuery('''
      SELECT COUNT(*) as count FROM customers WHERE total_debt > 0
    ''');

    return {
      'total_debt': (totalDebt.first['total'] as num).toDouble(),
      'overdue_debt': (overdueDebt.first['overdue'] as num).toDouble(),
      'total_payments': (totalPayments.first['total'] as num).toDouble(),
      'customers_with_debt':
          (customersWithDebt.first['count'] as num).toDouble(),
    };
  }

  // Debt aging report
  Future<List<Map<String, Object?>>> getDebtAgingReport() async {
    return _db.rawQuery('''
      SELECT 
        c.id,
        c.name,
        c.phone,
        c.total_debt,
        COUNT(CASE 
          WHEN s.due_date IS NULL THEN 1 
          WHEN s.due_date >= ? THEN 1 
          ELSE NULL 
        END) as current_count,
        COUNT(CASE 
          WHEN s.due_date < ? AND s.due_date >= ? THEN 1 
          ELSE NULL 
        END) as overdue_30_count,
        COUNT(CASE 
          WHEN s.due_date < ? AND s.due_date >= ? THEN 1 
          ELSE NULL 
        END) as overdue_60_count,
        COUNT(CASE 
          WHEN s.due_date < ? THEN 1 
          ELSE NULL 
        END) as overdue_90_count,
        SUM(CASE 
          WHEN s.due_date IS NULL THEN s.total 
          WHEN s.due_date >= ? THEN s.total 
          ELSE 0 
        END) as current_amount,
        SUM(CASE 
          WHEN s.due_date < ? AND s.due_date >= ? THEN s.total 
          ELSE 0 
        END) as overdue_30_amount,
        SUM(CASE 
          WHEN s.due_date < ? AND s.due_date >= ? THEN s.total 
          ELSE 0 
        END) as overdue_60_amount,
        SUM(CASE 
          WHEN s.due_date < ? THEN s.total 
          ELSE 0 
        END) as overdue_90_amount
      FROM customers c
      LEFT JOIN sales s ON s.customer_id = c.id AND s.type = 'credit'
      WHERE c.total_debt > 0
      GROUP BY c.id, c.name, c.phone, c.total_debt
      ORDER BY c.total_debt DESC
    ''', [
      DateTime.now().toIso8601String(), // current
      DateTime.now().toIso8601String(), // overdue_30
      DateTime.now()
          .subtract(Duration(days: 30))
          .toIso8601String(), // overdue_30
      DateTime.now()
          .subtract(Duration(days: 30))
          .toIso8601String(), // overdue_60
      DateTime.now()
          .subtract(Duration(days: 60))
          .toIso8601String(), // overdue_60
      DateTime.now()
          .subtract(Duration(days: 60))
          .toIso8601String(), // overdue_90
      DateTime.now().toIso8601String(), // current_amount
      DateTime.now().toIso8601String(), // overdue_30_amount
      DateTime.now()
          .subtract(Duration(days: 30))
          .toIso8601String(), // overdue_30_amount
      DateTime.now()
          .subtract(Duration(days: 30))
          .toIso8601String(), // overdue_60_amount
      DateTime.now()
          .subtract(Duration(days: 60))
          .toIso8601String(), // overdue_60_amount
      DateTime.now()
          .subtract(Duration(days: 60))
          .toIso8601String(), // overdue_90_amount
    ]);
  }

  // Overdue debt alerts
  Future<List<Map<String, Object?>>> getOverdueDebts(
      {int daysOverdue = 0}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOverdue));
    return _db.rawQuery('''
      SELECT 
        s.*,
        c.name as customer_name,
        c.phone as customer_phone,
        c.address as customer_address,
        julianday('now') - julianday(s.due_date) as days_overdue
      FROM sales s
      JOIN customers c ON c.id = s.customer_id
      WHERE s.type = 'credit' 
        AND s.due_date IS NOT NULL 
        AND s.due_date < ?
      ORDER BY s.due_date ASC
    ''', [cutoffDate.toIso8601String()]);
  }

  // Delete payment
  Future<bool> deletePayment(int paymentId,
      {int? userId, String? username, String? name}) async {
    return _db.transaction<bool>((txn) async {
      try {
        // Get payment details
        final payment = await txn.query('payments',
            where: 'id = ?', whereArgs: [paymentId], limit: 1);

        if (payment.isEmpty) return false;

        final p = payment.first;
        final customerId = p['customer_id'] as int;
        final amount = (p['amount'] as num).toDouble();

        // حفظ بيانات المدفوعة في سلة المحذوفات قبل الحذف
        await txn.insert('deleted_items', {
          'entity_type': 'payment',
          'entity_id': paymentId,
          'original_data': jsonEncode(p),
          'deleted_by_user_id': userId,
          'deleted_by_username': username,
          'deleted_by_name': name,
          'deleted_at': DateTime.now().toIso8601String(),
          'can_restore': 1,
        });

        // Delete payment
        final deletedRows = await txn
            .delete('payments', where: 'id = ?', whereArgs: [paymentId]);

        if (deletedRows > 0) {
          // Restore customer debt
          await txn.rawUpdate(
            'UPDATE customers SET total_debt = IFNULL(total_debt, 0) + ? WHERE id = ?',
            [amount, customerId],
          );
        }

        return deletedRows > 0;
      } catch (e) {
        return false;
      }
    });
  }

  /// دالة شاملة لتنظيف قاعدة البيانات من المراجع القديمة
  Future<void> comprehensiveCleanup() async {
    try {
      await _db.execute('PRAGMA foreign_keys = OFF');

      // حذف جدول sales_old إذا كان موجوداً
      await _db.execute('DROP TABLE IF EXISTS sales_old');

      // البحث عن جميع الكائنات التي تشير إلى sales_old في المخطط الرئيسي
      final mainObjects = await _db.rawQuery('''
        SELECT type, name, sql FROM sqlite_master 
        WHERE type IN ('trigger', 'view', 'index', 'table') 
        AND (IFNULL(sql,'') LIKE '%sales_old%' OR name LIKE '%sales_old%')
        ORDER BY type, name
      ''');

      for (final row in mainObjects) {
        final type = row['type']?.toString();
        final name = row['name']?.toString();
        if (type != null && name != null && name.isNotEmpty) {
          try {
            String dropCommand;
            switch (type) {
              case 'view':
                dropCommand = 'DROP VIEW IF EXISTS $name';
                break;
              case 'index':
                dropCommand = 'DROP INDEX IF EXISTS $name';
                break;
              case 'trigger':
                dropCommand = 'DROP TRIGGER IF EXISTS $name';
                break;
              case 'table':
                if (name == 'sales_old') {
                  dropCommand = 'DROP TABLE IF EXISTS $name';
                } else {
                  continue; // Skip other tables
                }
                break;
              default:
                continue;
            }
            await _db.execute(dropCommand);
            debugPrint('Dropped main schema $type: $name');
          } catch (e) {
            debugPrint('Error dropping main schema $type $name: $e');
          }
        }
      }

      // البحث عن جميع الكائنات التي تشير إلى sales_old في المخطط المؤقت
      final tempObjects = await _db.rawQuery('''
        SELECT type, name, sql FROM sqlite_temp_master 
        WHERE type IN ('trigger', 'view', 'index', 'table') 
        AND (IFNULL(sql,'') LIKE '%sales_old%' OR name LIKE '%sales_old%')
        ORDER BY type, name
      ''');

      for (final row in tempObjects) {
        final type = row['type']?.toString();
        final name = row['name']?.toString();
        if (type != null && name != null && name.isNotEmpty) {
          try {
            String dropCommand;
            switch (type) {
              case 'view':
                dropCommand = 'DROP VIEW IF EXISTS $name';
                break;
              case 'index':
                dropCommand = 'DROP INDEX IF EXISTS $name';
                break;
              case 'trigger':
                dropCommand = 'DROP TRIGGER IF EXISTS $name';
                break;
              case 'table':
                if (name == 'sales_old') {
                  dropCommand = 'DROP TABLE IF EXISTS $name';
                } else {
                  continue; // Skip other tables
                }
                break;
              default:
                continue;
            }
            await _db.execute(dropCommand);
          } catch (e) {
            debugPrint('Error dropping temp schema $type $name: $e');
          }
        }
      }

      // إعادة تمكين المفاتيح الخارجية
      await _db.execute('PRAGMA foreign_keys = ON');

      // إعادة إنشاء الفهارس
      await DatabaseSchema.createIndexes(_db);
    } catch (e) {
      await _db.execute('PRAGMA foreign_keys = ON');
      rethrow;
    }
  }

  // دالة تعديل القسط
  Future<void> updateInstallment(
      int installmentId, double newAmount, DateTime newDueDate) async {
    await _db.transaction((txn) async {
      // الحصول على بيانات القسط الحالية
      final installment = await txn.query(
        'installments',
        where: 'id = ?',
        whereArgs: [installmentId],
      );

      if (installment.isEmpty) {
        throw Exception('القسط غير موجود');
      }

      final installmentData = installment.first;
      final isPaid = (installmentData['paid'] as int?) == 1;
      final oldAmount = (installmentData['amount'] as num).toDouble();
      final saleId = installmentData['sale_id'] as int;

      // التحقق من أن القسط غير مدفوع قبل التعديل
      if (isPaid) {
        throw Exception('لا يمكن تعديل قسط مدفوع');
      }

      // تحديث بيانات القسط
      await txn.update(
        'installments',
        {
          'amount': newAmount,
          'due_date': newDueDate.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [installmentId],
      );

      // تحديث دين العميل إذا تغير المبلغ
      if (oldAmount != newAmount) {
        final sale = await txn.query(
          'sales',
          where: 'id = ?',
          whereArgs: [saleId],
        );

        if (sale.isNotEmpty) {
          final customerId = sale.first['customer_id'] as int;
          final amountDifference = newAmount - oldAmount;

          // تحديث دين العميل بالفرق بين المبلغ القديم والجديد
          await txn.rawUpdate(
            'UPDATE customers SET total_debt = IFNULL(total_debt, 0) + ? WHERE id = ?',
            [amountDifference, customerId],
          );
        }
      }
    });
  }

  // دالة حذف القسط
  Future<void> deleteInstallment(int installmentId,
      {int? userId, String? username, String? name}) async {
    await _db.transaction((txn) async {
      // الحصول على بيانات القسط
      final installment = await txn.query(
        'installments',
        where: 'id = ?',
        whereArgs: [installmentId],
      );

      if (installment.isEmpty) {
        throw Exception('القسط غير موجود');
      }

      final installmentData = installment.first;
      final saleId = installmentData['sale_id'] as int;
      final amount = (installmentData['amount'] as num).toDouble();
      final isPaid = (installmentData['paid'] as int?) == 1;

      // التحقق من أن القسط غير مدفوع قبل الحذف
      if (isPaid) {
        throw Exception(
            'لا يمكن حذف قسط مدفوع. يجب حذف المدفوعة المرتبطة به من سجل المدفوعات أولاً.');
      }

      // حفظ بيانات القسط في سلة المحذوفات قبل الحذف
      await txn.insert('deleted_items', {
        'entity_type': 'installment',
        'entity_id': installmentId,
        'original_data': jsonEncode(installmentData),
        'deleted_by_user_id': userId,
        'deleted_by_username': username,
        'deleted_by_name': name,
        'deleted_at': DateTime.now().toIso8601String(),
        'can_restore': 1,
      });

      // الحصول على بيانات البيع
      final sale = await txn.query(
        'sales',
        where: 'id = ?',
        whereArgs: [saleId],
      );

      if (sale.isNotEmpty) {
        final customerId = sale.first['customer_id'] as int;

        // إضافة المبلغ إلى دين العميل فقط إذا كان القسط غير مدفوع
        // لأن القسط المدفوع تم خصم مبلغه من الدين عند الدفع
        if (!isPaid) {
          await txn.rawUpdate(
            'UPDATE customers SET total_debt = IFNULL(total_debt, 0) + ? WHERE id = ?',
            [amount, customerId],
          );
        }
      }

      // حذف القسط
      await txn.delete(
        'installments',
        where: 'id = ?',
        whereArgs: [installmentId],
      );
    });
  }

  // دالة الحصول على الأقساط المتأخرة
  Future<List<Map<String, dynamic>>> getOverdueInstallments() async {
    final now = DateTime.now().toIso8601String();
    return _db.rawQuery('''
      SELECT 
        i.*,
        s.customer_id,
        c.name as customer_name,
        c.phone as customer_phone,
        c.address as customer_address,
        julianday('now') - julianday(i.due_date) as days_overdue
      FROM installments i
      JOIN sales s ON i.sale_id = s.id
      JOIN customers c ON s.customer_id = c.id
      WHERE i.paid = 0 
      AND i.due_date < ?
      ORDER BY i.due_date ASC
    ''', [now]);
  }

  // دالة الحصول على الأقساط المستحقة هذا الشهر
  Future<List<Map<String, dynamic>>> getCurrentMonthInstallments() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
    final endOfMonth = DateTime(now.year, now.month + 1, 0).toIso8601String();

    return _db.rawQuery('''
      SELECT 
        i.*,
        s.customer_id,
        c.name as customer_name,
        c.phone as customer_phone,
        c.address as customer_address
      FROM installments i
      JOIN sales s ON i.sale_id = s.id
      JOIN customers c ON s.customer_id = c.id
      WHERE i.paid = 0 
      AND i.due_date >= ? 
      AND i.due_date <= ?
      ORDER BY i.due_date ASC
    ''', [startOfMonth, endOfMonth]);
  }

  // دالة تنظيف شاملة لجميع triggers
  Future<void> cleanupAllTriggers() async {
    await _db.transaction((txn) async {
      try {
        // البحث عن جميع triggers
        final allTriggers = await txn.rawQuery('''
          SELECT name, sql FROM sqlite_master 
          WHERE type = 'trigger'
        ''');

        for (final trigger in allTriggers) {
          final name = trigger['name']?.toString();
          final sql = trigger['sql']?.toString();

          if (name != null && sql != null) {
            // حذف triggers التي تحتوي على sales_old أو أي مراجع مشكلة
            if (sql.contains('sales_old') ||
                sql.contains('main.sales_old') ||
                name.contains('sales_old')) {
              try {
                await txn.execute('DROP TRIGGER IF EXISTS $name');
              } catch (e) {
                debugPrint('Error dropping trigger $name: $e');
              }
            }
          }
        }
      } catch (e) {
        rethrow;
      }
    });
  }

  // دالة تنظيف شاملة لجميع مراجع sales_old
  Future<void> comprehensiveSalesOldCleanup() async {
    await _db.transaction((txn) async {
      try {
        // تعطيل المفاتيح الخارجية مؤقتاً
        await txn.execute('PRAGMA foreign_keys = OFF');

        // حذف جدول sales_old إذا كان موجوداً
        await txn.execute('DROP TABLE IF EXISTS sales_old');

        // البحث عن جميع الكائنات التي تحتوي على مراجع لـ sales_old
        final allObjects = await txn.rawQuery('''
          SELECT name, type, sql FROM sqlite_master 
          WHERE (sql LIKE '%sales_old%' OR name LIKE '%sales_old%')
          AND type IN ('trigger', 'view', 'index')
          UNION ALL
          SELECT name, type, sql FROM sqlite_temp_master 
          WHERE (sql LIKE '%sales_old%' OR name LIKE '%sales_old%')
          AND type IN ('trigger', 'view', 'index')
        ''');

        for (final obj in allObjects) {
          final name = obj['name']?.toString();
          final type = obj['type']?.toString();
          if (name != null && name.isNotEmpty) {
            try {
              switch (type) {
                case 'trigger':
                  await txn.execute('DROP TRIGGER IF EXISTS $name');
                  break;
                case 'view':
                  await txn.execute('DROP VIEW IF EXISTS $name');
                  break;
                case 'index':
                  await txn.execute('DROP INDEX IF EXISTS $name');
                  break;
              }
            } catch (e) {
              debugPrint('Error dropping $type $name: $e');
            }
          }
        }

        // إعادة تفعيل المفاتيح الخارجية
        await txn.execute('PRAGMA foreign_keys = ON');
      } catch (e) {
        // التأكد من إعادة تفعيل المفاتيح الخارجية حتى لو فشل التنظيف
        try {
          await txn.execute('PRAGMA foreign_keys = ON');
        } catch (_) {}
        rethrow;
      }
    });
  }

  // دالة الحصول على إحصائيات الأقساط
  Future<Map<String, dynamic>> getInstallmentStatistics() async {
    final now = DateTime.now().toIso8601String();

    final totalInstallments = await _db.rawQuery('''
      SELECT COUNT(*) as count, SUM(amount) as total
      FROM installments
    ''');

    final paidInstallments = await _db.rawQuery('''
      SELECT COUNT(*) as count, SUM(amount) as total
      FROM installments
      WHERE paid = 1
    ''');

    final unpaidInstallments = await _db.rawQuery('''
      SELECT COUNT(*) as count, SUM(amount) as total
      FROM installments
      WHERE paid = 0
    ''');

    final overdueInstallments = await _db.rawQuery('''
      SELECT COUNT(*) as count, SUM(amount) as total
      FROM installments
      WHERE paid = 0 AND due_date < ?
    ''', [now]);

    return {
      'total_count': (totalInstallments.first['count'] as int),
      'total_amount':
          (totalInstallments.first['total'] as num?)?.toDouble() ?? 0.0,
      'paid_count': (paidInstallments.first['count'] as int),
      'paid_amount':
          (paidInstallments.first['total'] as num?)?.toDouble() ?? 0.0,
      'unpaid_count': (unpaidInstallments.first['count'] as int),
      'unpaid_amount':
          (unpaidInstallments.first['total'] as num?)?.toDouble() ?? 0.0,
      'overdue_count': (overdueInstallments.first['count'] as int),
      'overdue_amount':
          (overdueInstallments.first['total'] as num?)?.toDouble() ?? 0.0,
    };
  }

  // دالة الحصول على ملخص أقساط فاتورة محددة
  Future<Map<String, dynamic>> getSaleInstallmentSummary(int saleId) async {
    final now = DateTime.now().toIso8601String();

    final totalInstallments = await _db.rawQuery('''
      SELECT COUNT(*) as count, SUM(amount) as total
      FROM installments
      WHERE sale_id = ?
    ''', [saleId]);

    final paidInstallments = await _db.rawQuery('''
      SELECT COUNT(*) as count, SUM(amount) as total
      FROM installments
      WHERE sale_id = ? AND paid = 1
    ''', [saleId]);

    final unpaidInstallments = await _db.rawQuery('''
      SELECT COUNT(*) as count, SUM(amount) as total
      FROM installments
      WHERE sale_id = ? AND paid = 0
    ''', [saleId]);

    final overdueInstallments = await _db.rawQuery('''
      SELECT COUNT(*) as count, SUM(amount) as total
      FROM installments
      WHERE sale_id = ? AND paid = 0 AND due_date < ?
    ''', [saleId, now]);

    return {
      'totalDebt':
          (totalInstallments.first['total'] as num?)?.toDouble() ?? 0.0,
      'totalPaid': (paidInstallments.first['total'] as num?)?.toDouble() ?? 0.0,
      'remainingDebt':
          (unpaidInstallments.first['total'] as num?)?.toDouble() ?? 0.0,
      'overdueAmount':
          (overdueInstallments.first['total'] as num?)?.toDouble() ?? 0.0,
      'totalCount': (totalInstallments.first['count'] as int),
      'paidCount': (paidInstallments.first['count'] as int),
      'unpaidCount': (unpaidInstallments.first['count'] as int),
      'overdueCount': (overdueInstallments.first['count'] as int),
    };
  }

  /// دالة شاملة لحذف جميع البيانات من قاعدة البيانات
  /// تحذف جميع الجداول عدا الجداول الأساسية (users, settings)
  Future<void> deleteAllData() async {
    try {
      await _db.execute('PRAGMA foreign_keys = OFF');

      // حذف جميع البيانات من الجداول بالترتيب الصحيح
      await _db.delete('payments');

      await _db.delete('installments');

      await _db.delete('sale_items');

      await _db.delete('sales');

      await _db.delete('expenses');

      await _db.delete('customers');

      await _db.delete('suppliers');

      await _db.delete('products');

      await _db.delete('categories');

      // إعادة تعيين AUTO_INCREMENT للجداول
      await _db.execute(
          'DELETE FROM sqlite_sequence WHERE name IN (?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            'payments',
            'installments',
            'sale_items',
            'sales',
            'expenses',
            'customers',
            'suppliers',
            'products',
            'categories'
          ]);

      await _db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      await _db.execute('PRAGMA foreign_keys = ON');
      rethrow;
    }
  }

  /// دالة للتحقق من وجود بيانات في قاعدة البيانات
  Future<Map<String, int>> checkDataExists() async {
    final result = <String, int>{};

    try {
      // فحص جدول المبيعات
      final salesCount =
          await _db.rawQuery('SELECT COUNT(*) as count FROM sales');
      result['المبيعات'] = salesCount.first['count'] as int;

      // فحص جدول المنتجات
      final productsCount =
          await _db.rawQuery('SELECT COUNT(*) as count FROM products');
      result['المنتجات'] = productsCount.first['count'] as int;

      // فحص جدول العملاء
      final customersCount =
          await _db.rawQuery('SELECT COUNT(*) as count FROM customers');
      result['العملاء'] = customersCount.first['count'] as int;

      // فحص جدول المصاريف
      final expensesCount =
          await _db.rawQuery('SELECT COUNT(*) as count FROM expenses');
      result['المصاريف'] = expensesCount.first['count'] as int;

      // فحص جدول الأقساط
      final installmentsCount =
          await _db.rawQuery('SELECT COUNT(*) as count FROM installments');
      result['الأقساط'] = installmentsCount.first['count'] as int;

      // فحص جدول المدفوعات
      final paymentsCount =
          await _db.rawQuery('SELECT COUNT(*) as count FROM payments');
      result['المدفوعات'] = paymentsCount.first['count'] as int;

      // فحص جدول عناصر المبيعات
      final saleItemsCount =
          await _db.rawQuery('SELECT COUNT(*) as count FROM sale_items');
      result['عناصر المبيعات'] = saleItemsCount.first['count'] as int;
    } catch (e) {
      debugPrint('Error checking data existence: $e');
    }

    return result;
  }

  /// دالة لإعادة تعيين جميع الديون في جدول العملاء
  Future<void> resetAllCustomerDebts() async {
    try {
      await _db.execute('UPDATE customers SET total_debt = 0');
    } catch (e) {
      rethrow;
    }
  }

  /// إنشاء نسخة احتياطية كاملة محسنة لقاعدة البيانات
  Future<String> createFullBackup(String backupPath) async {
    try {
      final timestamp = DateTime.now();
      final formattedDate =
          '${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}';
      final fileName = 'office_system_backup_$formattedDate.db';
      final backupFile = File(p.join(backupPath, fileName));

      // إنشاء مجلد النسخ الاحتياطي إذا لم يكن موجوداً
      final backupDir = Directory(backupPath);
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // تنظيف النسخ القديمة (الاحتفاظ بآخر 10 نسخ فقط)
      await _cleanupOldBackups(backupPath);

      // التحقق من وجود مساحة كافية
      final dbSize = await File(_dbPath).length();
      final availableSpace = await _getAvailableDiskSpace(backupPath);
      if (availableSpace < dbSize * 1.5) {
        // نحتاج مساحة إضافية للتأكد
        throw Exception('مساحة القرص غير كافية لإنشاء النسخة الاحتياطية');
      }

      // إنشاء نسخة احتياطية من البيانات الحالية قبل الإغلاق
      try {
        await _db.execute('PRAGMA wal_checkpoint(FULL)');
        await _db.execute('PRAGMA optimize');
      } catch (e) {
        debugPrint('تحذير: فشل في تحسين قاعدة البيانات قبل النسخ: $e');
      }

      // إغلاق قاعدة البيانات مؤقتاً لضمان النسخ الكامل
      try {
        await _db.close();
      } catch (e) {
        debugPrint('تحذير: قاعدة البيانات قد تكون مغلقة بالفعل: $e');
      }

      try {
        // نسخ ملف قاعدة البيانات الرئيسي
        await File(_dbPath).copy(backupFile.path);

        // نسخ ملف WAL إذا كان موجوداً
        final walFile = File('$_dbPath-wal');
        if (await walFile.exists()) {
          final backupWalFile = File('${backupFile.path}-wal');
          await walFile.copy(backupWalFile.path);
        }

        // نسخ ملف SHM إذا كان موجوداً
        final shmFile = File('$_dbPath-shm');
        if (await shmFile.exists()) {
          final backupShmFile = File('${backupFile.path}-shm');
          await shmFile.copy(backupShmFile.path);
        }

        // التحقق من صحة النسخة الاحتياطية
        final backupDb = await openDatabase(backupFile.path, readOnly: true);
        await backupDb.rawQuery('SELECT COUNT(*) FROM sqlite_master');
        await backupDb.close();
      } catch (copyError) {
        // إذا فشل النسخ، حذف جميع الملفات المكسورة
        if (await backupFile.exists()) {
          await backupFile.delete();
        }
        final backupWalFile = File('${backupFile.path}-wal');
        if (await backupWalFile.exists()) {
          await backupWalFile.delete();
        }
        final backupShmFile = File('${backupFile.path}-shm');
        if (await backupShmFile.exists()) {
          await backupShmFile.delete();
        }
        rethrow;
      }

      // إعادة فتح قاعدة البيانات مع التحسينات
      _db = await openDatabase(_dbPath, version: _dbVersion);
      await _db.execute('PRAGMA foreign_keys = ON');
      await DatabaseSchema.createIndexes(_db);

      return backupFile.path;
    } catch (e) {
      // محاولة إعادة فتح قاعدة البيانات في حالة الخطأ
      try {
        _db = await openDatabase(_dbPath, version: _dbVersion);
        await _db.execute('PRAGMA foreign_keys = ON');
        await DatabaseSchema.createIndexes(_db);
      } catch (_) {}
      rethrow;
    }
  }

  /// الحصول على المساحة المتاحة في القرص
  Future<int> _getAvailableDiskSpace(String path) async {
    try {
      // هذا تنفيذ مبسط - في التطبيقات الحقيقية قد تحتاج مكتبة خارجية
      final directory = Directory(path);
      if (await directory.exists()) {
        return 1024 * 1024 * 1024; // 1GB افتراضي
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// استعادة نسخة احتياطية كاملة محسنة
  Future<void> restoreFullBackup(String backupFilePath) async {
    try {
      final backupFile = File(backupFilePath);
      if (!await backupFile.exists()) {
        throw Exception('ملف النسخة الاحتياطية غير موجود');
      }

      // التحقق من صحة ملف النسخة الاحتياطية والحصول على إصداره
      int backupVersion = 1;
      final testDb = await openDatabase(backupFilePath, readOnly: true);
      try {
        await testDb.rawQuery('SELECT COUNT(*) FROM sqlite_master');
        // التحقق من وجود الجداول الأساسية
        final tables = await testDb.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'");
        if (tables.isEmpty) {
          throw Exception('ملف النسخة الاحتياطية لا يحتوي على جداول صالحة');
        }
        // الحصول على إصدار قاعدة البيانات من النسخة الاحتياطية
        final versionResult = await testDb.rawQuery('PRAGMA user_version');
        backupVersion = (versionResult.first['user_version'] as int?) ?? 1;
        debugPrint('إصدار النسخة الاحتياطية: $backupVersion');
      } finally {
        await testDb.close();
      }

      // إنشاء نسخة احتياطية من البيانات الحالية قبل الاستعادة
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final currentBackupPath = '${_dbPath}_pre_restore_$timestamp.db';

      // إغلاق قاعدة البيانات الحالية وإجراء تنظيف
      try {
        await _db.execute('PRAGMA wal_checkpoint(FULL)');
      } catch (e) {
        debugPrint('تحذير: فشل في تحسين قاعدة البيانات قبل الاستعادة: $e');
      }

      try {
        await _db.close();
      } catch (e) {
        debugPrint('تحذير: قاعدة البيانات قد تكون مغلقة بالفعل: $e');
      }

      // نسخ البيانات الحالية كنسخة احتياطية احتياطية
      await File(_dbPath).copy(currentBackupPath);

      // نسخ ملفات WAL و SHM الحالية إذا كانت موجودة
      final currentWalFile = File('$_dbPath-wal');
      if (await currentWalFile.exists()) {
        await currentWalFile.copy('$currentBackupPath-wal');
      }

      final currentShmFile = File('$_dbPath-shm');
      if (await currentShmFile.exists()) {
        await currentShmFile.copy('$currentBackupPath-shm');
      }

      try {
        // استعادة النسخة الاحتياطية الرئيسية
        await backupFile.copy(_dbPath);

        // استعادة ملف WAL إذا كان موجوداً
        final backupWalFile = File('$backupFilePath-wal');
        if (await backupWalFile.exists()) {
          final walFile = File('$_dbPath-wal');
          await backupWalFile.copy(walFile.path);
        }

        // استعادة ملف SHM إذا كان موجوداً
        final backupShmFile = File('$backupFilePath-shm');
        if (await backupShmFile.exists()) {
          final shmFile = File('$_dbPath-shm');
          await backupShmFile.copy(shmFile.path);
        }

        // إعادة فتح قاعدة البيانات والتحقق من صحتها
        // نفتح قاعدة البيانات بدون تحديد الإصدار لتجنب استدعاء onUpgrade تلقائياً
        // ثم نتحكم في migrations يدوياً
        _db = await openDatabase(_dbPath);
        await _db.execute('PRAGMA foreign_keys = ON');

        // التحقق من صحة البيانات المستعادة
        final integrityResult = await _db.rawQuery('PRAGMA integrity_check');
        final integrityCheck =
            integrityResult.first['integrity_check'] as String?;
        if (integrityCheck != 'ok') {
          throw Exception(
              'فشل التحقق من سلامة قاعدة البيانات: $integrityCheck');
        }

        // الحصول على الإصدار الحالي للنسخة المستعادة
        final currentVersionResult = await _db.rawQuery('PRAGMA user_version');
        final currentVersion =
            (currentVersionResult.first['user_version'] as int?) ??
                backupVersion;
        debugPrint(
            'إصدار النسخة المستعادة: $currentVersion، الإصدار المطلوب: $_dbVersion');

        // تشغيل جميع الـ migrations المطلوبة فقط إذا كان الإصدار الحالي أقل من المطلوب
        if (currentVersion < _dbVersion) {
          debugPrint(
              'بدء تشغيل الـ migrations بعد الاستعادة من الإصدار $currentVersion إلى $_dbVersion...');
          await DatabaseMigrations.runMigrations(
              _db, currentVersion, _dbVersion);

          // تحديث إصدار قاعدة البيانات
          await _db.execute('PRAGMA user_version = $_dbVersion');
          debugPrint('تم تحديث إصدار قاعدة البيانات إلى $_dbVersion');
        } else {
          debugPrint(
              'قاعدة البيانات في الإصدار المطلوب، لا حاجة لتشغيل migrations');
        }

        // إعادة بناء الفهارس والتنظيف بعد الـ migrations
        await DatabaseSchema.createIndexes(_db);

        // التأكد من وجود جميع الجداول المهمة (returns, event_log, deleted_items, إلخ)
        await _ensureReturnsTable(_db);
        await _ensureReturnsTableColumns(_db);
        await _ensureReturnsStatusColumn(_db);
        await _ensureEventLogTable(_db);
        await _ensureDeletedItemsTable(_db);
        await _ensureExpensesTableColumns(_db);
        await _ensureDiscountTables(_db);

        // تحسين قاعدة البيانات بعد الاستعادة
        await _db.execute('PRAGMA optimize');

        // التحقق من وجود البيانات المستعادة
        final customersCount =
            await _db.rawQuery('SELECT COUNT(*) as count FROM customers');
        final salesCount =
            await _db.rawQuery('SELECT COUNT(*) as count FROM sales');
        final productsCount =
            await _db.rawQuery('SELECT COUNT(*) as count FROM products');
        debugPrint(
            'البيانات المستعادة - العملاء: ${customersCount.first['count']}, المبيعات: ${salesCount.first['count']}, المنتجات: ${productsCount.first['count']}');

        // إعادة فتح قاعدة البيانات بشكل صحيح مع الإصدار و callbacks لضمان التهيئة الصحيحة
        try {
          await _db.close();
        } catch (e) {
          debugPrint('تحذير: قاعدة البيانات قد تكون مغلقة بالفعل: $e');
        }
        _db = await openDatabase(
          _dbPath,
          version: _dbVersion,
          onOpen: (db) async {
            // التحقق من وجود الجداول المهمة عند فتح قاعدة البيانات
            await _ensureEventLogTable(db);
            await _ensureReturnsTable(db);
            await _ensureReturnsTableColumns(db);
            await _ensureReturnsStatusColumn(db);
            await _ensureDeletedItemsTable(db);
            await _ensureExpensesTableColumns(db);
            await _ensureDiscountTables(db);
          },
        );
        await _db.execute('PRAGMA foreign_keys = ON');
        await DatabaseSchema.createIndexes(_db);

        // التحقق مرة أخرى من البيانات بعد إعادة الفتح
        final finalCustomersCount =
            await _db.rawQuery('SELECT COUNT(*) as count FROM customers');
        final finalSalesCount =
            await _db.rawQuery('SELECT COUNT(*) as count FROM sales');
        final finalProductsCount =
            await _db.rawQuery('SELECT COUNT(*) as count FROM products');
        debugPrint(
            'البيانات بعد إعادة الفتح - العملاء: ${finalCustomersCount.first['count']}, المبيعات: ${finalSalesCount.first['count']}, المنتجات: ${finalProductsCount.first['count']}');
      } catch (restoreError) {
        // في حالة فشل الاستعادة، استعادة البيانات الأصلية
        try {
          await _db.close();
          await File(currentBackupPath).copy(_dbPath);

          // استعادة ملفات WAL و SHM الأصلية
          final backupWalFile = File('$currentBackupPath-wal');
          if (await backupWalFile.exists()) {
            await backupWalFile.copy('$_dbPath-wal');
          }

          final backupShmFile = File('$currentBackupPath-shm');
          if (await backupShmFile.exists()) {
            await backupShmFile.copy('$_dbPath-shm');
          }

          _db = await openDatabase(_dbPath, version: _dbVersion);
          await _db.execute('PRAGMA foreign_keys = ON');
          await DatabaseSchema.createIndexes(_db);
        } catch (_) {}

        // حذف النسخة الاحتياطية المؤقتة وجميع ملفاتها
        try {
          final currentBackupFile = File(currentBackupPath);
          if (await currentBackupFile.exists()) {
            await currentBackupFile.delete();
          }

          final currentBackupWalFile = File('$currentBackupPath-wal');
          if (await currentBackupWalFile.exists()) {
            await currentBackupWalFile.delete();
          }

          final currentBackupShmFile = File('$currentBackupPath-shm');
          if (await currentBackupShmFile.exists()) {
            await currentBackupShmFile.delete();
          }
        } catch (_) {}

        throw Exception(
            'فشل في استعادة النسخة الاحتياطية: ${restoreError.toString()}');
      }

      // حذف النسخة الاحتياطية المؤقتة وجميع ملفاتها بعد نجاح الاستعادة
      try {
        final currentBackupFile = File(currentBackupPath);
        if (await currentBackupFile.exists()) {
          await currentBackupFile.delete();
        }

        final currentBackupWalFile = File('$currentBackupPath-wal');
        if (await currentBackupWalFile.exists()) {
          await currentBackupWalFile.delete();
        }

        final currentBackupShmFile = File('$currentBackupPath-shm');
        if (await currentBackupShmFile.exists()) {
          await currentBackupShmFile.delete();
        }
      } catch (_) {}
    } catch (e) {
      // محاولة إعادة فتح قاعدة البيانات في حالة الخطأ
      try {
        _db = await openDatabase(_dbPath, version: _dbVersion);
        await _db.execute('PRAGMA foreign_keys = ON');
        await DatabaseSchema.createIndexes(_db);
      } catch (_) {}
      rethrow;
    }
  }

  /// الحصول على حجم قاعدة البيانات
  Future<String> getDatabaseSize() async {
    try {
      final file = File(_dbPath);
      if (await file.exists()) {
        final size = await file.length();
        if (size < 1024) {
          return '$size B';
        } else if (size < 1024 * 1024) {
          return '${(size / 1024).toStringAsFixed(1)} KB';
        } else {
          return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
        }
      }
      return 'غير متاح';
    } catch (e) {
      return 'خطأ في الحساب';
    }
  }

  /// الحصول على إحصائيات قاعدة البيانات
  /// تنظيف النسخ الاحتياطية القديمة (الاحتفاظ بآخر 10 نسخ فقط)
  Future<void> _cleanupOldBackups(String backupPath) async {
    try {
      final backupDir = Directory(backupPath);
      if (!await backupDir.exists()) return;

      final backupFiles = await backupDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.db'))
          .cast<File>()
          .toList();

      // ترتيب الملفات حسب تاريخ التعديل (الأحدث أولاً)
      backupFiles
          .sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // حذف الملفات الزائدة (الاحتفاظ بآخر 10 نسخ فقط)
      if (backupFiles.length > 10) {
        for (int i = 10; i < backupFiles.length; i++) {
          try {
            await backupFiles[i].delete();
          } catch (e) {
            // تجاهل الأخطاء في الحذف
          }
        }
      }
    } catch (e) {
      // تجاهل الأخطاء في التنظيف
    }
  }

  /// التحقق من سلامة النسخة الاحتياطية
  Future<bool> verifyBackup(String backupFilePath) async {
    try {
      final backupFile = File(backupFilePath);
      if (!await backupFile.exists()) return false;

      // فتح قاعدة البيانات للتحقق
      final testDb = await openDatabase(backupFilePath, readOnly: true);
      try {
        // التحقق من وجود الجداول الأساسية
        final tables = await testDb
            .rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
        final tableNames = tables.map((t) => t['name'] as String).toList();

        // الجداول الأساسية المطلوبة (يجب أن تكون موجودة)
        final requiredTables = [
          'users',
          'products',
          'categories',
          'customers',
          'sales',
          'sale_items',
          'installments',
          'payments',
          'expenses',
          'suppliers',
          'settings',
        ];

        // التحقق من وجود جميع الجداول الأساسية
        for (final table in requiredTables) {
          if (!tableNames.contains(table)) {
            debugPrint('النسخة الاحتياطية لا تحتوي على الجدول المطلوب: $table');
            return false;
          }
        }

        // التحقق من سلامة البيانات
        final integrityResult = await testDb.rawQuery('PRAGMA integrity_check');
        final integrityCheck =
            integrityResult.first['integrity_check'] as String?;
        if (integrityCheck != 'ok') {
          debugPrint('فشل التحقق من سلامة النسخة الاحتياطية: $integrityCheck');
          return false;
        }

        return true;
      } finally {
        await testDb.close();
      }
    } catch (e) {
      debugPrint('خطأ في التحقق من النسخة الاحتياطية: $e');
      return false;
    }
  }

  /// الحصول على قائمة النسخ الاحتياطية المتاحة
  Future<List<Map<String, dynamic>>> getAvailableBackups(
      String backupPath) async {
    try {
      final backupDir = Directory(backupPath);
      if (!await backupDir.exists()) {
        debugPrint('مجلد النسخ الاحتياطية غير موجود: $backupPath');
        return [];
      }

      // الحصول على جميع الملفات من المجلد
      final entities = await backupDir.list().toList();
      debugPrint('عدد الملفات في المجلد: ${entities.length}');

      // فلترة الملفات التي تنتهي بـ .db
      final backupFiles = <File>[];
      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.db')) {
          backupFiles.add(entity);
        }
      }

      debugPrint('عدد ملفات النسخ الاحتياطية: ${backupFiles.length}');

      final backups = <Map<String, dynamic>>[];
      for (final file in backupFiles) {
        try {
          final stat = await file.stat();
          final size = await file.length();
          final isValid = await verifyBackup(file.path);

          backups.add({
            'path': file.path,
            'name': p.basename(file.path),
            'size': size,
            'date': stat.modified,
            'isValid': isValid,
          });
        } catch (e) {
          debugPrint('خطأ في معالجة ملف النسخة الاحتياطية ${file.path}: $e');
          // نتابع مع الملفات الأخرى حتى لو فشل أحدها
        }
      }

      // ترتيب حسب التاريخ (الأحدث أولاً)
      backups.sort(
          (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      debugPrint('عدد النسخ الاحتياطية المعروضة: ${backups.length}');
      return backups;
    } catch (e) {
      debugPrint('خطأ في الحصول على قائمة النسخ الاحتياطية: $e');
      return [];
    }
  }

  /// تشغيل النسخ الاحتياطي التلقائي
  Future<void> runAutoBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final autoBackupEnabled = prefs.getBool('auto_backup_enabled') ?? false;
      final autoBackupFrequency =
          prefs.getString('auto_backup_frequency') ?? 'weekly';
      final backupPath = prefs.getString('backup_path') ?? '';

      if (!autoBackupEnabled || backupPath.isEmpty) return;

      // التحقق من موعد آخر نسخة احتياطية
      final lastBackupTime = prefs.getInt('last_auto_backup_time') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final timeSinceLastBackup = now - lastBackupTime;

      bool shouldBackup = false;
      switch (autoBackupFrequency) {
        case 'daily':
          shouldBackup = timeSinceLastBackup >= 24 * 60 * 60 * 1000; // 24 ساعة
          break;
        case 'weekly':
          shouldBackup =
              timeSinceLastBackup >= 7 * 24 * 60 * 60 * 1000; // 7 أيام
          break;
        case 'monthly':
          shouldBackup =
              timeSinceLastBackup >= 30 * 24 * 60 * 60 * 1000; // 30 يوم
          break;
      }

      if (shouldBackup) {
        await createFullBackup(backupPath);
        await prefs.setInt('last_auto_backup_time', now);
      }
    } catch (e) {
      // تسجيل الخطأ (يمكن إضافة نظام logging لاحقاً)
    }
  }

  Future<Map<String, int>> getDatabaseStats() async {
    try {
      final stats = <String, int>{};

      // عدد المنتجات
      final productsResult =
          await _db.rawQuery('SELECT COUNT(*) as count FROM products');
      final productsCount = productsResult.first['count'] as int? ?? 0;
      stats['products'] = productsCount;

      // عدد العملاء
      final customersResult =
          await _db.rawQuery('SELECT COUNT(*) as count FROM customers');
      final customersCount = customersResult.first['count'] as int? ?? 0;
      stats['customers'] = customersCount;

      // عدد المبيعات
      final salesResult =
          await _db.rawQuery('SELECT COUNT(*) as count FROM sales');
      final salesCount = salesResult.first['count'] as int? ?? 0;
      stats['sales'] = salesCount;

      // عدد الأقسام
      final categoriesResult =
          await _db.rawQuery('SELECT COUNT(*) as count FROM categories');
      final categoriesCount = categoriesResult.first['count'] as int? ?? 0;
      stats['categories'] = categoriesCount;

      return stats;
    } catch (e) {
      return {};
    }
  }

  // ==================== التقارير المالية الشاملة ====================

  /// قائمة الدخل الشهرية
  Future<Map<String, dynamic>> getIncomeStatement(DateTime month) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      // الإيرادات
      final revenueResult = await _db.rawQuery('''
        SELECT 
          COALESCE(SUM(total), 0) as total_revenue,
          COALESCE(SUM(profit), 0) as gross_profit
        FROM sales 
        WHERE created_at >= ? AND created_at <= ?
      ''', [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()]);

      // تكلفة البضائع المباعة
      final cogsResult = await _db.rawQuery('''
        SELECT COALESCE(SUM(si.cost * si.quantity), 0) as cogs
        FROM sale_items si
        JOIN sales s ON si.sale_id = s.id
        WHERE s.created_at >= ? AND s.created_at <= ?
      ''', [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()]);

      // المصروفات
      final expensesResult = await _db.rawQuery('''
        SELECT COALESCE(SUM(amount), 0) as total_expenses
        FROM expenses 
        WHERE created_at >= ? AND created_at <= ?
      ''', [startOfMonth.toIso8601String(), endOfMonth.toIso8601String()]);

      final expenses =
          (expensesResult.first['total_expenses'] as num?)?.toDouble() ?? 0.0;

      final revenue =
          (revenueResult.first['total_revenue'] as num?)?.toDouble() ?? 0.0;
      final grossProfit =
          (revenueResult.first['gross_profit'] as num?)?.toDouble() ?? 0.0;
      final cogs = (cogsResult.first['cogs'] as num?)?.toDouble() ?? 0.0;
      final netProfit = grossProfit - expenses;

      return {
        'revenue': revenue,
        'cogs': cogs,
        'gross_profit': grossProfit,
        'expenses': expenses,
        'net_profit': netProfit,
        'month': month.month,
        'year': month.year,
      };
    } catch (e) {
      return {};
    }
  }

  /// الميزانية العمومية
  Future<Map<String, dynamic>> getBalanceSheet(DateTime date) async {
    try {
      // الأصول
      final assetsResult = await _db.rawQuery('''
        SELECT COALESCE(SUM(price * quantity), 0) as inventory_value
        FROM products
      ''');

      // الخصوم (الديون المستحقة)
      final liabilitiesResult = await _db.rawQuery('''
        SELECT COALESCE(SUM(amount - paid), 0) as total_debts
        FROM installments
        WHERE paid < amount
      ''');

      // حقوق الملكية (الأرباح المحتجزة)
      final equityResult = await _db.rawQuery('''
        SELECT COALESCE(SUM(profit), 0) as retained_earnings
        FROM sales
        WHERE created_at <= ?
      ''', [date.toIso8601String()]);

      final assets =
          (assetsResult.first['inventory_value'] as num?)?.toDouble() ?? 0.0;
      final liabilities =
          (liabilitiesResult.first['total_debts'] as num?)?.toDouble() ?? 0.0;
      final equity =
          (equityResult.first['retained_earnings'] as num?)?.toDouble() ?? 0.0;

      return {
        'assets': assets,
        'liabilities': liabilities,
        'equity': equity,
        'date': date.toIso8601String(),
      };
    } catch (e) {
      return {};
    }
  }

  /// تحليل الاتجاهات والتنبؤات
  Future<Map<String, dynamic>> getTrendAnalysis(int months) async {
    try {
      final endDate = DateTime.now();
      final startDate = DateTime(endDate.year, endDate.month - months, 1);

      // بيانات المبيعات الشهرية
      final monthlySales = await _db.rawQuery('''
        SELECT 
          strftime('%Y-%m', created_at) as month,
          COUNT(*) as sales_count,
          SUM(total) as total_revenue,
          SUM(profit) as total_profit,
          AVG(total) as avg_sale_amount
        FROM sales
        WHERE created_at >= ? AND created_at <= ?
        GROUP BY strftime('%Y-%m', created_at)
        ORDER BY month
      ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

      // حساب معدل النمو
      List<double> revenues = [];
      for (final row in monthlySales) {
        revenues.add((row['total_revenue'] as num?)?.toDouble() ?? 0.0);
      }

      double growthRate = 0.0;
      if (revenues.length >= 2) {
        final currentRevenue = revenues.last;
        final previousRevenue = revenues[revenues.length - 2];
        if (previousRevenue > 0) {
          growthRate =
              ((currentRevenue - previousRevenue) / previousRevenue) * 100;
        }
      }

      // التنبؤ بالشهر القادم
      double predictedRevenue = 0.0;
      if (revenues.isNotEmpty) {
        final avgRevenue = revenues.reduce((a, b) => a + b) / revenues.length;
        predictedRevenue = avgRevenue * (1 + (growthRate / 100));
      }

      return {
        'monthly_data': monthlySales,
        'growth_rate': growthRate,
        'predicted_revenue': predictedRevenue,
        'trend_direction': growthRate > 0
            ? 'up'
            : growthRate < 0
                ? 'down'
                : 'stable',
      };
    } catch (e) {
      return {};
    }
  }

  /// مؤشرات الأداء الرئيسية (KPI)
  Future<Map<String, dynamic>> getKPIs(DateTime date) async {
    try {
      final startOfMonth = DateTime(date.year, date.month, 1);
      // Use half-open [start, nextMonthStart) to be consistent
      final nextMonthStart = DateTime(date.year, date.month + 1, 1);

      // إجمالي المبيعات الشهرية
      final monthlySalesResult = await _db.rawQuery('''
        SELECT 
          COUNT(*) as sales_count,
          SUM(total) as total_revenue,
          SUM(profit) as total_profit,
          AVG(total) as avg_sale_amount
        FROM sales
        WHERE created_at >= ? AND created_at < ?
      ''', [startOfMonth.toIso8601String(), nextMonthStart.toIso8601String()]);

      // عدد العملاء الجدد
      int newCustomersCount = 0;
      try {
        final newCustomersResult = await _db.rawQuery('''
          SELECT COUNT(*) as new_customers
          FROM customers
          WHERE created_at >= ? AND created_at < ?
        ''',
            [startOfMonth.toIso8601String(), nextMonthStart.toIso8601String()]);
        newCustomersCount =
            (newCustomersResult.first['new_customers'] as num?)?.toInt() ?? 0;
      } catch (_) {
        // Fallback if customers.created_at doesn't exist: distinct customers from sales this month
        final fallback = await _db.rawQuery('''
          SELECT COUNT(DISTINCT customer_id) as cnt
          FROM sales
          WHERE customer_id IS NOT NULL AND created_at >= ? AND created_at < ?
        ''',
            [startOfMonth.toIso8601String(), nextMonthStart.toIso8601String()]);
        newCustomersCount = (fallback.first['cnt'] as num?)?.toInt() ?? 0;
      }

      // معدل التحويل (العملاء الذين اشتروا)
      final totalCustomersResult = await _db.rawQuery('''
        SELECT COUNT(*) as total_customers
        FROM customers
      ''');

      final customersWithSalesResult = await _db.rawQuery('''
        SELECT COUNT(DISTINCT customer_id) as customers_with_sales
        FROM sales
        WHERE created_at >= ? AND created_at < ? AND customer_id IS NOT NULL
      ''', [startOfMonth.toIso8601String(), nextMonthStart.toIso8601String()]);

      // هامش الربح
      final totalRevenue =
          (monthlySalesResult.first['total_revenue'] as num?)?.toDouble() ??
              0.0;
      final totalProfit =
          (monthlySalesResult.first['total_profit'] as num?)?.toDouble() ?? 0.0;
      final profitMargin =
          totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0.0;

      // معدل التحويل
      final totalCustomers =
          totalCustomersResult.first['total_customers'] as int? ?? 0;
      final customersWithSales =
          customersWithSalesResult.first['customers_with_sales'] as int? ?? 0;
      final conversionRate = totalCustomers > 0
          ? (customersWithSales / totalCustomers) * 100
          : 0.0;

      return {
        'monthly_revenue': totalRevenue,
        'monthly_profit': totalProfit,
        'sales_count': monthlySalesResult.first['sales_count'] as int? ?? 0,
        'avg_sale_amount':
            (monthlySalesResult.first['avg_sale_amount'] as num?)?.toDouble() ??
                0.0,
        'new_customers': newCustomersCount,
        'profit_margin': profitMargin,
        'conversion_rate': conversionRate,
        'month': date.month,
        'year': date.year,
      };
    } catch (e) {
      return {};
    }
  }

  /// تقرير الضرائب
  Future<Map<String, dynamic>> getTaxReport(
      DateTime startDate, DateTime endDate) async {
    try {
      // المبيعات الخاضعة للضريبة
      final taxableSalesResult = await _db.rawQuery('''
        SELECT 
          COUNT(*) as sales_count,
          SUM(total) as total_amount,
          SUM(profit) as total_profit
        FROM sales
        WHERE created_at >= ? AND created_at <= ?
      ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

      // تفاصيل المبيعات للفاتورة الضريبية
      final salesDetails = await _db.rawQuery('''
        SELECT 
          s.id,
          s.created_at,
          s.total,
          s.profit,
          s.type,
          c.name as customer_name,
          c.phone as customer_phone
        FROM sales s
        LEFT JOIN customers c ON s.customer_id = c.id
        WHERE s.created_at >= ? AND s.created_at <= ?
        ORDER BY s.created_at DESC
      ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

      final totalAmount =
          (taxableSalesResult.first['total_amount'] as num?)?.toDouble() ?? 0.0;
      final totalProfit =
          (taxableSalesResult.first['total_profit'] as num?)?.toDouble() ?? 0.0;

      // لا توجد ضرائب - المبلغ الصافي = إجمالي المبيعات
      const taxRate = 0.0;
      final taxAmount = 0.0;
      final netAmount = totalAmount;

      return {
        'period_start': startDate.toIso8601String(),
        'period_end': endDate.toIso8601String(),
        'total_sales': totalAmount,
        'total_profit': totalProfit,
        'tax_rate': taxRate * 100,
        'tax_amount': taxAmount,
        'net_amount': netAmount,
        'sales_count': taxableSalesResult.first['sales_count'] as int? ?? 0,
        'sales_details': salesDetails,
      };
    } catch (e) {
      return {};
    }
  }

  /// تقرير الجرد الشامل
  Future<Map<String, dynamic>> getInventoryReport() async {
    try {
      // إجمالي المخزون
      final totalInventoryResult = await _db.rawQuery('''
        SELECT 
          COUNT(*) as total_products,
          SUM(quantity) as total_quantity,
          SUM(price * quantity) as total_value,
          SUM(cost * quantity) as total_cost
        FROM products
      ''');

      // المنتجات منخفضة الكمية
      final lowStockResult = await _db.rawQuery('''
        SELECT COUNT(*) as low_stock_count
        FROM products
        WHERE quantity <= 10
      ''');

      // المنتجات نفدت
      final outOfStockResult = await _db.rawQuery('''
        SELECT COUNT(*) as out_of_stock_count
        FROM products
        WHERE quantity = 0
      ''');

      // المنتجات الأكثر مبيعاً
      final topSellingResult = await _db.rawQuery('''
        SELECT 
          p.name,
          p.barcode,
          SUM(si.quantity) as total_sold,
          SUM(si.price * si.quantity) as total_revenue
        FROM products p
        JOIN sale_items si ON p.id = si.product_id
        JOIN sales s ON si.sale_id = s.id
        WHERE s.created_at >= date('now', '-30 days')
        GROUP BY p.id, p.name, p.barcode
        ORDER BY total_sold DESC
        LIMIT 10
      ''');

      // المنتجات بطيئة الحركة
      final slowMovingResult = await _db.rawQuery('''
        SELECT 
          p.name,
          p.barcode,
          p.quantity,
          p.price,
          p.cost
        FROM products p
        LEFT JOIN sale_items si ON p.id = si.product_id
        LEFT JOIN sales s ON si.sale_id = s.id AND s.created_at >= date('now', '-90 days')
        GROUP BY p.id, p.name, p.barcode, p.quantity, p.price, p.cost
        HAVING COUNT(si.id) = 0 OR COUNT(si.id) < 3
        ORDER BY p.quantity DESC
        LIMIT 10
      ''');

      final totalValue =
          totalInventoryResult.first['total_value'] as double? ?? 0.0;
      final totalCost =
          totalInventoryResult.first['total_cost'] as double? ?? 0.0;
      final inventoryTurnover = totalCost > 0 ? (totalValue / totalCost) : 0.0;
      final profitMargin =
          totalValue > 0 ? ((totalValue - totalCost) / totalValue) * 100 : 0.0;

      return {
        'total_products':
            totalInventoryResult.first['total_products'] as int? ?? 0,
        'total_quantity':
            totalInventoryResult.first['total_quantity'] as int? ?? 0,
        'total_value': totalValue,
        'total_cost': totalCost,
        'inventory_turnover': inventoryTurnover,
        'profit_margin': profitMargin,
        'low_stock_count': lowStockResult.first['low_stock_count'] as int? ?? 0,
        'out_of_stock_count':
            outOfStockResult.first['out_of_stock_count'] as int? ?? 0,
        'top_selling_products': topSellingResult,
        'slow_moving_products': slowMovingResult,
        'report_date': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {};
    }
  }

  /// حذف جميع البيانات عدا المستخدمين (دون إعادة إنشاء البيانات الأساسية)
  /// تستخدم عند الاستعادة للحفاظ على المستخدمين من النسخة المستعادة
  Future<void> _deleteAllDataExceptUsers() async {
    try {
      // تعطيل المفاتيح الخارجية خارج transaction
      await _db.execute('PRAGMA foreign_keys = OFF');

      // نفّذ الحذف داخل معاملة واحدة مع السماح بتحديث الواجهة
      await _db.transaction((txn) async {
        // حذف الجداول بالترتيب الصحيح لتجنب مشاكل المفاتيح الخارجية
        // أولاً: حذف الجداول الفرعية
        try {
          await txn.execute('DELETE FROM installments');
        } catch (e) {
          debugPrint('خطأ في حذف installments: $e');
        }

        try {
          await txn.execute('DELETE FROM sale_items');
        } catch (e) {
          debugPrint('خطأ في حذف sale_items: $e');
        }

        try {
          await txn.execute('DELETE FROM payments');
        } catch (e) {
          debugPrint('خطأ في حذف payments: $e');
        }

        try {
          await txn.execute('DELETE FROM expenses');
        } catch (e) {
          debugPrint('خطأ في حذف expenses: $e');
        }

        try {
          await txn.execute('DELETE FROM returns');
        } catch (e) {
          debugPrint('خطأ في حذف returns: $e');
        }

        // ثانياً: حذف الجداول الرئيسية
        try {
          await txn.execute('DELETE FROM sales');
        } catch (e) {
          debugPrint('خطأ في حذف sales: $e');
        }

        try {
          await txn.execute('DELETE FROM products');
        } catch (e) {
          debugPrint('خطأ في حذف products: $e');
        }

        try {
          await txn.execute('DELETE FROM categories');
        } catch (e) {
          debugPrint('خطأ في حذف categories: $e');
        }

        try {
          await txn.execute('DELETE FROM customers');
        } catch (e) {
          debugPrint('خطأ في حذف customers: $e');
        }

        try {
          await txn.execute('DELETE FROM suppliers');
        } catch (e) {
          debugPrint('خطأ في حذف suppliers: $e');
        }

        // ثالثاً: حذف سلة المحذوفات
        try {
          await txn.execute('DELETE FROM deleted_items');
        } catch (e) {
          debugPrint('خطأ في حذف deleted_items: $e');
        }

        // رابعاً: حذف الكوبونات
        try {
          await txn.execute('DELETE FROM discount_coupons');
        } catch (e) {
          debugPrint('خطأ في حذف discount_coupons: $e');
        }

        // خامساً: حذف الخصومات
        try {
          await txn.execute('DELETE FROM product_discounts');
        } catch (e) {
          debugPrint('خطأ في حذف product_discounts: $e');
        }

        // سادساً: حذف سجل الأحداث
        try {
          await txn.execute('DELETE FROM event_log');
        } catch (e) {
          debugPrint('خطأ في حذف event_log: $e');
        }

        // سابعاً: حذف المجموعات والصلاحيات
        try {
          await txn.execute('DELETE FROM group_permissions');
        } catch (e) {
          debugPrint('خطأ في حذف group_permissions: $e');
        }

        try {
          await txn.execute('DELETE FROM groups');
        } catch (e) {
          debugPrint('خطأ في حذف groups: $e');
        }

        // إزالة ارتباط المستخدمين بالمجموعات (وضع group_id إلى NULL)
        try {
          await txn.execute('UPDATE users SET group_id = NULL');
        } catch (e) {
          debugPrint('خطأ في إزالة ارتباط المستخدمين بالمجموعات: $e');
        }

        // ملاحظة: لا نحذف المستخدمين - يتم الاحتفاظ بجميع المستخدمين

        // إعادة تعيين AUTO_INCREMENT
        try {
          await txn.execute('DELETE FROM sqlite_sequence');
        } catch (e) {
          debugPrint('خطأ في حذف sqlite_sequence: $e');
        }
      });

      // السماح للواجهة بالتحديث قبل إعادة تفعيل المفاتيح الخارجية
      await Future.delayed(const Duration(milliseconds: 10));

      // إعادة تفعيل المفاتيح الخارجية
      await _db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      // إعادة تفعيل المفاتيح الخارجية في حالة الخطأ
      try {
        await _db.execute('PRAGMA foreign_keys = ON');
      } catch (_) {}

      debugPrint('خطأ في حذف جميع البيانات عدا المستخدمين: $e');
      throw Exception('خطأ في حذف جميع البيانات عدا المستخدمين: $e');
    }
  }

  // تم الإبقاء على الدالة القديمة `deleteAllDataNew` في الإصدارات السابقة.
  // الدالة الجديدة الكاملة توجد في الأسفل باسم deleteAllDataHardReset().

  /// حذف المنتجات والأقسام فقط
  Future<void> deleteProductsAndCategories() async {
    try {
      // تعطيل المفاتيح الخارجية خارج transaction
      await _db.execute('PRAGMA foreign_keys = OFF');

      // نفّذ الحذف داخل معاملة واحدة
      await _db.transaction((txn) async {
        // حذف sale_items أولاً (لأنها مرتبطة بالمنتجات)
        try {
          await txn.execute('DELETE FROM sale_items');
          debugPrint('تم حذف sale_items بنجاح');
        } catch (e) {
          debugPrint('خطأ في حذف sale_items: $e');
          // نتابع حتى لو فشل حذف sale_items
        }

        // حذف المنتجات
        try {
          await txn.execute('DELETE FROM products');
          debugPrint('تم حذف products بنجاح');
        } catch (e) {
          debugPrint('خطأ في حذف products: $e');
          rethrow; // نرمي الخطأ هنا لأن حذف المنتجات مهم
        }

        // حذف الأقسام
        try {
          await txn.execute('DELETE FROM categories');
          debugPrint('تم حذف categories بنجاح');
        } catch (e) {
          debugPrint('خطأ في حذف categories: $e');
          // نتابع حتى لو فشل حذف categories
        }

        // إعادة تعيين AUTO_INCREMENT للمنتجات والأقسام
        try {
          await txn.execute(
              'DELETE FROM sqlite_sequence WHERE name IN ("products", "categories", "sale_items")');
          debugPrint('تم إعادة تعيين sqlite_sequence بنجاح');
        } catch (e) {
          debugPrint('خطأ في إعادة تعيين sqlite_sequence: $e');
          // لا نرمي الخطأ هنا لأن هذا ليس حرجاً
        }
      });

      // إعادة تفعيل المفاتيح الخارجية
      await _db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      // التأكد من إعادة تفعيل المفاتيح الخارجية حتى في حالة الخطأ
      try {
        await _db.execute('PRAGMA foreign_keys = ON');
      } catch (_) {}
      debugPrint('خطأ في حذف المنتجات والأقسام: $e');
      throw Exception('خطأ في حذف المنتجات والأقسام: $e');
    }
  }

  /// حذف الإحصائيات والتقارير
  Future<void> deleteReportsAndStatistics() async {
    try {
      await _db.transaction((txn) async {
        // حذف سجلات الأداء إذا كانت موجودة
        try {
          await txn.execute('DELETE FROM performance_logs');
        } catch (e) {
          // الجدول قد لا يكون موجوداً
        }

        // حذف التقارير المؤقتة إذا كانت موجودة
        try {
          await txn.execute('DELETE FROM temp_reports');
        } catch (e) {
          // الجدول قد لا يكون موجوداً
        }

        // حذف سجلات النسخ الاحتياطي إذا كانت موجودة
        try {
          await txn.execute('DELETE FROM backup_logs');
        } catch (e) {
          // الجدول قد لا يكون موجوداً
        }

        // حذف البيانات الإحصائية من الجداول الموجودة
        // حذف سجلات المدفوعات (إحصائيات مالية)
        await txn.delete('payments');

        // حذف سجلات المصروفات (إحصائيات مالية)
        await txn.delete('expenses');

        // حذف الأقساط (إحصائيات مالية)
        await txn.delete('installments');

        // إعادة تعيين AUTO_INCREMENT للجداول المحذوفة
        await txn.execute(
            'DELETE FROM sqlite_sequence WHERE name IN ("payments", "expenses", "installments")');

        // تنظيف أي جداول مؤقتة أخرى
        await txn
            .execute('DELETE FROM sqlite_sequence WHERE name LIKE "%temp%"');
        await txn
            .execute('DELETE FROM sqlite_sequence WHERE name LIKE "%log%"');
        await txn
            .execute('DELETE FROM sqlite_sequence WHERE name LIKE "%report%"');
      });
    } catch (e) {
      throw Exception('خطأ في حذف الإحصائيات والتقارير: $e');
    }
  }

  /// حذف المبيعات فقط
  Future<void> deleteSalesOnly() async {
    try {
      // تعطيل المفاتيح الخارجية خارج transaction
      await _db.execute('PRAGMA foreign_keys = OFF');

      // نفّذ الحذف داخل معاملة واحدة
      await _db.transaction((txn) async {
        // حذف الأقساط أولاً (لأنها مرتبطة بالمبيعات)
        try {
          await txn.execute('DELETE FROM installments');
          debugPrint('تم حذف installments بنجاح');
        } catch (e) {
          debugPrint('خطأ في حذف installments: $e');
        }

        // حذف سجلات المبيعات
        try {
          await txn.execute('DELETE FROM sale_items');
          debugPrint('تم حذف sale_items بنجاح');
        } catch (e) {
          debugPrint('خطأ في حذف sale_items: $e');
        }

        // حذف المبيعات
        try {
          await txn.execute('DELETE FROM sales');
          debugPrint('تم حذف sales بنجاح');
        } catch (e) {
          debugPrint('خطأ في حذف sales: $e');
          rethrow; // نرمي الخطأ هنا لأن حذف المبيعات مهم
        }

        // إعادة تعيين AUTO_INCREMENT
        try {
          await txn.execute(
              'DELETE FROM sqlite_sequence WHERE name IN ("sales", "sale_items", "installments")');
          debugPrint('تم إعادة تعيين sqlite_sequence بنجاح');
        } catch (e) {
          debugPrint('خطأ في إعادة تعيين sqlite_sequence: $e');
          // لا نرمي الخطأ هنا لأن هذا ليس حرجاً
        }
      });

      // إعادة تفعيل المفاتيح الخارجية
      await _db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      // التأكد من إعادة تفعيل المفاتيح الخارجية حتى في حالة الخطأ
      try {
        await _db.execute('PRAGMA foreign_keys = ON');
      } catch (_) {}
      debugPrint('خطأ في حذف المبيعات: $e');
      throw Exception('خطأ في حذف المبيعات: $e');
    }
  }

  /// حذف العملاء فقط
  Future<void> deleteCustomersOnly() async {
    try {
      await _db.transaction((txn) async {
        // حذف الأقساط أولاً (لأنها مرتبطة بالمبيعات)
        try {
          await txn.execute('DELETE FROM installments');
        } catch (e) {
          debugPrint('خطأ في حذف installments: $e');
        }

        // حذف عناصر المبيعات (لأنها مرتبطة بالمبيعات)
        try {
          await txn.execute('DELETE FROM sale_items');
        } catch (e) {
          debugPrint('خطأ في حذف sale_items: $e');
        }

        // حذف المبيعات (لأنها مرتبطة بالعملاء)
        try {
          await txn.execute('DELETE FROM sales');
        } catch (e) {
          debugPrint('خطأ في حذف sales: $e');
          rethrow;
        }

        // حذف المدفوعات المرتبطة بالعملاء
        try {
          await txn.delete('payments');
        } catch (e) {
          debugPrint('خطأ في حذف payments: $e');
        }

        // حذف العملاء
        try {
          await txn.delete('customers');
        } catch (e) {
          debugPrint('خطأ في حذف customers: $e');
          rethrow;
        }

        // إعادة تعيين AUTO_INCREMENT
        await txn.execute(
            'DELETE FROM sqlite_sequence WHERE name IN ("customers", "payments", "sales", "sale_items", "installments")');
      });
    } catch (e) {
      throw Exception('خطأ في حذف العملاء: $e');
    }
  }

  /// حذف المدفوعات فقط
  Future<void> deletePaymentsOnly() async {
    try {
      await _db.transaction((txn) async {
        // حذف المدفوعات
        await txn.delete('payments');

        // إعادة تعيين AUTO_INCREMENT
        await txn
            .execute('DELETE FROM sqlite_sequence WHERE name = "payments"');
      });
    } catch (e) {
      throw Exception('خطأ في حذف المدفوعات: $e');
    }
  }

  /// حذف المصروفات فقط
  Future<void> deleteExpensesOnly() async {
    try {
      await _db.transaction((txn) async {
        // حذف المصروفات
        await txn.delete('expenses');

        // إعادة تعيين AUTO_INCREMENT
        await txn
            .execute('DELETE FROM sqlite_sequence WHERE name = "expenses"');
      });
    } catch (e) {
      throw Exception('خطأ في حذف المصروفات: $e');
    }
  }

  /// حذف الأقساط فقط
  Future<void> deleteInstallmentsOnly() async {
    try {
      await _db.transaction((txn) async {
        // حذف الأقساط
        await txn.delete('installments');

        // إعادة تعيين AUTO_INCREMENT
        await txn
            .execute('DELETE FROM sqlite_sequence WHERE name = "installments"');
      });
    } catch (e) {
      throw Exception('خطأ في حذف الأقساط: $e');
    }
  }

  /// حذف جميع الموردين فقط
  Future<void> deleteSuppliersOnly() async {
    try {
      await _db.transaction((txn) async {
        // حذف مدفوعات الموردين أولاً
        try {
          await txn.execute('DELETE FROM supplier_payments');
        } catch (e) {
          debugPrint('خطأ في حذف supplier_payments: $e');
        }

        // حذف الموردين
        try {
          await txn.execute('DELETE FROM suppliers');
        } catch (e) {
          debugPrint('خطأ في حذف suppliers: $e');
          rethrow;
        }

        // إعادة تعيين AUTO_INCREMENT
        try {
          await txn.execute(
              'DELETE FROM sqlite_sequence WHERE name IN ("suppliers", "supplier_payments")');
        } catch (e) {
          debugPrint('خطأ في إعادة تعيين sqlite_sequence: $e');
        }
      });
    } catch (e) {
      debugPrint('خطأ في حذف الموردين: $e');
      throw Exception('خطأ في حذف الموردين: $e');
    }
  }

  /// حذف المنتجات فقط (مع حذف سجلات sale_items المرتبطة)
  Future<void> deleteProductsOnly() async {
    try {
      // تعطيل المفاتيح الخارجية خارج transaction
      await _db.execute('PRAGMA foreign_keys = OFF');

      // نفّذ الحذف داخل معاملة واحدة
      await _db.transaction((txn) async {
        // حذف عناصر المبيعات المرتبطة بالمنتجات
        try {
          await txn.execute('DELETE FROM sale_items');
        } catch (e) {
          debugPrint('خطأ في حذف sale_items: $e');
        }

        // حذف الخصومات المرتبطة بالمنتجات
        try {
          await txn.execute('DELETE FROM product_discounts');
        } catch (e) {
          debugPrint('خطأ في حذف product_discounts: $e');
        }

        // حذف المنتجات فقط
        try {
          await txn.execute('DELETE FROM products');
        } catch (e) {
          debugPrint('خطأ في حذف products: $e');
          rethrow;
        }

        // إعادة تعيين AUTO_INCREMENT
        try {
          await txn.execute(
              'DELETE FROM sqlite_sequence WHERE name IN ("products", "sale_items", "product_discounts")');
        } catch (e) {
          debugPrint('خطأ في إعادة تعيين sqlite_sequence: $e');
        }
      });

      // إعادة تفعيل المفاتيح الخارجية
      await _db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      // التأكد من إعادة تفعيل المفاتيح الخارجية حتى في حالة الخطأ
      try {
        await _db.execute('PRAGMA foreign_keys = ON');
      } catch (_) {}
      debugPrint('خطأ في حذف المنتجات: $e');
      throw Exception('خطأ في حذف المنتجات: $e');
    }
  }

  /// حذف الأقسام الفارغة فقط (التي لا تحتوي على منتجات)
  Future<int> deleteEmptyCategories() async {
    try {
      return await _db.transaction<int>((txn) async {
        final deleted = await txn.rawDelete('''
          DELETE FROM categories
          WHERE id NOT IN (
            SELECT DISTINCT IFNULL(category_id, -1) FROM products
          )
        ''');
        await txn
            .execute('DELETE FROM sqlite_sequence WHERE name = "categories"');
        return deleted;
      });
    } catch (e) {
      throw Exception('خطأ في حذف الأقسام الفارغة: $e');
    }
  }

  /// حذف العملاء الذين ليس لديهم أي مبيعات (مع حذف مدفوعاتهم)
  Future<void> deleteCustomersWithoutSales() async {
    try {
      await _db.transaction((txn) async {
        // حذف المدفوعات للعملاء الذين لا يملكون مبيعات
        await txn.execute('''
          DELETE FROM payments
          WHERE customer_id IN (
            SELECT c.id FROM customers c
            LEFT JOIN sales s ON s.customer_id = c.id
            WHERE s.id IS NULL
          )
        ''');

        // حذف العملاء الذين لا يملكون مبيعات
        await txn.execute('''
          DELETE FROM customers
          WHERE id IN (
            SELECT c.id FROM customers c
            LEFT JOIN sales s ON s.customer_id = c.id
            WHERE s.id IS NULL
          )
        ''');

        await txn
            .execute('DELETE FROM sqlite_sequence WHERE name = "customers"');
      });
    } catch (e) {
      throw Exception('خطأ في حذف العملاء بدون مبيعات: $e');
    }
  }

  /// حذف المبيعات الأقدم من تاريخ محدد (مع العناصر والأقساط)
  Future<void> deleteSalesBefore(DateTime cutoff) async {
    try {
      final cutoffIso = cutoff.toIso8601String();

      // تعطيل المفاتيح الخارجية خارج transaction
      await _db.execute('PRAGMA foreign_keys = OFF');

      // نفّذ الحذف داخل معاملة واحدة
      await _db.transaction((txn) async {
        // حذف الأقساط المرتبطة بمبيعات قديمة
        try {
          await txn.execute('''
            DELETE FROM installments
            WHERE sale_id IN (
              SELECT id FROM sales WHERE created_at < ?
            )
          ''', [cutoffIso]);
          debugPrint('تم حذف installments القديمة بنجاح');
        } catch (e) {
          debugPrint('خطأ في حذف installments: $e');
        }

        // حذف عناصر المبيعات للمبيعات القديمة
        try {
          await txn.execute('''
            DELETE FROM sale_items
            WHERE sale_id IN (
              SELECT id FROM sales WHERE created_at < ?
            )
          ''', [cutoffIso]);
          debugPrint('تم حذف sale_items القديمة بنجاح');
        } catch (e) {
          debugPrint('خطأ في حذف sale_items: $e');
        }

        // حذف المبيعات القديمة
        try {
          await txn
              .execute('DELETE FROM sales WHERE created_at < ?', [cutoffIso]);
          debugPrint('تم حذف sales القديمة بنجاح');
        } catch (e) {
          debugPrint('خطأ في حذف sales: $e');
          rethrow; // نرمي الخطأ هنا لأن حذف المبيعات مهم
        }

        // إعادة تعيين AUTO_INCREMENT
        try {
          await txn.execute(
              'DELETE FROM sqlite_sequence WHERE name IN ("sales", "sale_items", "installments")');
          debugPrint('تم إعادة تعيين sqlite_sequence بنجاح');
        } catch (e) {
          debugPrint('خطأ في إعادة تعيين sqlite_sequence: $e');
          // لا نرمي الخطأ هنا لأن هذا ليس حرجاً
        }
      });

      // إعادة تفعيل المفاتيح الخارجية
      await _db.execute('PRAGMA foreign_keys = ON');
    } catch (e) {
      // التأكد من إعادة تفعيل المفاتيح الخارجية حتى في حالة الخطأ
      try {
        await _db.execute('PRAGMA foreign_keys = ON');
      } catch (_) {}
      debugPrint('خطأ في حذف المبيعات القديمة: $e');
      throw Exception('خطأ في حذف المبيعات القديمة: $e');
    }
  }

  /// إعادة تعيين كميات المخزون إلى صفر لجميع المنتجات
  Future<void> resetInventoryToZero() async {
    try {
      await _db.transaction((txn) async {
        await txn.execute('UPDATE products SET quantity = 0');
      });
    } catch (e) {
      throw Exception('خطأ في إعادة تعيين كميات المخزون: $e');
    }
  }

  /// ضغط قاعدة البيانات لتقليل الحجم بعد عمليات الحذف الكبيرة
  Future<void> vacuumDatabase() async {
    try {
      await _db.execute('VACUUM');
    } catch (e) {
      throw Exception('خطأ في ضغط قاعدة البيانات: $e');
    }
  }

  // ==================== دوال إدارة المصروفات ====================

  /// إضافة مصروف جديد
  Future<int> createExpense({
    required String title,
    required double amount,
    required String category,
    String? description,
    DateTime? expenseDate,
  }) async {
    try {
      // التأكد من وجود الأعمدة المطلوبة
      await _ensureExpensesTableColumns(_db);

      final now = DateTime.now().toIso8601String();
      final expenseDateStr = (expenseDate ?? DateTime.now()).toIso8601String();

      final hasExpenseDate =
          await _columnExists(_db, 'expenses', 'expense_date');
      final hasCategory = await _columnExists(_db, 'expenses', 'category');
      final hasDescription =
          await _columnExists(_db, 'expenses', 'description');
      final hasUpdatedAt = await _columnExists(_db, 'expenses', 'updated_at');

      final data = <String, dynamic>{
        'title': title,
        'amount': amount,
        'created_at': now,
      };

      if (hasExpenseDate) {
        data['expense_date'] = expenseDateStr;
      }
      if (hasCategory) {
        data['category'] = category;
      }
      if (hasDescription && description != null) {
        data['description'] = description;
      }
      if (hasUpdatedAt) {
        data['updated_at'] = now;
      }

      final id = await _db.insert('expenses', data);

      return id;
    } catch (e) {
      throw Exception('خطأ في إضافة المصروف: $e');
    }
  }

  /// تحديث مصروف موجود
  Future<void> updateExpense({
    required int id,
    required String title,
    required double amount,
    required String category,
    String? description,
    DateTime? expenseDate,
  }) async {
    try {
      // التأكد من وجود الأعمدة المطلوبة
      await _ensureExpensesTableColumns(_db);

      final now = DateTime.now().toIso8601String();
      final expenseDateStr = (expenseDate ?? DateTime.now()).toIso8601String();

      final hasExpenseDate =
          await _columnExists(_db, 'expenses', 'expense_date');
      final hasCategory = await _columnExists(_db, 'expenses', 'category');
      final hasDescription =
          await _columnExists(_db, 'expenses', 'description');
      final hasUpdatedAt = await _columnExists(_db, 'expenses', 'updated_at');

      final data = <String, dynamic>{
        'title': title,
        'amount': amount,
      };

      if (hasExpenseDate) {
        data['expense_date'] = expenseDateStr;
      }
      if (hasCategory) {
        data['category'] = category;
      }
      if (hasDescription) {
        data['description'] = description;
      }
      if (hasUpdatedAt) {
        data['updated_at'] = now;
      }

      await _db.update(
        'expenses',
        data,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('خطأ في تحديث المصروف: $e');
    }
  }

  /// حذف مصروف
  Future<void> deleteExpense(int id,
      {int? userId, String? username, String? name}) async {
    try {
      await _db.transaction((txn) async {
        // التحقق من وجود المصروف
        final expense = await txn.query('expenses',
            where: 'id = ?', whereArgs: [id], limit: 1);
        if (expense.isEmpty) {
          throw Exception('المصروف غير موجود');
        }

        // حفظ بيانات المصروف في سلة المحذوفات قبل الحذف
        final expenseData = expense.first;
        await txn.insert('deleted_items', {
          'entity_type': 'expense',
          'entity_id': id,
          'original_data': jsonEncode(expenseData),
          'deleted_by_user_id': userId,
          'deleted_by_username': username,
          'deleted_by_name': name,
          'deleted_at': DateTime.now().toIso8601String(),
          'can_restore': 1,
        });

        // حذف المصروف
        await txn.delete(
          'expenses',
          where: 'id = ?',
          whereArgs: [id],
        );
      });
    } catch (e) {
      throw Exception('خطأ في حذف المصروف: $e');
    }
  }

  /// الحصول على جميع المصروفات
  Future<List<Map<String, dynamic>>> getExpenses({
    DateTime? from,
    DateTime? to,
    String? category,
  }) async {
    try {
      // التأكد من وجود الأعمدة المطلوبة
      await _ensureExpensesTableColumns(_db);

      // التحقق من وجود عمود expense_date
      final hasExpenseDate =
          await _columnExists(_db, 'expenses', 'expense_date');
      final dateColumn = hasExpenseDate ? 'expense_date' : 'created_at';

      final where = <String>[];
      final whereArgs = <Object?>[];

      if (from != null) {
        where.add('$dateColumn >= ?');
        whereArgs.add(from.toIso8601String());
      }

      if (to != null) {
        where.add('$dateColumn <= ?');
        whereArgs.add(to.toIso8601String());
      }

      if (category != null && category.isNotEmpty) {
        final hasCategory = await _columnExists(_db, 'expenses', 'category');
        if (hasCategory) {
          where.add('category = ?');
          whereArgs.add(category);
        }
      }

      final whereClause =
          where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';

      return await _db.rawQuery('''
        SELECT * FROM expenses
        $whereClause
        ORDER BY $dateColumn DESC, created_at DESC
      ''', whereArgs);
    } catch (e) {
      throw Exception('خطأ في جلب المصروفات: $e');
    }
  }

  /// الحصول على مصروف واحد
  Future<Map<String, dynamic>?> getExpense(int id) async {
    try {
      final result = await _db.query(
        'expenses',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      return result.isEmpty ? null : result.first;
    } catch (e) {
      throw Exception('خطأ في جلب المصروف: $e');
    }
  }

  /// الحصول على إجمالي المصروفات
  Future<double> getTotalExpenses({
    DateTime? from,
    DateTime? to,
    String? category,
  }) async {
    try {
      // التأكد من وجود الأعمدة المطلوبة
      await _ensureExpensesTableColumns(_db);

      // التحقق من وجود عمود expense_date
      final hasExpenseDate =
          await _columnExists(_db, 'expenses', 'expense_date');
      final dateColumn = hasExpenseDate ? 'expense_date' : 'created_at';

      final where = <String>[];
      final whereArgs = <Object?>[];

      if (from != null) {
        where.add('$dateColumn >= ?');
        whereArgs.add(from.toIso8601String());
      }

      if (to != null) {
        where.add('$dateColumn <= ?');
        whereArgs.add(to.toIso8601String());
      }

      if (category != null && category.isNotEmpty) {
        final hasCategory = await _columnExists(_db, 'expenses', 'category');
        if (hasCategory) {
          where.add('category = ?');
          whereArgs.add(category);
        }
      }

      final whereClause =
          where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';

      final result = await _db.rawQuery('''
        SELECT COALESCE(SUM(amount), 0) as total FROM expenses
        $whereClause
      ''', whereArgs);

      return (result.first['total'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      throw Exception('خطأ في حساب إجمالي المصروفات: $e');
    }
  }

  /// الحصول على قائمة أنواع المصروفات
  Future<List<String>> getExpenseCategories() async {
    try {
      final result = await _db.rawQuery('''
        SELECT DISTINCT category FROM expenses
        WHERE category IS NOT NULL AND category != ''
        ORDER BY category
      ''');

      return result.map((row) => row['category']?.toString() ?? '').toList();
    } catch (e) {
      return [];
    }
  }

  /// حذف نوع مصروف (تحديث جميع المصروفات التي تستخدمه إلى "عام")
  Future<int> deleteExpenseCategory(String category) async {
    try {
      if (category == 'عام') {
        throw Exception('لا يمكن حذف النوع الافتراضي "عام"');
      }

      // التحقق من وجود مصروفات تستخدم هذا النوع
      final countResult = await _db.rawQuery('''
        SELECT COUNT(*) as count FROM expenses
        WHERE category = ?
      ''', [category]);

      final count = (countResult.first['count'] as num?)?.toInt() ?? 0;

      if (count > 0) {
        // تحديث جميع المصروفات التي تستخدم هذا النوع إلى "عام"
        final updated = await _db.update(
          'expenses',
          {
            'category': 'عام',
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'category = ?',
          whereArgs: [category],
        );
        return updated;
      }

      return 0;
    } catch (e) {
      throw Exception('خطأ في حذف نوع المصروف: $e');
    }
  }

  /// الحصول على عدد المصروفات لنوع معين
  Future<int> getExpenseCountByCategory(String category) async {
    try {
      final result = await _db.rawQuery('''
        SELECT COUNT(*) as count FROM expenses
        WHERE category = ?
      ''', [category]);

      return (result.first['count'] as num?)?.toInt() ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// الحصول على جميع المعاملات المالية (مبيعات، مصروفات، مدفوعات)
  Future<List<Map<String, dynamic>>> getAllFinancialTransactions({
    DateTime? from,
    DateTime? to,
    String? transactionType,
  }) async {
    try {
      final transactions = <Map<String, dynamic>>[];

      // إضافة المبيعات
      if (transactionType == null || transactionType == 'sales') {
        final where = <String>[];
        final args = <Object?>[];

        if (from != null && to != null) {
          where.add('s.created_at BETWEEN ? AND ?');
          args.addAll([from.toIso8601String(), to.toIso8601String()]);
        }

        final sales = await _db.rawQuery('''
          SELECT 
            s.id,
            s.created_at as transaction_date,
            s.total as amount,
            s.profit,
            s.type,
            c.name as customer_name,
            'sale' as transaction_type,
            'مبيعات' as transaction_type_label,
            CASE 
              WHEN s.type = 'cash' THEN 'نقدي'
              WHEN s.type = 'credit' THEN 'آجل'
              WHEN s.type = 'installment' THEN 'أقساط'
              ELSE s.type
            END as type_label
          FROM sales s
          LEFT JOIN customers c ON c.id = s.customer_id
          ${where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : ''}
          ORDER BY s.created_at DESC
        ''', args);

        transactions.addAll(sales.map((s) => {
              ...s,
              'amount': (s['amount'] as num?)?.toDouble() ?? 0.0,
              'profit': (s['profit'] as num?)?.toDouble() ?? 0.0,
            }));
      }

      // إضافة المصروفات
      if (transactionType == null || transactionType == 'expenses') {
        // التأكد من وجود الأعمدة المطلوبة
        await _ensureExpensesTableColumns(_db);

        // التحقق من وجود عمود expense_date
        final hasExpenseDate =
            await _columnExists(_db, 'expenses', 'expense_date');
        final dateColumn = hasExpenseDate ? 'expense_date' : 'created_at';

        final where = <String>[];
        final args = <Object?>[];

        if (from != null && to != null) {
          where.add('e.$dateColumn BETWEEN ? AND ?');
          args.addAll([from.toIso8601String(), to.toIso8601String()]);
        }

        final hasCategory = await _columnExists(_db, 'expenses', 'category');
        final categorySelect =
            hasCategory ? 'e.category' : '\'عام\' as category';
        final categoryLabel = hasCategory ? 'e.category' : '\'عام\'';

        final expenses = await _db.rawQuery('''
          SELECT 
            e.id,
            e.$dateColumn as transaction_date,
            e.amount,
            e.title,
            $categorySelect,
            ${await _columnExists(_db, 'expenses', 'description') ? 'e.description' : 'NULL as description'},
            NULL as profit,
            'expense' as transaction_type,
            'مصروفات' as transaction_type_label,
            $categoryLabel as type_label
          FROM expenses e
          ${where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : ''}
          ORDER BY e.$dateColumn DESC
        ''', args);

        transactions.addAll(expenses.map((e) => {
              ...e,
              'amount': (e['amount'] as num?)?.toDouble() ?? 0.0,
            }));
      }

      // إضافة المدفوعات
      if (transactionType == null || transactionType == 'payments') {
        final where = <String>[];
        final args = <Object?>[];

        if (from != null && to != null) {
          where.add('p.payment_date BETWEEN ? AND ?');
          args.addAll([from.toIso8601String(), to.toIso8601String()]);
        }

        final payments = await _db.rawQuery('''
          SELECT 
            p.id,
            p.payment_date as transaction_date,
            p.amount,
            p.notes as description,
            c.name as customer_name,
            NULL as profit,
            'payment' as transaction_type,
            'مدفوعات' as transaction_type_label,
            'دفعة' as type_label
          FROM payments p
          JOIN customers c ON c.id = p.customer_id
          ${where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : ''}
          ORDER BY p.payment_date DESC
        ''', args);

        transactions.addAll(payments.map((p) => {
              ...p,
              'amount': (p['amount'] as num?)?.toDouble() ?? 0.0,
            }));
      }

      // ترتيب جميع المعاملات حسب التاريخ
      transactions.sort((a, b) {
        final dateA = a['transaction_date']?.toString() ?? '';
        final dateB = b['transaction_date']?.toString() ?? '';
        return dateB.compareTo(dateA); // الأحدث أولاً
      });

      return transactions;
    } catch (e) {
      throw Exception('خطأ في جلب المعاملات المالية: $e');
    }
  }

  // ========== دوال المرتجعات ==========

  /// التأكد من وجود جميع الأعمدة المطلوبة في جدول returns
  Future<void> _ensureReturnsTableColumns([Database? db]) async {
    try {
      final database = db ?? _db;
      // التحقق من وجود الجدول أولاً
      final tables = await database.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='returns'");

      if (tables.isNotEmpty) {
        final columns = await database.rawQuery("PRAGMA table_info(returns)");
        final columnNames =
            columns.map((c) => c['name']?.toString().toLowerCase()).toSet();

        // إضافة العمود return_date إذا لم يكن موجوداً
        if (!columnNames.contains('return_date')) {
          debugPrint('إضافة عمود return_date إلى جدول returns...');
          try {
            await database
                .execute('ALTER TABLE returns ADD COLUMN return_date TEXT');
            debugPrint('تم إضافة عمود return_date بنجاح');
          } catch (e) {
            debugPrint('خطأ في إضافة عمود return_date: $e');
          }
        }

        // إضافة العمود notes إذا لم يكن موجوداً
        if (!columnNames.contains('notes')) {
          debugPrint('إضافة عمود notes إلى جدول returns...');
          try {
            await database.execute('ALTER TABLE returns ADD COLUMN notes TEXT');
            debugPrint('تم إضافة عمود notes بنجاح');
          } catch (e) {
            debugPrint('خطأ في إضافة عمود notes: $e');
          }
        }

        // إضافة العمود created_at إذا لم يكن موجوداً
        if (!columnNames.contains('created_at')) {
          debugPrint('إضافة عمود created_at إلى جدول returns...');
          try {
            await database
                .execute('ALTER TABLE returns ADD COLUMN created_at TEXT');
            // تحديث البيانات الموجودة
            await database.execute(
                'UPDATE returns SET created_at = datetime(\'now\') WHERE created_at IS NULL');
            debugPrint('تم إضافة عمود created_at بنجاح');
          } catch (e) {
            debugPrint('خطأ في إضافة عمود created_at: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('خطأ في التأكد من أعمدة جدول returns: $e');
    }
  }

  /// التأكد من وجود عمود status في جدول returns
  Future<void> _ensureReturnsStatusColumn([Database? db]) async {
    try {
      final database = db ?? _db;
      final tables = await database.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='returns'");

      if (tables.isNotEmpty) {
        final columns = await database.rawQuery("PRAGMA table_info(returns)");
        final columnNames =
            columns.map((c) => c['name']?.toString().toLowerCase()).toSet();

        if (!columnNames.contains('status')) {
          debugPrint('إضافة عمود status إلى جدول returns...');
          try {
            await database.execute(
                'ALTER TABLE returns ADD COLUMN status TEXT NOT NULL DEFAULT \'pending\'');
            // تحديث البيانات الموجودة
            await database.execute(
                'UPDATE returns SET status = \'completed\' WHERE status IS NULL');
            debugPrint('تم إضافة عمود status بنجاح');
          } catch (e) {
            debugPrint('خطأ في إضافة عمود status: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('خطأ في التأكد من عمود status في جدول returns: $e');
    }
  }

  /// التأكد من وجود جدول supplier_payments
  Future<void> _ensureSupplierPaymentsTable([Database? db]) async {
    try {
      final database = db ?? _db;
      // التحقق من وجود الجدول أولاً
      final tables = await database.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='supplier_payments'");

      if (tables.isEmpty) {
        debugPrint('جدول supplier_payments غير موجود، جاري إنشاؤه...');
        await database.execute('''
          CREATE TABLE IF NOT EXISTS supplier_payments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            supplier_id INTEGER NOT NULL,
            amount REAL NOT NULL,
            payment_date TEXT NOT NULL,
            notes TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY(supplier_id) REFERENCES suppliers(id)
          );
        ''');
        // إنشاء الفهرس
        await database.execute(
            'CREATE INDEX IF NOT EXISTS idx_supplier_payments_supplier_id ON supplier_payments(supplier_id)');
        await database.execute(
            'CREATE INDEX IF NOT EXISTS idx_supplier_payments_date ON supplier_payments(payment_date)');
        debugPrint('تم إنشاء جدول supplier_payments بنجاح');
      }
    } catch (e) {
      debugPrint('خطأ في التأكد من جدول supplier_payments: $e');
    }
  }

  /// التأكد من وجود جميع الأعمدة المطلوبة في جدول expenses
  Future<void> _ensureExpensesTableColumns([Database? db]) async {
    try {
      final database = db ?? _db;
      // التحقق من وجود الجدول أولاً
      final tables = await database.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='expenses'");

      if (tables.isEmpty) {
        debugPrint('جدول expenses غير موجود، سيتم إنشاؤه في migration');
        return;
      }

      final columns = await database.rawQuery("PRAGMA table_info(expenses)");
      final columnNames =
          columns.map((c) => c['name']?.toString().toLowerCase()).toSet();

      // إضافة عمود expense_date إذا لم يكن موجوداً
      if (!columnNames.contains('expense_date')) {
        debugPrint('إضافة عمود expense_date إلى جدول expenses...');
        try {
          await database
              .execute('ALTER TABLE expenses ADD COLUMN expense_date TEXT');
          // نسخ created_at إلى expense_date للبيانات الموجودة
          await database.execute(
              'UPDATE expenses SET expense_date = created_at WHERE expense_date IS NULL');
          debugPrint('تم إضافة عمود expense_date بنجاح');
        } catch (e) {
          debugPrint('خطأ في إضافة عمود expense_date: $e');
        }
      }

      // إضافة عمود category إذا لم يكن موجوداً
      if (!columnNames.contains('category')) {
        debugPrint('إضافة عمود category إلى جدول expenses...');
        try {
          await database.execute(
              'ALTER TABLE expenses ADD COLUMN category TEXT NOT NULL DEFAULT \'عام\'');
          debugPrint('تم إضافة عمود category بنجاح');
        } catch (e) {
          debugPrint('خطأ في إضافة عمود category: $e');
        }
      }

      // إضافة عمود description إذا لم يكن موجوداً
      if (!columnNames.contains('description')) {
        debugPrint('إضافة عمود description إلى جدول expenses...');
        try {
          await database
              .execute('ALTER TABLE expenses ADD COLUMN description TEXT');
          debugPrint('تم إضافة عمود description بنجاح');
        } catch (e) {
          debugPrint('خطأ في إضافة عمود description: $e');
        }
      }

      // إضافة عمود updated_at إذا لم يكن موجوداً
      if (!columnNames.contains('updated_at')) {
        debugPrint('إضافة عمود updated_at إلى جدول expenses...');
        try {
          await database
              .execute('ALTER TABLE expenses ADD COLUMN updated_at TEXT');
          debugPrint('تم إضافة عمود updated_at بنجاح');
        } catch (e) {
          debugPrint('خطأ في إضافة عمود updated_at: $e');
        }
      }
    } catch (e) {
      debugPrint('خطأ في التأكد من أعمدة جدول expenses: $e');
    }
  }

  /// إنشاء جدول المرتجعات إذا لم يكن موجوداً (للتوافق مع الإصدارات القديمة)
  Future<void> _ensureReturnsTable([Database? db]) async {
    try {
      final database = db ?? _db;
      // التحقق من وجود الجدول أولاً
      final tables = await database.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='returns'");
      if (tables.isEmpty) {
        debugPrint('إنشاء جدول returns...');
        await database.execute('''
          CREATE TABLE returns (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sale_id INTEGER NOT NULL,
            total_amount REAL NOT NULL,
            return_date TEXT NOT NULL,
            notes TEXT,
            status TEXT NOT NULL DEFAULT 'pending',
            created_at TEXT NOT NULL,
            FOREIGN KEY(sale_id) REFERENCES sales(id)
          );
        ''');
        debugPrint('تم إنشاء جدول returns بنجاح');
      } else {
        debugPrint('جدول returns موجود بالفعل');
        // التحقق من وجود الأعمدة المطلوبة
        final columns = await database.rawQuery("PRAGMA table_info(returns)");
        final columnNames =
            columns.map((c) => c['name']?.toString().toLowerCase()).toSet();

        // إضافة العمود return_date إذا لم يكن موجوداً
        if (!columnNames.contains('return_date')) {
          debugPrint('إضافة عمود return_date إلى جدول returns...');
          try {
            await database
                .execute('ALTER TABLE returns ADD COLUMN return_date TEXT');
            debugPrint('تم إضافة عمود return_date بنجاح');
          } catch (e) {
            debugPrint('خطأ في إضافة عمود return_date: $e');
          }
        }

        // إضافة العمود notes إذا لم يكن موجوداً
        if (!columnNames.contains('notes')) {
          debugPrint('إضافة عمود notes إلى جدول returns...');
          try {
            await database.execute('ALTER TABLE returns ADD COLUMN notes TEXT');
            debugPrint('تم إضافة عمود notes بنجاح');
          } catch (e) {
            debugPrint('خطأ في إضافة عمود notes: $e');
          }
        }

        // إضافة العمود created_at إذا لم يكن موجوداً
        if (!columnNames.contains('created_at')) {
          debugPrint('إضافة عمود created_at إلى جدول returns...');
          try {
            await database.execute(
                'ALTER TABLE returns ADD COLUMN created_at TEXT NOT NULL DEFAULT (datetime(\'now\'))');
            debugPrint('تم إضافة عمود created_at بنجاح');
          } catch (e) {
            debugPrint('خطأ في إضافة عمود created_at: $e');
          }
        }
      }
    } catch (e) {
      // لا نرمي الخطأ هنا لأن الجدول قد يكون موجوداً بالفعل
    }
  }

  /// الحصول على جميع المرتجعات
  Future<List<Map<String, dynamic>>> getReturns({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      // التأكد من وجود الجدول
      await _ensureReturnsTable();

      // التحقق من وجود الجدول
      final tables = await _db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='returns'");
      if (tables.isEmpty) {
        debugPrint('جدول returns غير موجود، محاولة إنشائه...');
        await _ensureReturnsTable();
      }

      final where = <String>[];
      final whereArgs = <Object?>[];

      if (from != null && to != null) {
        where.add('r.return_date BETWEEN ? AND ?');
        whereArgs.addAll([from.toIso8601String(), to.toIso8601String()]);
      }

      final whereClause =
          where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';

      final returns = await _db.rawQuery('''
        SELECT 
          r.id,
          r.sale_id,
          r.total_amount,
          r.return_date,
          r.notes,
          r.status,
          r.created_at,
          c.name as customer_name
        FROM returns r
        LEFT JOIN sales s ON s.id = r.sale_id
        LEFT JOIN customers c ON c.id = s.customer_id
        $whereClause
        ORDER BY r.return_date DESC, r.created_at DESC
      ''', whereArgs);

      return returns
          .map((r) => {
                ...r,
                'total_amount': (r['total_amount'] as num?)?.toDouble() ?? 0.0,
              })
          .toList();
    } catch (e) {
      // إرجاع قائمة فارغة بدلاً من رمي خطأ
      return [];
    }
  }

  /// إنشاء مرتجع جديد مع إرجاع المنتجات للمخزون وتحديث الديون
  Future<int> createReturn({
    required int saleId,
    required double totalAmount,
    required List<Map<String, dynamic>>
        returnItems, // [{product_id, quantity, price}]
    String? notes,
    String status = 'pending',
    int? userId,
    String? username,
  }) async {
    return await _db.transaction<int>((txn) async {
      try {
        // الحصول على تفاصيل البيع
        final sale = await txn.query('sales',
            where: 'id = ?', whereArgs: [saleId], limit: 1);
        if (sale.isEmpty) {
          throw Exception('الفاتورة غير موجودة');
        }

        final saleData = sale.first;
        final saleType = saleData['type'] as String;
        final customerId = saleData['customer_id'] as int?;

        // إرجاع المنتجات للمخزون
        for (final item in returnItems) {
          final productId = item['product_id'] as int;
          final quantity = item['quantity'] as int;
          await txn.rawUpdate(
            'UPDATE products SET quantity = quantity + ? WHERE id = ?',
            [quantity, productId],
          );
        }

        // تحديث إجمالي المبيعات (تقليل المبلغ من إجمالي الفاتورة)
        final currentTotal = (saleData['total'] as num).toDouble();
        final newTotal =
            (currentTotal - totalAmount).clamp(0.0, double.infinity);
        final currentProfit = (saleData['profit'] as num?)?.toDouble() ?? 0.0;

        // حساب الربح المرتجع (نسبة من الربح الأصلي)
        final profitRatio = currentTotal > 0 ? totalAmount / currentTotal : 0.0;
        final returnedProfit = currentProfit * profitRatio;
        final newProfit =
            (currentProfit - returnedProfit).clamp(0.0, double.infinity);

        await txn.rawUpdate(
          'UPDATE sales SET total = ?, profit = ? WHERE id = ?',
          [newTotal, newProfit, saleId],
        );

        // تحديث ديون العميل إذا كان البيع آجل أو أقساط
        if (customerId != null &&
            (saleType == 'credit' || saleType == 'installment')) {
          await txn.rawUpdate(
            'UPDATE customers SET total_debt = IFNULL(total_debt, 0) - ? WHERE id = ?',
            [totalAmount, customerId],
          );
        }

        // إنشاء سجل المرتجع
        final now = DateTime.now();
        final returnId = await txn.insert('returns', {
          'sale_id': saleId,
          'total_amount': totalAmount,
          'return_date': now.toIso8601String(),
          'notes': notes,
          'status': status,
          'created_at': now.toIso8601String(),
        });

        // تسجيل حدث المرتجع
        try {
          await logEvent(
            eventType: 'return',
            entityType: 'return',
            entityId: returnId,
            userId: userId,
            username: username,
            description:
                'إنشاء مرتجع للفاتورة #$saleId - المبلغ: ${totalAmount.toStringAsFixed(2)}',
            details: 'عدد المنتجات المرجعة: ${returnItems.length}',
            transaction: txn,
          );
        } catch (e) {
          debugPrint('خطأ في تسجيل حدث المرتجع: $e');
        }

        return returnId;
      } catch (e) {
        debugPrint('خطأ في إنشاء المرتجع: $e');
        rethrow;
      }
    });
  }

  /// حذف مرتجع
  Future<void> deleteReturn(int id) async {
    try {
      await _ensureReturnsTable();

      // محاولة الحذف مع معاملة عادية أولاً
      try {
        return await _db.transaction<void>((txn) async {
          // حذف سجلات event_log المرتبطة بالمرتجع أولاً
          try {
            await txn.delete(
              'event_log',
              where: 'entity_type = ? AND entity_id = ?',
              whereArgs: ['return', id],
            );
          } catch (e) {
            debugPrint('خطأ في حذف سجلات event_log للمرتجع: $e');
            // نتابع حتى لو فشل حذف سجلات event_log
          }

          // حذف المرتجع
          final deletedRows = await txn.delete(
            'returns',
            where: 'id = ?',
            whereArgs: [id],
          );

          if (deletedRows == 0) {
            throw Exception('المرتجع غير موجود');
          }
        });
      } catch (e) {
        // إذا فشل الحذف بسبب قيد المفتاح الخارجي، نستخدم تعطيل المفاتيح الخارجية
        if (e.toString().contains('FOREIGN KEY') ||
            e.toString().contains('constraint')) {
          debugPrint(
              'فشل الحذف بسبب قيد المفتاح الخارجي، محاولة مع تعطيل المفاتيح الخارجية...');

          // تعطيل المفاتيح الخارجية مؤقتاً
          await _db.execute('PRAGMA foreign_keys = OFF');

          try {
            await _db.transaction<void>((txn) async {
              // حذف سجلات event_log المرتبطة بالمرتجع
              try {
                await txn.delete(
                  'event_log',
                  where: 'entity_type = ? AND entity_id = ?',
                  whereArgs: ['return', id],
                );
              } catch (e) {
                debugPrint('خطأ في حذف سجلات event_log للمرتجع: $e');
              }

              // حذف المرتجع
              final deletedRows = await txn.delete(
                'returns',
                where: 'id = ?',
                whereArgs: [id],
              );

              if (deletedRows == 0) {
                throw Exception('المرتجع غير موجود');
              }
            });
          } finally {
            // إعادة تفعيل المفاتيح الخارجية
            await _db.execute('PRAGMA foreign_keys = ON');
          }
        } else {
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('خطأ في حذف المرتجع: $e');
      throw Exception('خطأ في حذف المرتجع: $e');
    }
  }

  /// تحديث حالة المرتجع
  Future<void> updateReturnStatus({
    required int id,
    required String status,
    int? userId,
    String? username,
  }) async {
    try {
      await _ensureReturnsTable();
      await _ensureReturnsStatusColumn();

      await _db.update(
        'returns',
        {'status': status},
        where: 'id = ?',
        whereArgs: [id],
      );

      // تسجيل حدث تحديث الحالة
      try {
        await logEvent(
          eventType: 'return_status_update',
          entityType: 'return',
          entityId: id,
          userId: userId,
          username: username,
          description: 'تحديث حالة المرتجع #$id إلى: $status',
        );
      } catch (e) {
        debugPrint('خطأ في تسجيل حدث تحديث الحالة: $e');
      }
    } catch (e) {
      throw Exception('خطأ في تحديث حالة المرتجع: $e');
    }
  }

  /// الحصول على إحصائيات المصروفات حسب النوع
  Future<Map<String, double>> getExpensesByCategory({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final where = <String>[];
      final whereArgs = <Object?>[];

      if (from != null) {
        where.add('expense_date >= ?');
        whereArgs.add(from.toIso8601String());
      }

      if (to != null) {
        where.add('expense_date <= ?');
        whereArgs.add(to.toIso8601String());
      }

      final whereClause =
          where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';

      final result = await _db.rawQuery('''
        SELECT category, SUM(amount) as total
        FROM expenses
        $whereClause
        GROUP BY category
        ORDER BY total DESC
      ''', whereArgs);

      final map = <String, double>{};
      for (final row in result) {
        final category = row['category']?.toString() ?? 'عام';
        final total = (row['total'] as num?)?.toDouble() ?? 0.0;
        map[category] = total;
      }

      return map;
    } catch (e) {
      throw Exception('خطأ في جلب إحصائيات المصروفات: $e');
    }
  }

  /// فحص وإصلاح المستخدمين الافتراضيين
  Future<void> checkAndFixDefaultUsers() async {
    try {
      debugPrint('بدء فحص المستخدمين الافتراضيين...');

      // التحقق من وجود جدول المستخدمين
      final tables = await _db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='users'");

      if (tables.isEmpty) {
        debugPrint('جدول المستخدمين غير موجود، سيتم إنشاؤه...');
        await DatabaseSchema.createSchema(_db);
        return;
      }

      // حذف المستخدمين المؤقتين (الذين لديهم _conflict_ في اسم المستخدم)
      try {
        final conflictUsers = await _db.query(
          'users',
          where: 'username LIKE ?',
          whereArgs: ['%_conflict_%'],
        );
        if (conflictUsers.isNotEmpty) {
          await _db.delete(
            'users',
            where: 'username LIKE ?',
            whereArgs: ['%_conflict_%'],
          );
          debugPrint('تم حذف ${conflictUsers.length} مستخدم مؤقت');
        }
      } catch (e) {
        debugPrint('خطأ في حذف المستخدمين المؤقتين: $e');
      }

      // إنشاء المستخدمين الافتراضيين ببساطة
      // تحذير: يجب تغيير كلمات المرور الافتراضية فوراً بعد التثبيت للأمان
      final nowIso = DateTime.now().toIso8601String();
      final defaultUsers = [
        {
          'name': 'المدير',
          'username': 'manager',
          'password': _sha256Hex('man2026'),
          'role': 'manager',
          'employee_code': 'A1',
          'active': 1,
          'created_at': nowIso,
          'updated_at': nowIso,
        },
        {
          'name': 'المشرف',
          'username': 'supervisor',
          'password': _sha256Hex('sup2026'),
          'role': 'supervisor',
          'employee_code': 'S1',
          'active': 1,
          'created_at': nowIso,
          'updated_at': nowIso,
        },
        {
          'name': 'الموظف',
          'username': 'employee',
          'password': _sha256Hex('emp2026'),
          'role': 'employee',
          'employee_code': 'C1',
          'active': 1,
          'created_at': nowIso,
          'updated_at': nowIso,
        },
      ];

      for (final user in defaultUsers) {
        try {
          // محاولة إدراج أو تحديث المستخدم
          await _db.insert('users', user);
          debugPrint('تم إضافة مستخدم: ${user['username']}');
        } catch (e) {
          // إذا فشل الإدراج، جرب التحديث
          try {
            // التحقق من المستخدم الحالي أولاً
            final existing = await _db.query(
              'users',
              where: 'username = ?',
              whereArgs: [user['username']],
              limit: 1,
            );

            if (existing.isNotEmpty) {
              final currentEmployeeCode =
                  existing.first['employee_code']?.toString();
              final desiredEmployeeCode = user['employee_code']?.toString();

              // التحقق من وجود تضارب في employee_code
              bool hasConflict = false;
              if (currentEmployeeCode != desiredEmployeeCode) {
                final conflict = await _db.query(
                  'users',
                  where: 'employee_code = ? AND username != ?',
                  whereArgs: [desiredEmployeeCode, user['username']],
                  limit: 1,
                );
                hasConflict = conflict.isNotEmpty;
              }

              // تحديث الحقول الآمنة فقط (لا employee_code إذا كان هناك تضارب)
              final updateData = <String, dynamic>{
                'name': user['name'],
                'password': user['password'],
                'role': user['role'],
                'active': 1,
                'updated_at': nowIso,
              };

              // تحديث employee_code فقط إذا لم يكن هناك تضارب
              if (!hasConflict && currentEmployeeCode != desiredEmployeeCode) {
                updateData['employee_code'] = user['employee_code'];
              }

              await _db.update(
                'users',
                updateData,
                where: 'username = ?',
                whereArgs: [user['username']],
              );
              debugPrint('تم تحديث مستخدم: ${user['username']}');
            }
          } catch (updateError) {
            debugPrint(
                'فشل في تحديث المستخدم ${user['username']}: $updateError');
          }
        }
      }

      debugPrint('انتهى فحص وإصلاح المستخدمين الافتراضيين');
    } catch (e) {
      debugPrint('خطأ في فحص وإصلاح المستخدمين الافتراضيين: $e');
      // لا نرمي الاستثناء هنا لتجنب تعليق التطبيق
    }
  }

  // ==================== دوال التحليل والتحليلات ====================

  /// تحليل المبيعات: أكثر المنتجات مبيعاً
  Future<List<Map<String, dynamic>>> getTopSellingProducts({
    DateTime? from,
    DateTime? to,
    int limit = 10,
  }) async {
    try {
      final where = <String>[];
      final args = <Object?>[];

      if (from != null && to != null) {
        where.add('s.created_at BETWEEN ? AND ?');
        args.addAll([from.toIso8601String(), to.toIso8601String()]);
      }

      final whereClause =
          where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';

      return await _db.rawQuery('''
        SELECT 
          p.id,
          p.name,
          p.barcode,
          p.price,
          p.cost,
          SUM(si.quantity) as total_quantity_sold,
          SUM(si.price * si.quantity) as total_revenue,
          SUM((si.price - si.cost) * si.quantity) as total_profit,
          COUNT(DISTINCT s.id) as sales_count
        FROM products p
        JOIN sale_items si ON p.id = si.product_id
        JOIN sales s ON si.sale_id = s.id
        $whereClause
        GROUP BY p.id, p.name, p.barcode, p.price, p.cost
        ORDER BY total_quantity_sold DESC
        LIMIT ?
      ''', [...args, limit]);
    } catch (e) {
      throw Exception('خطأ في جلب أكثر المنتجات مبيعاً: $e');
    }
  }

  /// تحليل المبيعات: أقل المنتجات مبيعاً
  Future<List<Map<String, dynamic>>> getLeastSellingProducts({
    DateTime? from,
    DateTime? to,
    int limit = 10,
  }) async {
    try {
      final where = <String>[];
      final args = <Object?>[];

      if (from != null && to != null) {
        where.add('s.created_at BETWEEN ? AND ?');
        args.addAll([from.toIso8601String(), to.toIso8601String()]);
      }

      final whereClause =
          where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';

      return await _db.rawQuery('''
        SELECT 
          p.id,
          p.name,
          p.barcode,
          p.price,
          p.cost,
          p.quantity as current_stock,
          COALESCE(SUM(si.quantity), 0) as total_quantity_sold,
          COALESCE(SUM(si.price * si.quantity), 0) as total_revenue,
          COALESCE(SUM((si.price - si.cost) * si.quantity), 0) as total_profit,
          COALESCE(COUNT(DISTINCT s.id), 0) as sales_count
        FROM products p
        LEFT JOIN sale_items si ON p.id = si.product_id
        LEFT JOIN sales s ON si.sale_id = s.id $whereClause
        GROUP BY p.id, p.name, p.barcode, p.price, p.cost, p.quantity
        ORDER BY total_quantity_sold ASC, p.name ASC
        LIMIT ?
      ''', [...args, limit]);
    } catch (e) {
      throw Exception('خطأ في جلب أقل المنتجات مبيعاً: $e');
    }
  }

  /// تحليل العملاء: أفضل العملاء
  Future<List<Map<String, dynamic>>> getTopCustomers({
    DateTime? from,
    DateTime? to,
    int limit = 10,
  }) async {
    try {
      final where = <String>[];
      final args = <Object?>[];

      if (from != null && to != null) {
        where.add('s.created_at BETWEEN ? AND ?');
        args.addAll([from.toIso8601String(), to.toIso8601String()]);
      }

      final whereClause =
          where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';

      return await _db.rawQuery('''
        SELECT 
          c.id,
          c.name,
          c.phone,
          c.total_debt,
          COUNT(DISTINCT s.id) as total_purchases,
          COALESCE(SUM(s.total), 0) as total_spent,
          COALESCE(SUM(s.profit), 0) as total_profit_generated,
          MAX(s.created_at) as last_purchase_date
        FROM customers c
        LEFT JOIN sales s ON c.id = s.customer_id $whereClause
        GROUP BY c.id, c.name, c.phone, c.total_debt
        HAVING total_spent > 0
        ORDER BY total_spent DESC
        LIMIT ?
      ''', [...args, limit]);
    } catch (e) {
      throw Exception('خطأ في جلب أفضل العملاء: $e');
    }
  }

  /// تحليل العملاء: العملاء المتأخرين في الدفع
  Future<List<Map<String, dynamic>>> getOverdueCustomers({
    int? daysOverdue,
  }) async {
    try {
      final cutoffDate = daysOverdue != null
          ? DateTime.now().subtract(Duration(days: daysOverdue))
          : DateTime.now();

      return await _db.rawQuery('''
        SELECT 
          c.id,
          c.name,
          c.phone,
          c.total_debt,
          COUNT(DISTINCT s.id) as overdue_sales_count,
          SUM(s.total) as overdue_amount,
          MIN(s.due_date) as oldest_due_date,
          julianday('now') - julianday(MIN(s.due_date)) as days_overdue
        FROM customers c
        JOIN sales s ON c.id = s.customer_id
        WHERE s.type IN ('credit', 'installment')
          AND s.due_date IS NOT NULL
          AND s.due_date < ?
          AND c.total_debt > 0
        GROUP BY c.id, c.name, c.phone, c.total_debt
        ORDER BY days_overdue DESC, overdue_amount DESC
      ''', [cutoffDate.toIso8601String()]);
    } catch (e) {
      throw Exception('خطأ في جلب العملاء المتأخرين: $e');
    }
  }

  /// التنبؤ بالطلب: توقع المنتجات التي قد تنفد
  Future<List<Map<String, dynamic>>> getProductsAtRisk({
    int daysAhead = 30,
    double riskThreshold = 0.5,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysAhead));

      return await _db.rawQuery('''
        SELECT 
          p.id,
          p.name,
          p.barcode,
          p.quantity as current_stock,
          p.min_quantity,
          p.price,
          p.cost,
          COALESCE(SUM(si.quantity), 0) as sold_last_period,
          COALESCE(AVG(si.quantity), 0) as avg_daily_sales,
          CASE 
            WHEN p.quantity = 0 THEN 1.0
            WHEN p.quantity <= p.min_quantity THEN 0.9
            WHEN COALESCE(AVG(si.quantity), 0) > 0 AND p.quantity / NULLIF(AVG(si.quantity), 0) < 7 THEN 0.8
            WHEN COALESCE(AVG(si.quantity), 0) > 0 AND p.quantity / NULLIF(AVG(si.quantity), 0) < 14 THEN 0.6
            ELSE 0.3
          END as risk_score
        FROM products p
        LEFT JOIN sale_items si ON p.id = si.product_id
        LEFT JOIN sales s ON si.sale_id = s.id 
          AND s.created_at >= ?
        GROUP BY p.id, p.name, p.barcode, p.quantity, p.min_quantity, p.price, p.cost
        HAVING risk_score >= ?
        ORDER BY risk_score DESC, current_stock ASC
      ''', [cutoffDate.toIso8601String(), riskThreshold]);
    } catch (e) {
      throw Exception('خطأ في التنبؤ بالمنتجات المعرضة للخطر: $e');
    }
  }

  /// مؤشرات الأداء (KPIs) للمبيعات والأرباح
  Future<Map<String, dynamic>> getSalesKPIs({
    DateTime? from,
    DateTime? to,
    DateTime? previousFrom,
    DateTime? previousTo,
  }) async {
    try {
      final where = <String>[];
      final args = <Object?>[];

      if (from != null && to != null) {
        where.add('s.created_at BETWEEN ? AND ?');
        args.addAll([from.toIso8601String(), to.toIso8601String()]);
      }

      final whereClause =
          where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : '';

      // KPIs للفترة الحالية
      final currentKPIs = await _db.rawQuery('''
        SELECT 
          COUNT(DISTINCT s.id) as total_sales,
          COUNT(DISTINCT s.customer_id) as unique_customers,
          COUNT(DISTINCT si.product_id) as unique_products_sold,
          COALESCE(SUM(s.total), 0) as total_revenue,
          COALESCE(SUM(s.profit), 0) as total_profit,
          COALESCE(AVG(s.total), 0) as avg_sale_amount,
          COALESCE(SUM(CASE WHEN s.type = 'cash' THEN s.total ELSE 0 END), 0) as cash_sales,
          COALESCE(SUM(CASE WHEN s.type = 'credit' THEN s.total ELSE 0 END), 0) as credit_sales,
          COALESCE(SUM(CASE WHEN s.type = 'installment' THEN s.total ELSE 0 END), 0) as installment_sales
        FROM sales s
        LEFT JOIN sale_items si ON s.id = si.sale_id
        $whereClause
      ''', args);

      final kpis = currentKPIs.first;

      // حساب معدل الربح
      final totalRevenue = (kpis['total_revenue'] as num?)?.toDouble() ?? 0.0;
      final totalProfit = (kpis['total_profit'] as num?)?.toDouble() ?? 0.0;
      final profitMargin =
          totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0.0;

      Map<String, dynamic> result = {
        'current_period': {
          'total_sales': kpis['total_sales'] as int? ?? 0,
          'unique_customers': kpis['unique_customers'] as int? ?? 0,
          'unique_products_sold': kpis['unique_products_sold'] as int? ?? 0,
          'total_revenue': totalRevenue,
          'total_profit': totalProfit,
          'profit_margin': profitMargin,
          'avg_sale_amount':
              (kpis['avg_sale_amount'] as num?)?.toDouble() ?? 0.0,
          'cash_sales': (kpis['cash_sales'] as num?)?.toDouble() ?? 0.0,
          'credit_sales': (kpis['credit_sales'] as num?)?.toDouble() ?? 0.0,
          'installment_sales':
              (kpis['installment_sales'] as num?)?.toDouble() ?? 0.0,
        },
      };

      // مقارنة مع الفترة السابقة إذا كانت متوفرة
      if (previousFrom != null && previousTo != null) {
        final prevWhere = <String>[];
        final prevArgs = <Object?>[];

        prevWhere.add('s.created_at BETWEEN ? AND ?');
        prevArgs.addAll(
            [previousFrom.toIso8601String(), previousTo.toIso8601String()]);

        final prevWhereClause = 'WHERE ${prevWhere.join(' AND ')}';

        final previousKPIs = await _db.rawQuery('''
          SELECT 
            COUNT(DISTINCT s.id) as total_sales,
            COALESCE(SUM(s.total), 0) as total_revenue,
            COALESCE(SUM(s.profit), 0) as total_profit
          FROM sales s
          $prevWhereClause
        ''', prevArgs);

        final prevKpis = previousKPIs.first;
        final prevRevenue =
            (prevKpis['total_revenue'] as num?)?.toDouble() ?? 0.0;
        final prevProfit =
            (prevKpis['total_profit'] as num?)?.toDouble() ?? 0.0;

        result['previous_period'] = {
          'total_sales': prevKpis['total_sales'] as int? ?? 0,
          'total_revenue': prevRevenue,
          'total_profit': prevProfit,
        };

        // حساب التغييرات
        result['changes'] = {
          'sales_change': prevRevenue > 0
              ? ((totalRevenue - prevRevenue) / prevRevenue) * 100
              : 0.0,
          'profit_change': prevProfit > 0
              ? ((totalProfit - prevProfit) / prevProfit) * 100
              : 0.0,
        };
      }

      return result;
    } catch (e) {
      throw Exception('خطأ في حساب مؤشرات الأداء: $e');
    }
  }

  // Event Log Methods
  Future<int> logEvent({
    required String eventType,
    required String entityType,
    int? entityId,
    int? userId,
    String? username,
    required String description,
    String? details,
    DatabaseExecutor? transaction,
  }) async {
    try {
      // استخدام transaction إذا كان متوفراً، وإلا استخدام _db
      final db = transaction ?? _db;

      // التحقق من وجود الجدول قبل الإدراج (فقط إذا لم يكن transaction)
      if (transaction == null) {
        await _ensureEventLogTable(_db);
      }

      return await db.insert('event_log', {
        'event_type': eventType,
        'entity_type': entityType,
        'entity_id': entityId,
        'user_id': userId,
        'username': username,
        'description': description,
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('خطأ في تسجيل الحدث: $e');
      return 0;
    }
  }

  Future<List<Map<String, Object?>>> getEventLogs({
    String? eventType,
    String? entityType,
    int? userId,
    DateTime? fromDate,
    DateTime? toDate,
    int? limit,
    int? offset,
  }) async {
    try {
      // التحقق من وجود الجدول قبل الاستعلام
      await _ensureEventLogTable(_db);

      final conditions = <String>[];
      final args = <Object?>[];

      if (eventType != null && eventType.isNotEmpty) {
        conditions.add('e.event_type = ?');
        args.add(eventType);
      }

      if (entityType != null && entityType.isNotEmpty) {
        conditions.add('e.entity_type = ?');
        args.add(entityType);
      }

      if (userId != null) {
        conditions.add('e.user_id = ?');
        args.add(userId);
      }

      if (fromDate != null) {
        conditions.add('e.created_at >= ?');
        args.add(fromDate.toIso8601String());
      }

      if (toDate != null) {
        conditions.add('e.created_at <= ?');
        args.add(toDate.toIso8601String());
      }

      final whereClause =
          conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

      var query = '''
        SELECT 
          e.*,
          CASE 
            WHEN u.name IS NOT NULL AND u.name != '' THEN u.name
            WHEN e.username IS NOT NULL AND e.username != '' THEN e.username
            WHEN u.role = 'manager' THEN 'مدير'
            WHEN u.role = 'supervisor' THEN 'مشرف'
            WHEN u.role = 'employee' THEN 'موظف'
            WHEN u.role IS NOT NULL AND u.role != '' THEN u.role
            ELSE 'غير معروف'
          END as user_name,
          u.role as user_role
        FROM event_log e
        LEFT JOIN users u ON e.user_id = u.id
        $whereClause 
        ORDER BY e.created_at DESC
      ''';
      if (limit != null) {
        query += ' LIMIT $limit';
        if (offset != null) {
          query += ' OFFSET $offset';
        }
      }

      final result = await _db.rawQuery(query, args);
      return result;
    } catch (e) {
      // التحقق من وجود الجدول
      try {
        await _db.rawQuery(
            'SELECT name FROM sqlite_master WHERE type="table" AND name="event_log"');
      } catch (_) {
        debugPrint('جدول event_log غير موجود');
      }
      rethrow;
    }
  }

  Future<int> getEventLogCount({
    String? eventType,
    String? entityType,
    int? userId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final conditions = <String>[];
    final args = <Object?>[];

    if (eventType != null && eventType.isNotEmpty) {
      conditions.add('event_type = ?');
      args.add(eventType);
    }

    if (entityType != null && entityType.isNotEmpty) {
      conditions.add('entity_type = ?');
      args.add(entityType);
    }

    if (userId != null) {
      conditions.add('user_id = ?');
      args.add(userId);
    }

    if (fromDate != null) {
      conditions.add('created_at >= ?');
      args.add(fromDate.toIso8601String());
    }

    if (toDate != null) {
      conditions.add('created_at <= ?');
      args.add(toDate.toIso8601String());
    }

    final whereClause =
        conditions.isNotEmpty ? 'WHERE ${conditions.join(' AND ')}' : '';

    final result = await _db.rawQuery(
        'SELECT COUNT(*) as count FROM event_log $whereClause', args);
    return result.first['count'] as int;
  }

  Future<bool> deleteEventLog(int eventId) async {
    try {
      final deletedRows =
          await _db.delete('event_log', where: 'id = ?', whereArgs: [eventId]);
      return deletedRows > 0;
    } catch (e) {
      debugPrint('خطأ في حذف الحدث: $e');
      return false;
    }
  }

  Future<bool> clearEventLogs({DateTime? beforeDate}) async {
    try {
      if (beforeDate != null) {
        final deletedRows = await _db.delete('event_log',
            where: 'created_at < ?', whereArgs: [beforeDate.toIso8601String()]);
        return deletedRows >= 0;
      } else {
        final deletedRows = await _db.delete('event_log');
        return deletedRows >= 0;
      }
    } catch (e) {
      debugPrint('خطأ في مسح سجل الأحداث: $e');
      return false;
    }
  }

  /// مقارنات زمنية: مقارنة المبيعات بين الفترات
  Future<List<Map<String, dynamic>>> getSalesComparison({
    required DateTime period1Start,
    required DateTime period1End,
    required DateTime period2Start,
    required DateTime period2End,
  }) async {
    try {
      return await _db.rawQuery('''
        SELECT 
          'period1' as period,
          COUNT(DISTINCT s.id) as total_sales,
          COUNT(DISTINCT s.customer_id) as unique_customers,
          COALESCE(SUM(s.total), 0) as total_revenue,
          COALESCE(SUM(s.profit), 0) as total_profit,
          COALESCE(AVG(s.total), 0) as avg_sale_amount
        FROM sales s
        WHERE s.created_at BETWEEN ? AND ?
        
        UNION ALL
        
        SELECT 
          'period2' as period,
          COUNT(DISTINCT s.id) as total_sales,
          COUNT(DISTINCT s.customer_id) as unique_customers,
          COALESCE(SUM(s.total), 0) as total_revenue,
          COALESCE(SUM(s.profit), 0) as total_profit,
          COALESCE(AVG(s.total), 0) as avg_sale_amount
        FROM sales s
        WHERE s.created_at BETWEEN ? AND ?
      ''', [
        period1Start.toIso8601String(),
        period1End.toIso8601String(),
        period2Start.toIso8601String(),
        period2End.toIso8601String(),
      ]);
    } catch (e) {
      throw Exception('خطأ في مقارنة المبيعات: $e');
    }
  }

  /// تحليل المبيعات الشهرية للرسوم البيانية
  Future<List<Map<String, dynamic>>> getMonthlySalesTrend({
    int months = 12,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: months * 30));

      return await _db.rawQuery('''
        SELECT 
          strftime('%Y-%m', s.created_at) as month,
          COUNT(DISTINCT s.id) as sales_count,
          COALESCE(SUM(s.total), 0) as total_revenue,
          COALESCE(SUM(s.profit), 0) as total_profit,
          COUNT(DISTINCT s.customer_id) as unique_customers
        FROM sales s
        WHERE s.created_at >= ?
        GROUP BY strftime('%Y-%m', s.created_at)
        ORDER BY month ASC
      ''', [startDate.toIso8601String()]);
    } catch (e) {
      throw Exception('خطأ في جلب اتجاه المبيعات الشهرية: $e');
    }
  }

  // Group Management Methods
  /// الحصول على جميع المجموعات
  Future<List<Map<String, dynamic>>> getAllGroups(
      {bool activeOnly = false}) async {
    try {
      if (activeOnly) {
        return await _db.query('groups', where: 'active = ?', whereArgs: [1]);
      }
      return await _db.query('groups', orderBy: 'name ASC');
    } catch (e) {
      debugPrint('خطأ في جلب المجموعات: $e');
      return [];
    }
  }

  /// الحصول على مجموعة بواسطة المعرف
  Future<Map<String, dynamic>?> getGroupById(int groupId) async {
    try {
      final groups = await _db.query('groups',
          where: 'id = ?', whereArgs: [groupId], limit: 1);
      if (groups.isEmpty) return null;
      return groups.first;
    } catch (e) {
      debugPrint('خطأ في جلب المجموعة: $e');
      return null;
    }
  }

  /// الحصول على الصلاحيات لمجموعة معينة
  Future<Map<SystemSection, List<UserPermission>>> getGroupPermissions(
      int groupId) async {
    try {
      final permissions = await _db.query(
        'group_permissions',
        where: 'group_id = ?',
        whereArgs: [groupId],
      );

      final Map<SystemSection, List<UserPermission>> result = {};

      for (final perm in permissions) {
        final section =
            SystemSection.fromString(perm['section']?.toString() ?? 'system');
        final permName = perm['permission']?.toString() ?? '';

        // Find the permission enum
        UserPermission? permission;
        try {
          permission = UserPermission.values.firstWhere(
            (p) => p.name == permName,
          );
        } catch (e) {
          debugPrint('صلاحية غير معروفة: $permName');
          continue;
        }

        result.putIfAbsent(section, () => []).add(permission);
      }

      return result;
    } catch (e) {
      debugPrint('خطأ في جلب صلاحيات المجموعة: $e');
      return {};
    }
  }

  /// إنشاء مجموعة جديدة
  Future<int> createGroup({
    required String name,
    String? description,
    Map<SystemSection, List<UserPermission>>? permissions,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final groupId = await _db.insert('groups', {
        'name': name,
        'description': description,
        'active': 1,
        'created_at': now,
        'updated_at': now,
      });

      // إضافة الصلاحيات
      if (permissions != null && permissions.isNotEmpty) {
        await _addGroupPermissions(groupId, permissions);
      }

      return groupId;
    } catch (e) {
      debugPrint('خطأ في إنشاء المجموعة: $e');
      rethrow;
    }
  }

  /// تحديث مجموعة
  Future<bool> updateGroup({
    required int groupId,
    String? name,
    String? description,
    bool? active,
    Map<SystemSection, List<UserPermission>>? permissions,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (active != null) updates['active'] = active ? 1 : 0;
      updates['updated_at'] = DateTime.now().toIso8601String();

      if (updates.isNotEmpty) {
        await _db
            .update('groups', updates, where: 'id = ?', whereArgs: [groupId]);
      }

      // تحديث الصلاحيات إذا تم توفيرها
      if (permissions != null) {
        await _db.delete('group_permissions',
            where: 'group_id = ?', whereArgs: [groupId]);
        await _addGroupPermissions(groupId, permissions);
      }

      return true;
    } catch (e) {
      debugPrint('خطأ في تحديث المجموعة: $e');
      return false;
    }
  }

  /// حذف مجموعة
  Future<bool> deleteGroup(int groupId) async {
    try {
      // حذف الصلاحيات المرتبطة (سيتم حذفها تلقائياً بسبب CASCADE)
      await _db.delete('group_permissions',
          where: 'group_id = ?', whereArgs: [groupId]);

      // حذف المجموعة
      final deleted =
          await _db.delete('groups', where: 'id = ?', whereArgs: [groupId]);
      return deleted > 0;
    } catch (e) {
      debugPrint('خطأ في حذف المجموعة: $e');
      return false;
    }
  }

  /// إضافة صلاحيات لمجموعة
  Future<void> _addGroupPermissions(
    int groupId,
    Map<SystemSection, List<UserPermission>> permissions,
  ) async {
    final now = DateTime.now().toIso8601String();
    final batch = _db.batch();

    for (final entry in permissions.entries) {
      final section = entry.key;
      for (final permission in entry.value) {
        batch.insert('group_permissions', {
          'group_id': groupId,
          'section': section.value,
          'permission': permission.name,
          'created_at': now,
        });
      }
    }

    await batch.commit(noResult: true);
  }

  /// الحصول على المجموعة الخاصة بمستخدم
  Future<GroupModel?> getUserGroup(int userId) async {
    try {
      final users = await _db.query('users',
          where: 'id = ?', whereArgs: [userId], limit: 1);
      if (users.isEmpty) return null;

      final groupIdObj = users.first['group_id'];
      if (groupIdObj == null) return null;
      final groupId =
          (groupIdObj is int) ? groupIdObj : (groupIdObj as num?)?.toInt();
      if (groupId == null) return null;

      final groupData = await getGroupById(groupId);
      if (groupData == null) return null;

      final permissions = await getGroupPermissions(groupId);
      return GroupModel.fromMap(groupData).copyWith(permissions: permissions);
    } catch (e) {
      debugPrint('خطأ في جلب مجموعة المستخدم: $e');
      return null;
    }
  }

  /// تحديث مجموعة المستخدم
  Future<bool> updateUserGroup(int userId, int groupId) async {
    try {
      await _db.update(
        'users',
        {'group_id': groupId, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [userId],
      );
      return true;
    } catch (e) {
      debugPrint('خطأ في تحديث مجموعة المستخدم: $e');
      return false;
    }
  }

  // ==================== دوال سلة المحذوفات ====================

  /// حذف مؤقت لعنصر (soft delete)
  Future<int> softDeleteItem({
    required String entityType,
    required int entityId,
    required Map<String, dynamic> originalData,
    int? userId,
    String? username,
    String? name,
  }) async {
    return _db.transaction<int>((txn) async {
      // حفظ البيانات الأصلية في جدول deleted_items
      final deletedItemId = await txn.insert('deleted_items', {
        'entity_type': entityType,
        'entity_id': entityId,
        'original_data': jsonEncode(originalData),
        'deleted_by_user_id': userId,
        'deleted_by_username': username,
        'deleted_by_name': name,
        'deleted_at': DateTime.now().toIso8601String(),
        'can_restore': 1,
      });

      // حذف العنصر من الجدول الأصلي
      String tableName;
      switch (entityType) {
        case 'customer':
          tableName = 'customers';
          break;
        case 'sale':
          tableName = 'sales';
          break;
        case 'installment':
          tableName = 'installments';
          break;
        case 'payment':
          tableName = 'payments';
          break;
        case 'product':
          tableName = 'products';
          break;
        case 'expense':
          tableName = 'expenses';
          break;
        default:
          throw Exception('نوع العنصر غير مدعوم: $entityType');
      }

      await txn.delete(tableName, where: 'id = ?', whereArgs: [entityId]);

      return deletedItemId;
    });
  }

  /// الحصول على جميع العناصر المحذوفة
  Future<List<Map<String, dynamic>>> getDeletedItems({
    String? entityType,
    int? limit,
  }) async {
    final where = <String>[];
    final args = <Object?>[];

    if (entityType != null) {
      where.add('di.entity_type = ?');
      args.add(entityType);
    }

    final sql = '''
      SELECT 
        di.*,
        u.name as user_name,
        u.username as user_username,
        u.role as user_role
      FROM deleted_items di
      LEFT JOIN users u ON di.deleted_by_user_id = u.id
      ${where.isNotEmpty ? 'WHERE ${where.join(' AND ')}' : ''}
      ORDER BY di.deleted_at DESC
      ${limit != null ? 'LIMIT $limit' : ''}
    ''';

    final results = await _db.rawQuery(sql, args);
    return results.map((row) {
      final data = row['original_data'] as String;
      return {
        ...row,
        'original_data': jsonDecode(data),
      };
    }).toList();
  }

  /// استرجاع عنصر محذوف
  Future<bool> restoreDeletedItem(int deletedItemId) async {
    return _db.transaction<bool>((txn) async {
      // الحصول على بيانات العنصر المحذوف
      final deletedItem = await txn.query('deleted_items',
          where: 'id = ?', whereArgs: [deletedItemId], limit: 1);

      if (deletedItem.isEmpty) {
        throw Exception('العنصر المحذوف غير موجود');
      }

      final item = deletedItem.first;
      final entityType = item['entity_type'] as String;
      final originalDataStr = item['original_data'] as String;
      final originalData = jsonDecode(originalDataStr) as Map<String, dynamic>;
      final canRestore = (item['can_restore'] as int) == 1;

      if (!canRestore) {
        throw Exception('لا يمكن استرجاع هذا العنصر');
      }

      // تحديد اسم الجدول
      String tableName;
      switch (entityType) {
        case 'customer':
          tableName = 'customers';
          break;
        case 'sale':
          tableName = 'sales';
          break;
        case 'installment':
          tableName = 'installments';
          break;
        case 'payment':
          tableName = 'payments';
          break;
        case 'product':
          tableName = 'products';
          break;
        case 'expense':
          tableName = 'expenses';
          break;
        default:
          throw Exception('نوع العنصر غير مدعوم: $entityType');
      }

      // إعادة إدراج العنصر في الجدول الأصلي
      await txn.insert(tableName, originalData);

      // تحديث دين العميل عند استرجاع الأقساط أو المدفوعات
      if (entityType == 'installment') {
        // عند استرجاع قسط، يجب تقليل دين العميل
        final saleId = originalData['sale_id'] as int;
        final amount = (originalData['amount'] as num).toDouble();

        final sale = await txn.query('sales',
            where: 'id = ?', whereArgs: [saleId], limit: 1);
        if (sale.isNotEmpty && sale.first['customer_id'] != null) {
          final customerId = sale.first['customer_id'] as int;
          await txn.rawUpdate(
            'UPDATE customers SET total_debt = MAX(IFNULL(total_debt, 0) - ?, 0) WHERE id = ?',
            [amount, customerId],
          );
        }
      } else if (entityType == 'payment') {
        // عند استرجاع مدفوعة، يجب زيادة دين العميل
        final customerId = originalData['customer_id'] as int;
        final amount = (originalData['amount'] as num).toDouble();
        await txn.rawUpdate(
          'UPDATE customers SET total_debt = IFNULL(total_debt, 0) + ? WHERE id = ?',
          [amount, customerId],
        );
      } else if (entityType == 'sale') {
        // عند استرجاع بيع من نوع credit، يجب زيادة دين العميل
        if (originalData['type'] == 'credit' &&
            originalData['customer_id'] != null) {
          final customerId = originalData['customer_id'] as int;
          final total = (originalData['total'] as num).toDouble();
          await txn.rawUpdate(
            'UPDATE customers SET total_debt = IFNULL(total_debt, 0) + ? WHERE id = ?',
            [total, customerId],
          );
        }
      }

      // حذف العنصر من جدول deleted_items
      await txn
          .delete('deleted_items', where: 'id = ?', whereArgs: [deletedItemId]);

      return true;
    });
  }

  /// حذف نهائي لعنصر من سلة المحذوفات
  Future<bool> permanentlyDeleteItem(int deletedItemId) async {
    final deletedRows = await _db
        .delete('deleted_items', where: 'id = ?', whereArgs: [deletedItemId]);
    return deletedRows > 0;
  }

  /// حذف جميع العناصر المحذوفة نهائياً
  Future<int> permanentlyDeleteAllItems({String? entityType}) async {
    if (entityType != null) {
      return await _db.delete('deleted_items',
          where: 'entity_type = ?', whereArgs: [entityType]);
    } else {
      return await _db.delete('deleted_items');
    }
  }

  /// الحصول على عدد العناصر المحذوفة
  Future<Map<String, int>> getDeletedItemsCount() async {
    final result = await _db.rawQuery('''
      SELECT entity_type, COUNT(*) as count
      FROM deleted_items
      GROUP BY entity_type
    ''');

    final counts = <String, int>{};
    for (final row in result) {
      counts[row['entity_type'] as String] = row['count'] as int;
    }

    return counts;
  }

  /// التأكد من وجود جدول deleted_items
  Future<void> _ensureDeletedItemsTable(DatabaseExecutor db) async {
    try {
      // التحقق من وجود الجدول
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='deleted_items'");

      if (tables.isEmpty) {
        debugPrint('جدول deleted_items غير موجود، جاري إنشاؤه...');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS deleted_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entity_type TEXT NOT NULL,
            entity_id INTEGER NOT NULL,
            original_data TEXT NOT NULL,
            deleted_by_user_id INTEGER,
            deleted_by_username TEXT,
            deleted_by_name TEXT,
            deleted_at TEXT NOT NULL,
            can_restore INTEGER NOT NULL DEFAULT 1,
            FOREIGN KEY(deleted_by_user_id) REFERENCES users(id)
          );
        ''');

        // إنشاء الفهارس
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_deleted_items_entity_type ON deleted_items(entity_type)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_deleted_items_deleted_at ON deleted_items(deleted_at)');

        debugPrint('تم إنشاء جدول deleted_items بنجاح');
      } else {
        // التحقق من وجود عمود deleted_by_name وإضافته إذا لم يكن موجوداً
        try {
          final columns = await db.rawQuery("PRAGMA table_info(deleted_items)");
          final hasDeletedByName = columns.any(
              (col) => (col['name']?.toString() ?? '') == 'deleted_by_name');

          if (!hasDeletedByName) {
            debugPrint('إضافة عمود deleted_by_name إلى جدول deleted_items...');
            await db.execute(
                'ALTER TABLE deleted_items ADD COLUMN deleted_by_name TEXT');
            debugPrint('تم إضافة عمود deleted_by_name بنجاح');
          }
        } catch (e) {
          debugPrint('خطأ في التحقق من/إضافة عمود deleted_by_name: $e');
        }
      }
    } catch (e) {
      // لا نرمي الخطأ هنا لأن الجدول قد يكون موجوداً بالفعل
    }
  }

  // ==================== نظام الخصومات والكوبونات ====================

  /// الحصول على خصم منتج نشط
  Future<Map<String, Object?>?> getActiveProductDiscount(int productId) async {
    final now = DateTime.now().toIso8601String();
    final discounts = await _db.query(
      'product_discounts',
      where:
          'product_id = ? AND active = 1 AND (start_date IS NULL OR start_date <= ?) AND (end_date IS NULL OR end_date >= ?)',
      whereArgs: [productId, now, now],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    return discounts.isNotEmpty ? discounts.first : null;
  }

  /// الحصول على جميع خصومات المنتجات
  Future<List<Map<String, Object?>>> getProductDiscounts(
      {int? productId}) async {
    final where = <String>[];
    final args = <Object?>[];

    if (productId != null) {
      where.add('pd.product_id = ?');
      args.add(productId);
    }

    return _db.rawQuery('''
      SELECT pd.*, p.name as product_name
      FROM product_discounts pd
      LEFT JOIN products p ON pd.product_id = p.id
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
      ORDER BY pd.created_at DESC
    ''', where.isEmpty ? null : args);
  }

  /// إضافة خصم منتج
  Future<int> insertProductDiscount(Map<String, Object?> values) async {
    if (values['product_id'] == null) {
      throw Exception('معرف المنتج مطلوب');
    }
    if (values['discount_percent'] == null &&
        values['discount_amount'] == null) {
      throw Exception('يجب تحديد نسبة أو مبلغ الخصم');
    }

    values['created_at'] = DateTime.now().toIso8601String();
    return _db.insert('product_discounts', values);
  }

  /// تحديث خصم منتج
  Future<void> updateProductDiscount(
      int id, Map<String, Object?> values) async {
    values['updated_at'] = DateTime.now().toIso8601String();
    await _db
        .update('product_discounts', values, where: 'id = ?', whereArgs: [id]);
  }

  /// حذف خصم منتج
  Future<void> deleteProductDiscount(int id) async {
    await _db.delete('product_discounts', where: 'id = ?', whereArgs: [id]);
  }

  /// الحصول على جميع الكوبونات
  Future<List<Map<String, Object?>>> getDiscountCoupons(
      {bool? activeOnly}) async {
    final where = <String>[];
    final args = <Object?>[];

    if (activeOnly == true) {
      where.add('active = 1');
    }

    return _db.query(
      'discount_coupons',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: where.isEmpty ? null : args,
      orderBy: 'created_at DESC',
    );
  }

  /// الحصول على كوبون بالكود
  Future<Map<String, Object?>?> getDiscountCouponByCode(String code) async {
    final coupons = await _db.query(
      'discount_coupons',
      where: 'code = ?',
      whereArgs: [code.toUpperCase()],
      limit: 1,
    );
    return coupons.isNotEmpty ? coupons.first : null;
  }

  /// التحقق من صحة الكوبون وتطبيقه
  Future<Map<String, Object?>> validateAndApplyCoupon(
    String code,
    double totalAmount,
  ) async {
    final coupon = await getDiscountCouponByCode(code);

    if (coupon == null) {
      throw Exception('كوبون غير صحيح');
    }

    final active = (coupon['active'] as int?) ?? 0;
    if (active != 1) {
      throw Exception('الكوبون غير مفعّل');
    }

    // التحقق من تاريخ البداية والنهاية
    final now = DateTime.now();
    if (coupon['start_date'] != null) {
      final startDate = DateTime.parse(coupon['start_date'] as String);
      if (now.isBefore(startDate)) {
        throw Exception('الكوبون لم يبدأ بعد');
      }
    }
    if (coupon['end_date'] != null) {
      final endDate = DateTime.parse(coupon['end_date'] as String);
      if (now.isAfter(endDate)) {
        throw Exception('الكوبون منتهي الصلاحية');
      }
    }

    // التحقق من حد الاستخدام
    final usageLimit = coupon['usage_limit'] as int?;
    final usedCount = (coupon['used_count'] as int?) ?? 0;
    if (usageLimit != null && usedCount >= usageLimit) {
      throw Exception('تم الوصول إلى حد استخدام الكوبون');
    }

    // التحقق من الحد الأدنى للشراء
    final minPurchase =
        (coupon['min_purchase_amount'] as num?)?.toDouble() ?? 0.0;
    if (totalAmount < minPurchase) {
      throw Exception(
          'يجب أن يكون إجمالي الشراء على الأقل ${minPurchase.toStringAsFixed(2)}');
    }

    // حساب الخصم
    final discountType = coupon['discount_type'] as String;
    final discountValue = (coupon['discount_value'] as num).toDouble();
    double discountAmount = 0.0;

    if (discountType == 'percent') {
      discountAmount = totalAmount * (discountValue / 100);
      final maxDiscount = (coupon['max_discount_amount'] as num?)?.toDouble();
      if (maxDiscount != null && discountAmount > maxDiscount) {
        discountAmount = maxDiscount;
      }
    } else {
      discountAmount = discountValue;
      if (discountAmount > totalAmount) {
        discountAmount = totalAmount;
      }
    }

    return {
      'coupon_id': coupon['id'],
      'coupon_code': code,
      'discount_amount': discountAmount,
      'coupon': coupon,
    };
  }

  /// زيادة عدد استخدامات الكوبون
  Future<void> incrementCouponUsage(int couponId) async {
    await _db.rawUpdate(
      'UPDATE discount_coupons SET used_count = used_count + 1 WHERE id = ?',
      [couponId],
    );
  }

  /// إضافة كوبون خصم
  Future<int> insertDiscountCoupon(Map<String, Object?> values) async {
    if (values['code'] == null || (values['code'] as String).trim().isEmpty) {
      throw Exception('كود الكوبون مطلوب');
    }
    if (values['name'] == null || (values['name'] as String).trim().isEmpty) {
      throw Exception('اسم الكوبون مطلوب');
    }
    if (values['discount_type'] == null) {
      throw Exception('نوع الخصم مطلوب');
    }
    if (values['discount_value'] == null) {
      throw Exception('قيمة الخصم مطلوبة');
    }

    // تحويل الكود إلى أحرف كبيرة
    values['code'] = (values['code'] as String).toUpperCase().trim();

    // التحقق من عدم تكرار الكود
    final existing = await getDiscountCouponByCode(values['code'] as String);
    if (existing != null) {
      throw Exception('كود الكوبون موجود بالفعل');
    }

    values['created_at'] = DateTime.now().toIso8601String();
    return _db.insert('discount_coupons', values);
  }

  /// تحديث كوبون خصم
  Future<void> updateDiscountCoupon(int id, Map<String, Object?> values) async {
    if (values['code'] != null) {
      values['code'] = (values['code'] as String).toUpperCase().trim();
      // التحقق من عدم تكرار الكود
      final existing = await getDiscountCouponByCode(values['code'] as String);
      if (existing != null && existing['id'] != id) {
        throw Exception('كود الكوبون موجود بالفعل');
      }
    }

    values['updated_at'] = DateTime.now().toIso8601String();
    await _db
        .update('discount_coupons', values, where: 'id = ?', whereArgs: [id]);
  }

  /// حذف كوبون خصم
  Future<void> deleteDiscountCoupon(int id) async {
    await _db.delete('discount_coupons', where: 'id = ?', whereArgs: [id]);
  }

  /// حذف جميع البيانات من جميع جداول قاعدة البيانات مع الحفاظ على بنيتها
  ///
  /// - يمسح محتوى جميع الجداول (ما عدا جداول النظام الداخلية الخاصة بـ SQLite)
  /// - لا يقوم بحذف الجداول نفسها
  /// - يعطّل قيود المفاتيح الخارجية مؤقتًا أثناء الحذف لتفادي تعارض القيود
  /// - بعد الحذف يعيد التأكد من وجود المستخدمين الافتراضيين
  Future<void> deleteAllDataHardReset() async {
    debugPrint('deleteAllDataHardReset: بدء عملية حذف جميع البيانات...');

    // قائمة الجداول التي نريد تفريغها (بدون حذفها)
    const tablesToClear = <String>[
      'categories',
      'products',
      'customers',
      'suppliers',
      'sales',
      'sale_items',
      'installments',
      'expenses',
      'payments',
      'supplier_payments',
      'event_log',
      'deleted_items',
      'product_discounts',
      'discount_coupons',
      'returns',
      // يمكن إضافة جداول أخرى هنا عند الحاجة
    ];

    try {
      // إيقاف المفاتيح الخارجية على مستوى القاعدة
      await _db.execute('PRAGMA foreign_keys = OFF');

      await _db.transaction((txn) async {
        for (final table in tablesToClear) {
          try {
            await txn.execute('DELETE FROM $table');
          } catch (e) {
            // نتجاهل الخطأ إذا لم يكن الجدول موجوداً، ونكمل
            debugPrint('deleteAllDataHardReset: فشل مسح جدول $table: $e');
          }
        }

        // إعادة تعيين عداد الـ AUTOINCREMENT للجداول المعروفة
        try {
          await txn.execute(
            "DELETE FROM sqlite_sequence WHERE name IN (${tablesToClear.map((t) => "'$t'").join(', ')})",
          );
        } catch (e) {
          debugPrint(
              'deleteAllDataHardReset: فشل إعادة تعيين sqlite_sequence: $e');
        }
      });

      // إعادة تفعيل المفاتيح الخارجية
      await _db.execute('PRAGMA foreign_keys = ON');

      // التأكد من وجود المستخدمين الافتراضيين بعد الحذف الكامل
      await _checkAndFixDefaultUsers();

      debugPrint('deleteAllDataHardReset: انتهت عملية حذف جميع البيانات بنجاح');
    } catch (e) {
      // في حالة أي خطأ، نحاول إعادة تفعيل المفاتيح الخارجية ثم نرمي الاستثناء
      try {
        await _db.execute('PRAGMA foreign_keys = ON');
      } catch (_) {}

      debugPrint('deleteAllDataHardReset: خطأ عام في الحذف: $e');
      rethrow;
    }
  }
}
