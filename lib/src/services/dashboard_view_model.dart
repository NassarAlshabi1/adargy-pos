import 'package:flutter/foundation.dart';
import 'db/database_service.dart';

/// مزود حالة لوحة التحكم (Dashboard)
/// يقوم بتحميل إحصاءات المبيعات والمنتجات والعملاء من قاعدة البيانات
/// ويعرضها على الشاشة بشكل مجمّع.
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel(this._databaseService);

  final DatabaseService _databaseService;

  /// حالة التحميل العامة للشاشة
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// آخر خطأ حدث أثناء التحميل (إن وجد)
  Object? _error;
  Object? get error => _error;

  /// إجمالي مبيعات اليوم والأرباح
  double _todaySales = 0;
  double get todaySales => _todaySales;

  double _todayProfit = 0;
  double get todayProfit => _todayProfit;

  /// إجمالي مبيعات الشهر والأرباح
  double _monthlySales = 0;
  double get monthlySales => _monthlySales;

  double _monthlyProfit = 0;
  double get monthlyProfit => _monthlyProfit;

  /// إحصاءات المنتجات والمخزون
  int _totalProducts = 0;
  int get totalProducts => _totalProducts;

  int _availableProductsCount = 0;
  int get availableProductsCount => _availableProductsCount;

  int _totalProductQuantity = 0;
  int get totalProductQuantity => _totalProductQuantity;

  /// أعداد العملاء والمورّدين
  int _totalCustomers = 0;
  int get totalCustomers => _totalCustomers;

  int _totalSuppliers = 0;
  int get totalSuppliers => _totalSuppliers;

  /// عدد الأصناف منخفضة المخزون
  int _lowStockCount = 0;
  int get lowStockCount => _lowStockCount;

  /// إحصاءات الديون
  double _totalDebt = 0;
  double get totalDebt => _totalDebt;

  double _overdueDebt = 0;
  double get overdueDebt => _overdueDebt;

  int _customersWithDebt = 0;
  int get customersWithDebt => _customersWithDebt;

  /// بيانات العرض: آخر المبيعات، أفضل المنتجات، المنتجات منخفضة المخزون
  List<Map<String, dynamic>> _recentSales = const [];
  List<Map<String, dynamic>> get recentSales => _recentSales;

  List<Map<String, dynamic>> _topProducts = const [];
  List<Map<String, dynamic>> get topProducts => _topProducts;

  List<Map<String, dynamic>> _lowStockProducts = const [];
  List<Map<String, dynamic>> get lowStockProducts => _lowStockProducts;

  /// تحميل جميع المؤشرات من قاعدة البيانات وتحديث الواجهة
  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final db = _databaseService.database;
      final today =
          DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
      final currentMonth =
          DateTime.now().toIso8601String().substring(0, 7); // YYYY-MM

      final todaySales = await db.rawQuery(
          "SELECT IFNULL(SUM(total),0) as t, IFNULL(SUM(profit),0) as p FROM sales WHERE substr(created_at,1,10)=?",
          [today]);

      final monthSales = await db.rawQuery(
          "SELECT IFNULL(SUM(total),0) as t, IFNULL(SUM(profit),0) as p FROM sales WHERE substr(created_at,1,7)=?",
          [currentMonth]);

      final products = await db
          .rawQuery("SELECT COUNT(*) as c FROM products"); // إجمالي الأصناف
      final availableProducts = await db.rawQuery(
          "SELECT COUNT(*) as c FROM products WHERE quantity > 0"); // أصناف متوفرة
      final totalQty = await db.rawQuery(
          "SELECT IFNULL(SUM(quantity),0) as q FROM products"); // إجمالي الكميات
      final customers =
          await db.rawQuery("SELECT COUNT(*) as c FROM customers");
      final suppliers =
          await db.rawQuery("SELECT COUNT(*) as c FROM suppliers");
      final lowStock = await db.rawQuery(
          "SELECT COUNT(*) as c FROM products WHERE quantity <= min_quantity"); // أصناف منخفضة المخزون

      final recentSales = await db.rawQuery('''
        SELECT p.name, p.price, si.quantity, si.price as sale_price, s.created_at
        FROM sale_items si
        JOIN products p ON si.product_id = p.id
        JOIN sales s ON si.sale_id = s.id
        ORDER BY s.created_at DESC 
        LIMIT 8
      ''');

      final topProducts = await db.rawQuery(
          "SELECT p.name, p.quantity, p.price FROM products p ORDER BY p.quantity DESC LIMIT 5"); // أعلى أصناف كميةً (استرشادي)

      final lowStockProducts = await db.rawQuery(
          "SELECT name, quantity, min_quantity FROM products WHERE quantity <= min_quantity LIMIT 5"); // عينات من الأصناف منخفضة المخزون

      final debtStats = await _databaseService.getDebtStatistics();

      _todaySales = (todaySales.first['t'] as num).toDouble();
      _todayProfit = (todaySales.first['p'] as num).toDouble();
      _monthlySales = (monthSales.first['t'] as num).toDouble();
      _monthlyProfit = (monthSales.first['p'] as num).toDouble();
      _totalProducts = (products.first['c'] as int);
      _availableProductsCount = (availableProducts.first['c'] as int);
      _totalProductQuantity = (totalQty.first['q'] as num).toInt();
      _totalCustomers = (customers.first['c'] as int);
      _totalSuppliers = (suppliers.first['c'] as int);
      _lowStockCount = (lowStock.first['c'] as int);
      _recentSales = recentSales;
      _topProducts = topProducts;
      _lowStockProducts = lowStockProducts;
      _totalDebt = debtStats['total_debt']!;
      _overdueDebt = debtStats['overdue_debt']!;
      _customersWithDebt = debtStats['customers_with_debt']!.toInt();
    } catch (e) {
      // حفظ الخطأ لعرضه في الواجهة/التتبّع
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
