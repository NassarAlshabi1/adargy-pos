import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Helper functions for database operations
class DatabaseHelpers {
  /// التحقق من وجود عمود في جدول
  static Future<bool> columnExists(
      Database db, String tableName, String columnName) async {
    try {
      final columns = await db.rawQuery("PRAGMA table_info('$tableName')");
      return columns.any((col) => col['name']?.toString() == columnName);
    } catch (e) {
      return false;
    }
  }

  /// التحقق من وجود جدول
  static Future<bool> tableExists(Database db, String tableName) async {
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

  /// إنشاء جميع الفهارس المطلوبة
  static Future<void> createIndexes(Database db) async {
    // Products
    if (await tableExists(db, 'products')) {
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_products_name ON products(name)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode)');
      if (await columnExists(db, 'products', 'category_id')) {
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id)');
      }
    }

    // Sales
    if (await tableExists(db, 'sales')) {
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_sales_created_at ON sales(created_at)');
      if (await columnExists(db, 'sales', 'customer_id')) {
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_sales_customer ON sales(customer_id)');
      }
      await db
          .execute('CREATE INDEX IF NOT EXISTS idx_sales_type ON sales(type)');
    }

    // Sale items
    if (await tableExists(db, 'sale_items')) {
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON sale_items(sale_id)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_sale_items_product ON sale_items(product_id)');
    }

    // Customers
    if (await tableExists(db, 'customers')) {
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone)');
    }

    // Payments
    if (await tableExists(db, 'payments')) {
      if (await columnExists(db, 'payments', 'customer_id')) {
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_payments_customer ON payments(customer_id)');
      }
      if (await columnExists(db, 'payments', 'payment_date')) {
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_payments_date ON payments(payment_date)');
      }
    }

    // Expenses
    if (await tableExists(db, 'expenses')) {
      // التحقق من وجود عمود expense_date قبل إنشاء الفهرس
      if (await columnExists(db, 'expenses', 'expense_date')) {
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(expense_date)');
      }
      // التحقق من وجود عمود category قبل إنشاء الفهرس
      if (await columnExists(db, 'expenses', 'category')) {
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category)');
      }
    }

    // Event Log
    if (await tableExists(db, 'event_log')) {
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_event_log_created_at ON event_log(created_at)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_event_log_event_type ON event_log(event_type)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_event_log_entity_type ON event_log(entity_type)');
      if (await columnExists(db, 'event_log', 'user_id')) {
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_event_log_user_id ON event_log(user_id)');
      }
    }
  }
}
