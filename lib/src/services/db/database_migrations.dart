import 'package:sqflite/sqflite.dart';

/// ملف يحتوي على جميع دوال الترحيل (Migrations) لقاعدة البيانات
class DatabaseMigrations {
  /// تشغيل جميع الترحيلات المطلوبة
  static Future<void> runMigrations(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await migrateToV2(db);
    }
    if (oldVersion < 3) {
      await migrateToV3(db);
    }
    if (oldVersion < 4) {
      await migrateToV4(db);
    }
    if (oldVersion < 5) {
      await migrateToV5(db);
    }
    if (oldVersion < 6) {
      await migrateToV6(db);
    }
    if (oldVersion < 7) {
      await migrateToV7(db);
    }
    if (oldVersion < 8) {
      await migrateToV8(db);
    }
    if (oldVersion < 9) {
      await migrateToV9(db);
    }
    if (oldVersion < 10) {
      await migrateToV10(db);
    }
    if (oldVersion < 11) {
      await migrateToV11(db);
    }
    if (oldVersion < 12) {
      await migrateToV12(db);
    }
    if (oldVersion < 13) {
      await migrateToV13(db);
    }
    if (oldVersion < 14) {
      await migrateToV14(db);
    }
    if (oldVersion < 15) {
      await migrateToV15(db);
    }
  }

  static Future<void> migrateToV2(Database db) async {
    // SQLite cannot directly alter CHECK constraints. Recreate sales table.
    await db.execute('PRAGMA foreign_keys=off');
    await db.execute('ALTER TABLE sales RENAME TO sales_old');
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER,
        total REAL NOT NULL,
        profit REAL NOT NULL DEFAULT 0,
        type TEXT NOT NULL CHECK(type IN ('cash','installment','credit')),
        created_at TEXT NOT NULL,
        FOREIGN KEY(customer_id) REFERENCES customers(id)
      );
    ''');
    await db.execute('''
      INSERT INTO sales (id, customer_id, total, profit, type, created_at)
      SELECT id, customer_id, total, profit, type, created_at FROM sales_old;
    ''');
    await db.execute('DROP TABLE sales_old');
    await db.execute('PRAGMA foreign_keys=on');
  }

  static Future<void> migrateToV3(Database db) async {
    // Add due_date to sales for credit tracking
    try {
      await db.execute('ALTER TABLE sales ADD COLUMN due_date TEXT');
    } catch (e) {
      // تجاهل الخطأ إذا كان العمود موجوداً بالفعل
    }
  }

  static Future<void> migrateToV4(Database db) async {
    // Add payments table for debt collection
    await db.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(customer_id) REFERENCES customers(id)
      );
    ''');
  }

  static Future<void> migrateToV5(Database db) async {
    // Add address field to settings table
    try {
      await db.execute('ALTER TABLE settings ADD COLUMN address TEXT');
    } catch (_) {
      // column already exists
    }
  }

  static Future<void> migrateToV6(Database db) async {
    // Add down_payment field to sales table for installments
    try {
      await db
          .execute('ALTER TABLE sales ADD COLUMN down_payment REAL DEFAULT 0');
    } catch (_) {
      // column already exists
    }
  }

  static Future<void> migrateToV7(Database db) async {
    // تحديث جدول المستخدمين لدعم النظام الجديد
    try {
      // إعادة إنشاء جدول المستخدمين لدعم supervisor
      await db.execute('PRAGMA foreign_keys=off');

      // إنشاء جدول مؤقت
      await db.execute('''
        CREATE TABLE users_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          username TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL,
          role TEXT NOT NULL CHECK(role IN ('manager','supervisor','employee')),
          employee_code TEXT UNIQUE NOT NULL,
          active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        );
      ''');

      // نسخ البيانات الموجودة
      await db.execute('''
        INSERT INTO users_new (id, name, username, password, role, employee_code, active, created_at, updated_at)
        SELECT 
          id, 
          name, 
          username, 
          password, 
          role,
          COALESCE(employee_code, 'LEGACY' || id) as employee_code,
          active,
          COALESCE(created_at, datetime('now')) as created_at,
          datetime('now') as updated_at
        FROM users;
      ''');

      // حذف الجدول القديم
      await db.execute('DROP TABLE users');

      // إعادة تسمية الجدول الجديد
      await db.execute('ALTER TABLE users_new RENAME TO users');

      await db.execute('PRAGMA foreign_keys=on');

      // تحديث البيانات الموجودة
      final now = DateTime.now().toIso8601String();
      final existingUsers = await db.query('users');

      for (final user in existingUsers) {
        await db.update(
            'users',
            {
              'employee_code': user['employee_code'] ?? 'LEGACY001',
              'created_at': user['created_at'] ?? now,
              'updated_at': now,
            },
            where: 'id = ?',
            whereArgs: [user['id']]);
      }
    } catch (e) {
      // تجاهل خطأ Migration V7
    }
  }

  static Future<void> migrateToV8(Database db) async {
    // إصلاح جدول المستخدمين لدعم supervisor
    try {
      // إعادة إنشاء جدول المستخدمين لدعم supervisor
      await db.execute('PRAGMA foreign_keys=off');

      // إنشاء جدول مؤقت
      await db.execute('''
        CREATE TABLE users_new (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          username TEXT UNIQUE NOT NULL,
          password TEXT NOT NULL,
          role TEXT NOT NULL CHECK(role IN ('manager','supervisor','employee')),
          employee_code TEXT UNIQUE NOT NULL,
          active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        );
      ''');

      // نسخ البيانات الموجودة
      await db.execute('''
        INSERT INTO users_new (id, name, username, password, role, employee_code, active, created_at, updated_at)
        SELECT 
          id, 
          name, 
          username, 
          password, 
          role,
          COALESCE(employee_code, 'LEGACY' || id) as employee_code,
          active,
          COALESCE(created_at, datetime('now')) as created_at,
          datetime('now') as updated_at
        FROM users;
      ''');

      // حذف الجدول القديم
      await db.execute('DROP TABLE users');

      // إعادة تسمية الجدول الجديد
      await db.execute('ALTER TABLE users_new RENAME TO users');

      await db.execute('PRAGMA foreign_keys=on');
    } catch (e) {
      // تجاهل خطأ Migration V8
    }
  }

  static Future<void> migrateToV9(Database db) async {
    // تحديث جدول المصروفات لإضافة حقول جديدة
    try {
      // التحقق من وجود الأعمدة الجديدة
      final cols = await db.rawQuery("PRAGMA table_info('expenses')");
      final columnNames = cols.map((c) => c['name']?.toString() ?? '').toList();

      // إضافة الأعمدة الجديدة إذا لم تكن موجودة
      if (!columnNames.contains('category')) {
        await db.execute(
            'ALTER TABLE expenses ADD COLUMN category TEXT NOT NULL DEFAULT \'عام\'');
      }

      if (!columnNames.contains('description')) {
        await db.execute('ALTER TABLE expenses ADD COLUMN description TEXT');
      }

      if (!columnNames.contains('expense_date')) {
        // إضافة عمود expense_date واستخدام created_at كقيمة افتراضية
        await db.execute('ALTER TABLE expenses ADD COLUMN expense_date TEXT');
        // نسخ created_at إلى expense_date للبيانات الموجودة
        await db.execute(
            'UPDATE expenses SET expense_date = created_at WHERE expense_date IS NULL');
        // جعل الحقل NOT NULL بعد نسخ البيانات
        await db.execute('''
          CREATE TABLE expenses_new (
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
          INSERT INTO expenses_new (id, title, amount, category, description, expense_date, created_at, updated_at)
          SELECT id, title, amount, COALESCE(category, 'عام'), description, COALESCE(expense_date, created_at), created_at, COALESCE(updated_at, created_at)
          FROM expenses;
        ''');
        await db.execute('DROP TABLE expenses');
        await db.execute('ALTER TABLE expenses_new RENAME TO expenses');
        // تحديث columnNames بعد إعادة إنشاء الجدول
        final newCols = await db.rawQuery("PRAGMA table_info('expenses')");
        final newColumnNames =
            newCols.map((c) => c['name']?.toString() ?? '').toList();
        columnNames.clear();
        columnNames.addAll(newColumnNames);
      }

      // التحقق مرة أخرى من updated_at بعد إعادة إنشاء الجدول
      if (!columnNames.contains('updated_at')) {
        try {
          await db.execute('ALTER TABLE expenses ADD COLUMN updated_at TEXT');
        } catch (e) {
          // تجاهل الخطأ إذا كان العمود موجوداً بالفعل
        }
      }
    } catch (e) {
      // تجاهل خطأ Migration V9
    }
  }

  static Future<void> migrateToV10(Database db) async {
    // إضافة جدول event_log لتسجيل جميع العمليات
    try {
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
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_event_log_created_at ON event_log(created_at)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_event_log_event_type ON event_log(event_type)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_event_log_entity_type ON event_log(entity_type)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_event_log_user_id ON event_log(user_id)');
    } catch (e) {
      // تجاهل خطأ Migration V10
    }
  }

  static Future<void> migrateToV11(Database db) async {
    // إضافة جدول returns للمرتجعات (هيكل موحّد مع DatabaseSchema)
    try {
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
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_returns_sale_id ON returns(sale_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_returns_status ON returns(status)');
    } catch (e) {
      // تجاهل خطأ Migration V11
    }
  }

  static Future<void> migrateToV12(Database db) async {
    // إضافة نظام المجموعات والصلاحيات
    try {
      // 1. إنشاء جدول groups
      await db.execute('''
        CREATE TABLE IF NOT EXISTS groups (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE,
          description TEXT,
          active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        );
      ''');

      // 2. إنشاء جدول group_permissions
      await db.execute('''
        CREATE TABLE IF NOT EXISTS group_permissions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          group_id INTEGER NOT NULL,
          section TEXT NOT NULL,
          permission TEXT NOT NULL,
          created_at TEXT NOT NULL,
          FOREIGN KEY(group_id) REFERENCES groups(id) ON DELETE CASCADE,
          UNIQUE(group_id, section, permission)
        );
      ''');

      // 3. إضافة عمود group_id إلى جدول users
      try {
        await db.execute(
            'ALTER TABLE users ADD COLUMN group_id INTEGER REFERENCES groups(id)');
      } catch (e) {
        // تجاهل الخطأ إذا كان العمود موجوداً بالفعل
      }

      // 4. إنشاء المجموعات الافتراضية
      final now = DateTime.now().toIso8601String();

      // مجموعة المدير (Admin)
      final adminGroupId = await db.insert('groups', {
        'name': 'Admin',
        'description': 'مجموعة المديرين - جميع الصلاحيات',
        'active': 1,
        'created_at': now,
        'updated_at': now,
      });

      // مجموعة الموظفين (Employee)
      final employeeGroupId = await db.insert('groups', {
        'name': 'Employee',
        'description': 'مجموعة الموظفين - صلاحيات محدودة',
        'active': 1,
        'created_at': now,
        'updated_at': now,
      });

      // مجموعة HR
      final hrGroupId = await db.insert('groups', {
        'name': 'HR',
        'description': 'مجموعة الموارد البشرية',
        'active': 1,
        'created_at': now,
        'updated_at': now,
      });

      // 5. إضافة الصلاحيات للمجموعات
      // صلاحيات مجموعة Admin (جميع الصلاحيات)
      final allPermissions = [
        'manageUsers',
        'systemSettings',
        'manageBackup',
        'manageLicensing',
        'manageSales',
        'applyDiscount',
        'overridePrice',
        'refundSales',
        'voidSale',
        'deleteSaleItem',
        'openCashDrawer',
        'manageProducts',
        'manageInventory',
        'adjustStock',
        'viewCostPrice',
        'editCostPrice',
        'receivePurchase',
        'manageSuppliers',
        'manageCategories',
        'manageCustomers',
        'viewReports',
        'exportReports',
        'viewProfitCosts',
      ];

      // تعيين الصلاحيات لمجموعة Admin
      for (final perm in allPermissions) {
        // تحديد القسم لكل صلاحية
        String section = 'system';
        if (perm.startsWith('manageUsers')) {
          section = 'hr';
        } else if (perm.contains('Sales') ||
            perm.contains('Discount') ||
            perm.contains('Price') ||
            perm.contains('refund') ||
            perm.contains('void') ||
            perm.contains('CashDrawer') ||
            perm.contains('Customers')) {
          section = 'sales';
        } else if (perm.contains('Product') ||
            perm.contains('Inventory') ||
            perm.contains('Stock') ||
            perm.contains('Cost') ||
            perm.contains('Purchase') ||
            perm.contains('Supplier') ||
            perm.contains('Categor')) {
          section = 'inventory';
        } else if (perm.contains('Report') || perm.contains('Profit')) {
          section = 'reports';
        } else if (perm.contains('Backup') ||
            perm.contains('Licensing') ||
            perm.contains('Settings')) {
          section = 'system';
        } else if (perm.contains('Profit')) {
          section = 'finance';
        }

        await db.insert('group_permissions', {
          'group_id': adminGroupId,
          'section': section,
          'permission': perm,
          'created_at': now,
        });
      }

      // صلاحيات مجموعة Employee (مبيعات وتقارير محدودة)
      final employeePermissions = [
        {'section': 'sales', 'permission': 'manageSales'},
        {'section': 'reports', 'permission': 'viewReports'},
      ];

      for (final perm in employeePermissions) {
        await db.insert('group_permissions', {
          'group_id': employeeGroupId,
          'section': perm['section'],
          'permission': perm['permission'],
          'created_at': now,
        });
      }

      // صلاحيات مجموعة HR
      final hrPermissions = [
        {'section': 'hr', 'permission': 'manageUsers'},
        {'section': 'reports', 'permission': 'viewReports'},
      ];

      for (final perm in hrPermissions) {
        await db.insert('group_permissions', {
          'group_id': hrGroupId,
          'section': perm['section'],
          'permission': perm['permission'],
          'created_at': now,
        });
      }

      // 6. تحديث المستخدمين الموجودين لربطهم بالمجموعات المناسبة
      final users = await db.query('users');
      for (final user in users) {
        final role = user['role']?.toString() ?? 'employee';
        int? groupId;

        if (role == 'manager') {
          groupId = adminGroupId;
        } else if (role == 'employee') {
          groupId = employeeGroupId;
        } else if (role == 'supervisor') {
          // المشرفون ينتقلون لمجموعة Admin (يمكن تغيير ذلك لاحقاً)
          groupId = adminGroupId;
        }

        if (groupId != null) {
          await db.update(
            'users',
            {'group_id': groupId},
            where: 'id = ?',
            whereArgs: [user['id']],
          );
        }
      }

      // 7. إنشاء الفهارس
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_users_group_id ON users(group_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_group_permissions_group_id ON group_permissions(group_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_group_permissions_section ON group_permissions(section)');
    } catch (e) {
      // تجاهل خطأ Migration V12
    }
  }

  static Future<void> migrateToV13(Database db) async {
    // إضافة حقل status إلى جدول returns
    try {
      // التحقق من وجود العمود أولاً
      final columns = await db.rawQuery("PRAGMA table_info(returns)");
      final columnNames =
          columns.map((c) => c['name']?.toString().toLowerCase()).toSet();

      if (!columnNames.contains('status')) {
        await db.execute(
            'ALTER TABLE returns ADD COLUMN status TEXT NOT NULL DEFAULT \'pending\'');
      }

      // إنشاء فهرس على status
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_returns_status ON returns(status)');
    } catch (e) {
      // تجاهل خطأ Migration V13
    }
  }

  static Future<void> migrateToV14(Database db) async {
    // إضافة جدول deleted_items لسلة المحذوفات
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS deleted_items (
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
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_deleted_items_entity_type ON deleted_items(entity_type)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_deleted_items_deleted_at ON deleted_items(deleted_at)');
    } catch (e) {
      // تجاهل خطأ Migration V14
    }
  }

  static Future<void> migrateToV15(Database db) async {
    // إضافة نظام الخصومات والكوبونات
    try {
      // إضافة حقول الكوبون إلى جدول sales
      try {
        await db.execute('ALTER TABLE sales ADD COLUMN coupon_id INTEGER');
        await db.execute(
            'ALTER TABLE sales ADD COLUMN coupon_discount REAL DEFAULT 0');
      } catch (e) {
        // تجاهل الخطأ إذا كانت الأعمدة موجودة بالفعل
      }

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
      // تجاهل خطأ Migration V15
    }
  }
}
