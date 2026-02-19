// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/db/database_service.dart';
import '../utils/format.dart';
import '../utils/export.dart';
import '../utils/dark_mode_utils.dart';
import '../services/print_service.dart';
import '../services/store_config.dart';

class InventoryReportsScreen extends StatefulWidget {
  const InventoryReportsScreen({super.key});

  @override
  State<InventoryReportsScreen> createState() => _InventoryReportsScreenState();
}

class _InventoryReportsScreenState extends State<InventoryReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'تقارير الجرد الشاملة',
          style: TextStyle(color: Colors.blue),
        ),
        backgroundColor:
            isDark ? scheme.surface : Color(0xFFFFFFFF), // Professional White
        foregroundColor: isDark ? scheme.onSurface : Colors.black,
        actions: [
          IconButton(
            icon: Icon(
              Icons.picture_as_pdf,
              color: Colors.deepOrange,
            ),
            tooltip: 'تصدير PDF',
            onPressed: () => _exportCurrentTab(),
          ),
          IconButton(
            icon: Icon(
              Icons.print,
              color: Colors.blue,
            ),
            tooltip: 'طباعة التقرير',
            onPressed: () => _printCurrentTab(),
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.green,
            ),
            onPressed: () {
              if (mounted) {
                setState(() {}); // تحديث الواجهة
              }
            },
            tooltip: 'تحديث البيانات',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: isDark ? scheme.primary : Colors.black,
          unselectedLabelColor:
              isDark ? scheme.onSurface.withOpacity(0.7) : Colors.grey,
          indicatorColor: isDark ? scheme.primary : Colors.black,
          tabs: const [
            Tab(text: 'ملخص الجرد', icon: Icon(Icons.inventory)),
            Tab(text: 'الأكثر مبيعاً', icon: Icon(Icons.trending_up)),
            Tab(text: 'بطيء الحركة', icon: Icon(Icons.trending_down)),
            Tab(text: 'تحليل المخزون', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInventorySummaryTab(),
          _buildTopSellingTab(),
          _buildSlowMovingTab(),
          _buildInventoryAnalysisTab(),
        ],
      ),
    );
  }

  Widget _buildInventorySummaryTab() {
    final db = context.read<DatabaseService>();

    return FutureBuilder<Map<String, dynamic>>(
      future: db.getInventoryReport(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error,
                    size: 64, color: DarkModeUtils.getErrorColor(context)),
                const SizedBox(height: 16),
                Text('خطأ في تحميل البيانات: ${snapshot.error}'),
              ],
            ),
          );
        }

        final data = snapshot.data ?? {};
        final totalProducts = data['total_products'] as int? ?? 0;
        final totalQuantity = data['total_quantity'] as int? ?? 0;
        final totalValue = data['total_value'] as double? ?? 0.0;
        final totalCost = data['total_cost'] as double? ?? 0.0;
        final inventoryTurnover = data['inventory_turnover'] as double? ?? 0.0;
        final lowStockCount = data['low_stock_count'] as int? ?? 0;
        final outOfStockCount = data['out_of_stock_count'] as int? ?? 0;

        // إذا كانت البيانات فارغة، اعرض رسالة توضيحية
        if (totalProducts == 0 && totalQuantity == 0 && totalValue == 0.0) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2,
                    size: 64,
                    color: DarkModeUtils.getSecondaryTextColor(context)),
                const SizedBox(height: 16),
                Text(
                  'لا توجد منتجات في المخزون',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: DarkModeUtils.getSecondaryTextColor(context),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'قم بإضافة منتجات لرؤية تقارير الجرد',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: DarkModeUtils.getSecondaryTextColor(context),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportHeader('ملخص الجرد الشامل'),
              const SizedBox(height: 12),

              // مؤشرات الجرد الرئيسية
              Row(
                children: [
                  Expanded(
                    child: _buildPerformanceCard(
                      'إجمالي المنتجات',
                      totalProducts.toString(),
                      'منتج',
                      Colors.blue,
                      Icons.inventory,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPerformanceCard(
                      'إجمالي الكمية',
                      totalQuantity.toString(),
                      'وحدة',
                      Colors.green,
                      Icons.shopping_cart,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildPerformanceCard(
                      'القيمة الإجمالية',
                      Formatters.currencyIQD(totalValue),
                      '',
                      Colors.orange,
                      Icons.account_balance_wallet,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildPerformanceCard(
                      'التكلفة الإجمالية',
                      Formatters.currencyIQD(totalCost),
                      '',
                      Colors.red,
                      Icons.money_off,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // مؤشرات الأداء
              Row(
                children: [
                  Expanded(
                    child: _buildPerformanceCard(
                      'معدل دوران المخزون',
                      inventoryTurnover.toStringAsFixed(2),
                      'مرة',
                      Colors.purple,
                      Icons.rotate_right,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildPerformanceCard(
                      'منخفض الكمية',
                      lowStockCount.toString(),
                      'منتج',
                      Colors.amber,
                      Icons.warning,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _buildPerformanceCard(
                      'نفد من المخزون',
                      outOfStockCount.toString(),
                      'منتج',
                      Colors.red,
                      Icons.error,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildPerformanceCard(
                      'هامش الربح',
                      totalValue > 0
                          ? '${((totalValue - totalCost) / totalValue * 100).toStringAsFixed(1)}%'
                          : '0%',
                      '',
                      Colors.green,
                      Icons.trending_up,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // مخطط توزيع المخزون
              _buildInventoryDistributionChart(
                  totalValue, totalCost, lowStockCount, outOfStockCount),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopSellingTab() {
    final db = context.read<DatabaseService>();

    return FutureBuilder<Map<String, dynamic>>(
      future: db.getInventoryReport(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error,
                    size: 64, color: DarkModeUtils.getErrorColor(context)),
                const SizedBox(height: 16),
                Text('خطأ في تحميل البيانات: ${snapshot.error}'),
              ],
            ),
          );
        }

        final data = snapshot.data ?? {};
        final topSellingProducts =
            data['top_selling_products'] as List<dynamic>? ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportHeader('المنتجات الأكثر مبيعاً (آخر 30 يوم)'),
              const SizedBox(height: 20),
              if (topSellingProducts.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.shopping_cart,
                          size: 64,
                          color: DarkModeUtils.getSecondaryTextColor(context)),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد بيانات مبيعات في آخر 30 يوم',
                        style: TextStyle(
                          fontSize: 16,
                          color: DarkModeUtils.getSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                )
              else
                _buildTopSellingTable(topSellingProducts),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSlowMovingTab() {
    final db = context.read<DatabaseService>();

    return FutureBuilder<Map<String, dynamic>>(
      future: db.getInventoryReport(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error,
                    size: 64, color: DarkModeUtils.getErrorColor(context)),
                const SizedBox(height: 16),
                Text('خطأ في تحميل البيانات: ${snapshot.error}'),
              ],
            ),
          );
        }

        final data = snapshot.data ?? {};
        final slowMovingProducts =
            data['slow_moving_products'] as List<dynamic>? ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportHeader('المنتجات بطيئة الحركة (آخر 90 يوم)'),
              const SizedBox(height: 20),
              if (slowMovingProducts.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.trending_down,
                          size: 64,
                          color: DarkModeUtils.getSecondaryTextColor(context)),
                      const SizedBox(height: 16),
                      Text(
                        'جميع المنتجات تتحرك بشكل جيد',
                        style: TextStyle(
                          fontSize: 16,
                          color: DarkModeUtils.getSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                )
              else
                _buildSlowMovingTable(slowMovingProducts),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInventoryAnalysisTab() {
    final db = context.read<DatabaseService>();

    return FutureBuilder<Map<String, dynamic>>(
      future: db.getInventoryReport(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error,
                    size: 64, color: DarkModeUtils.getErrorColor(context)),
                const SizedBox(height: 16),
                Text('خطأ في تحميل البيانات: ${snapshot.error}'),
              ],
            ),
          );
        }

        final data = snapshot.data ?? {};
        final totalValue = data['total_value'] as double? ?? 0.0;
        final totalCost = data['total_cost'] as double? ?? 0.0;
        final lowStockCount = data['low_stock_count'] as int? ?? 0;
        final outOfStockCount = data['out_of_stock_count'] as int? ?? 0;
        final totalProducts = data['total_products'] as int? ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportHeader('تحليل المخزون المتقدم'),
              const SizedBox(height: 20),

              // تحليل القيمة
              _buildAnalysisCard(
                'تحليل القيمة',
                [
                  'القيمة الإجمالية: ${Formatters.currencyIQD(totalValue)}',
                  'التكلفة الإجمالية: ${Formatters.currencyIQD(totalCost)}',
                  'الربح المحتمل: ${Formatters.currencyIQD(totalValue - totalCost)}',
                  'هامش الربح: ${totalValue > 0 ? ((totalValue - totalCost) / totalValue * 100).toStringAsFixed(1) : 0}%',
                ],
                Colors.blue,
                Icons.account_balance_wallet,
              ),

              const SizedBox(height: 16),

              // تحليل الكمية
              _buildAnalysisCard(
                'تحليل الكمية',
                [
                  'إجمالي المنتجات: $totalProducts',
                  'منخفض الكمية: $lowStockCount (${totalProducts > 0 ? (lowStockCount / totalProducts * 100).toStringAsFixed(1) : 0}%)',
                  'نفد من المخزون: $outOfStockCount (${totalProducts > 0 ? (outOfStockCount / totalProducts * 100).toStringAsFixed(1) : 0}%)',
                  'مخزون صحي: ${totalProducts - lowStockCount - outOfStockCount}',
                ],
                Colors.green,
                Icons.inventory,
              ),

              const SizedBox(height: 20),

              // مخطط تحليل المخزون
              _buildInventoryAnalysisChart(
                  totalProducts, lowStockCount, outOfStockCount),

              const SizedBox(height: 20),

              // توصيات
              _buildRecommendationsCard(
                  lowStockCount, outOfStockCount, totalProducts),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportHeader(String title) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory,
              color: Theme.of(context).colorScheme.onPrimary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatDateForDisplay(DateTime.now()),
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withOpacity(0.85),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(
      String title, String value, String unit, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: DarkModeUtils.createCardDecoration(context),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: DarkModeUtils.getSecondaryTextColor(context),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '$value $unit',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(
      String title, List<String> items, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DarkModeUtils.createCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTopSellingTable(List<dynamic> products) {
    return Container(
      decoration: DarkModeUtils.createCardDecoration(context),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('المنتج')),
            DataColumn(label: Text('الباركود')),
            DataColumn(label: Text('الكمية المباعة')),
            DataColumn(label: Text('إجمالي الإيرادات')),
          ],
          rows: products.map((product) {
            return DataRow(
              cells: [
                DataCell(Text(product['name'] as String? ?? '')),
                DataCell(Text(product['barcode'] as String? ?? '')),
                DataCell(Text('${product['total_sold']}')),
                DataCell(Text(Formatters.currencyIQD(
                    product['total_revenue'] as double? ?? 0.0))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSlowMovingTable(List<dynamic> products) {
    return Container(
      decoration: DarkModeUtils.createCardDecoration(context),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('المنتج')),
            DataColumn(label: Text('الباركود')),
            DataColumn(label: Text('الكمية المتاحة')),
            DataColumn(label: Text('السعر')),
            DataColumn(label: Text('التكلفة')),
          ],
          rows: products.map((product) {
            return DataRow(
              cells: [
                DataCell(Text(product['name'] as String? ?? '')),
                DataCell(Text(product['barcode'] as String? ?? '')),
                DataCell(Text('${product['quantity']}')),
                DataCell(Text(Formatters.currencyIQD(
                    product['price'] as double? ?? 0.0))),
                DataCell(Text(
                    Formatters.currencyIQD(product['cost'] as double? ?? 0.0))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInventoryDistributionChart(
      double totalValue, double totalCost, int lowStock, int outOfStock) {
    final scheme = Theme.of(context).colorScheme;
    final profit = totalValue - totalCost;

    // حساب النسب المئوية
    final costPercent = totalValue > 0
        ? (totalCost / totalValue * 100).toStringAsFixed(1)
        : '0.0';
    final profitPercent =
        totalValue > 0 ? (profit / totalValue * 100).toStringAsFixed(1) : '0.0';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: DarkModeUtils.createCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'توزيع قيمة المخزون',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          // القيمة الإجمالية
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: scheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'القيمة الإجمالية',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  Formatters.currencyIQD(totalValue),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // التكلفة
          _buildProgressBarItem(
            'التكلفة',
            totalCost,
            totalValue,
            costPercent,
            Colors.red,
          ),
          const SizedBox(height: 12),
          // الربح
          _buildProgressBarItem(
            'الربح',
            profit,
            totalValue,
            profitPercent,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBarItem(
      String label, double value, double total, String percent, Color color,
      {bool isCount = false}) {
    final scheme = Theme.of(context).colorScheme;
    final percentage = total > 0 ? (value / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isCount
                      ? '${value.toInt()} منتج'
                      : Formatters.currencyIQD(value),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: scheme.outline.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryAnalysisChart(
      int totalProducts, int lowStock, int outOfStock) {
    final healthyStock = totalProducts - lowStock - outOfStock;
    final scheme = Theme.of(context).colorScheme;

    // حساب النسب المئوية
    final healthyPercent = totalProducts > 0
        ? (healthyStock / totalProducts * 100).toStringAsFixed(1)
        : '0.0';
    final lowPercent = totalProducts > 0
        ? (lowStock / totalProducts * 100).toStringAsFixed(1)
        : '0.0';
    final outPercent = totalProducts > 0
        ? (outOfStock / totalProducts * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: DarkModeUtils.createCardDecoration(context),
      child: Column(
        children: [
          Text(
            'تحليل حالة المخزون',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          // إجمالي المنتجات
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: scheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'إجمالي المنتجات',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  '$totalProducts منتج',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // مخزون صحي
          _buildProgressBarItem(
            'مخزون صحي',
            healthyStock.toDouble(),
            totalProducts.toDouble(),
            healthyPercent,
            Colors.green,
            isCount: true,
          ),
          const SizedBox(height: 12),
          // منخفض الكمية
          _buildProgressBarItem(
            'منخفض الكمية',
            lowStock.toDouble(),
            totalProducts.toDouble(),
            lowPercent,
            Colors.orange,
            isCount: true,
          ),
          const SizedBox(height: 12),
          // نفد من المخزون
          _buildProgressBarItem(
            'نفد من المخزون',
            outOfStock.toDouble(),
            totalProducts.toDouble(),
            outPercent,
            Colors.red,
            isCount: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(
      int lowStock, int outOfStock, int totalProducts) {
    final recommendations = <String>[];

    if (outOfStock > 0) {
      recommendations.add('إعادة توريد $outOfStock منتج نفد من المخزون فوراً');
    }

    if (lowStock > 0) {
      recommendations.add('مراجعة $lowStock منتج منخفض الكمية');
    }

    if (recommendations.isEmpty) {
      recommendations.add('المخزون في حالة ممتازة');
    }

    recommendations.add('مراجعة دورية للمخزون كل أسبوع');
    recommendations.add('تحديد مستويات إعادة التوريد لكل منتج');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: DarkModeUtils.createCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb,
                  color: DarkModeUtils.getWarningColor(context), size: 24),
              const SizedBox(width: 8),
              const Text(
                'التوصيات',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendations.map((recommendation) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        size: 16,
                        color: DarkModeUtils.getSuccessColor(context)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recommendation,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _formatDateForDisplay(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatDateForFilename(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _exportCurrentTab() async {
    final currentIndex = _tabController.index;
    final db = context.read<DatabaseService>();
    String? savedPath;

    try {
      switch (currentIndex) {
        case 0: // ملخص الجرد
          savedPath = await _exportInventorySummary(db);
          break;
        case 1: // الأكثر مبيعاً
          savedPath = await _exportTopSelling(db);
          break;
        case 2: // بطيء الحركة
          savedPath = await _exportSlowMoving(db);
          break;
        case 3: // تحليل المخزون
          savedPath = await _exportInventoryAnalysis(db);
          break;
      }

      if (savedPath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حفظ التقرير في: $savedPath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التصدير: $e')),
        );
      }
    }
  }

  Future<String?> _exportInventorySummary(DatabaseService db) async {
    final data = await db.getInventoryReport();
    final items = <MapEntry<String, String>>[
      MapEntry('إجمالي المنتجات', '${data['total_products'] ?? 0} منتج'),
      MapEntry('إجمالي الكمية', '${data['total_quantity'] ?? 0} وحدة'),
      MapEntry('القيمة الإجمالية',
          Formatters.currencyIQD(data['total_value'] ?? 0.0)),
      MapEntry('التكلفة الإجمالية',
          Formatters.currencyIQD(data['total_cost'] ?? 0.0)),
      MapEntry('معدل دوران المخزون',
          '${(data['inventory_turnover'] ?? 0.0).toStringAsFixed(2)} مرة'),
      MapEntry('منخفض الكمية', '${data['low_stock_count'] ?? 0} منتج'),
      MapEntry('نفد من المخزون', '${data['out_of_stock_count'] ?? 0} منتج'),
      MapEntry('هامش الربح',
          '${(data['profit_margin'] ?? 0.0).toStringAsFixed(1)}%'),
    ];

    final now = DateTime.now();
    final dateStr = _formatDateForFilename(now);
    return await PdfExporter.exportKeyValue(
      filename: 'ملخص_الجرد_$dateStr.pdf',
      title: 'ملخص الجرد الشامل - ${_formatDateForDisplay(now)}',
      items: items,
    );
  }

  Future<String?> _exportTopSelling(DatabaseService db) async {
    final data = await db.getInventoryReport();
    final topSelling = data['top_selling_products'] as List<dynamic>? ?? [];

    final rows = <List<String>>[
      ['المنتج', 'الكمية المباعة', 'القيمة'],
      ...topSelling.map((product) => [
            product['name'] as String? ?? '',
            '${product['total_sold'] ?? 0}',
            Formatters.currencyIQD(product['total_revenue'] ?? 0.0),
          ]),
    ];

    final now = DateTime.now();
    final dateStr = _formatDateForFilename(now);
    return await PdfExporter.exportDataTable(
      filename: 'الأكثر_مبيعاً_$dateStr.pdf',
      title: 'المنتجات الأكثر مبيعاً - ${_formatDateForDisplay(now)}',
      headers: ['المنتج', 'الكمية المباعة', 'القيمة'],
      rows: rows,
    );
  }

  Future<String?> _exportSlowMoving(DatabaseService db) async {
    final data = await db.getInventoryReport();
    final slowMoving = data['slow_moving_products'] as List<dynamic>? ?? [];

    final rows = <List<String>>[
      ['المنتج', 'الباركود', 'الكمية المتاحة', 'السعر', 'التكلفة'],
      ...slowMoving.map((product) => [
            product['name'] as String? ?? '',
            product['barcode'] as String? ?? '',
            '${product['quantity'] ?? 0}',
            Formatters.currencyIQD(product['price'] ?? 0.0),
            Formatters.currencyIQD(product['cost'] ?? 0.0),
          ]),
    ];

    final now = DateTime.now();
    final dateStr = _formatDateForFilename(now);
    return await PdfExporter.exportDataTable(
      filename: 'بطيء_الحركة_$dateStr.pdf',
      title: 'المنتجات بطيئة الحركة - ${_formatDateForDisplay(now)}',
      headers: ['المنتج', 'الباركود', 'الكمية المتاحة', 'السعر', 'التكلفة'],
      rows: rows,
    );
  }

  Future<String?> _exportInventoryAnalysis(DatabaseService db) async {
    final data = await db.getInventoryReport();
    final items = <MapEntry<String, String>>[
      MapEntry('إجمالي المنتجات', '${data['total_products'] ?? 0} منتج'),
      MapEntry('إجمالي الكمية', '${data['total_quantity'] ?? 0} وحدة'),
      MapEntry('القيمة الإجمالية',
          Formatters.currencyIQD(data['total_value'] ?? 0.0)),
      MapEntry('التكلفة الإجمالية',
          Formatters.currencyIQD(data['total_cost'] ?? 0.0)),
      MapEntry('معدل دوران المخزون',
          '${(data['inventory_turnover'] ?? 0.0).toStringAsFixed(2)} مرة'),
      MapEntry('منخفض الكمية', '${data['low_stock_count'] ?? 0} منتج'),
      MapEntry('نفد من المخزون', '${data['out_of_stock_count'] ?? 0} منتج'),
      MapEntry('هامش الربح',
          '${(data['profit_margin'] ?? 0.0).toStringAsFixed(1)}%'),
    ];

    final now = DateTime.now();
    final dateStr = _formatDateForFilename(now);
    return await PdfExporter.exportKeyValue(
      filename: 'تحليل_المخزون_$dateStr.pdf',
      title: 'تحليل المخزون الشامل - ${_formatDateForDisplay(now)}',
      items: items,
    );
  }

  // دالة الطباعة
  Future<void> _printCurrentTab() async {
    final currentIndex = _tabController.index;
    final db = context.read<DatabaseService>();
    final storeConfig = context.read<StoreConfig>();

    try {
      switch (currentIndex) {
        case 0: // ملخص الجرد
          await _printInventorySummary(db, storeConfig);
          break;
        case 1: // الأكثر مبيعاً
          await _printTopSelling(db, storeConfig);
          break;
        case 2: // بطيء الحركة
          await _printSlowMoving(db, storeConfig);
          break;
        case 3: // تحليل المخزون
          await _printInventoryAnalysis(db, storeConfig);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الطباعة: $e')),
        );
      }
    }
  }

  Future<void> _printInventorySummary(
      DatabaseService db, StoreConfig storeConfig) async {
    final data = await db.getInventoryReport();
    final items = <MapEntry<String, String>>[
      MapEntry('إجمالي المنتجات', '${data['total_products'] ?? 0} منتج'),
      MapEntry('إجمالي الكمية', '${data['total_quantity'] ?? 0} وحدة'),
      MapEntry('القيمة الإجمالية',
          Formatters.currencyIQD(data['total_value'] ?? 0.0)),
      MapEntry('التكلفة الإجمالية',
          Formatters.currencyIQD(data['total_cost'] ?? 0.0)),
      MapEntry('معدل دوران المخزون',
          '${(data['inventory_turnover'] ?? 0.0).toStringAsFixed(2)} مرة'),
      MapEntry('منخفض الكمية', '${data['low_stock_count'] ?? 0} منتج'),
      MapEntry('نفد من المخزون', '${data['out_of_stock_count'] ?? 0} منتج'),
    ];

    await PrintService.printInventoryReport(
      reportType: 'ملخص_الجرد',
      title: 'ملخص الجرد الشامل',
      items: items,
      reportDate: DateTime.now(),
      shopName: storeConfig.shopName,
      phone: storeConfig.phone,
      address: storeConfig.address,
      context: context,
    );
  }

  Future<void> _printTopSelling(
      DatabaseService db, StoreConfig storeConfig) async {
    final data = await db.getInventoryReport();
    final topSelling = data['top_selling_products'] as List<dynamic>? ?? [];

    final headers = ['المنتج', 'الكمية المباعة', 'القيمة'];
    final rows = topSelling
        .map((product) => [
              product['name'] as String? ?? '',
              '${product['total_sold'] ?? 0}',
              Formatters.currencyIQD(product['total_revenue'] ?? 0.0),
            ])
        .toList();

    await PrintService.printTableReport(
      reportType: 'الأكثر_مبيعاً',
      title: 'المنتجات الأكثر مبيعاً',
      headers: headers,
      rows: rows,
      reportDate: DateTime.now(),
      shopName: storeConfig.shopName,
      phone: storeConfig.phone,
      address: storeConfig.address,
      context: context,
    );
  }

  Future<void> _printSlowMoving(
      DatabaseService db, StoreConfig storeConfig) async {
    final data = await db.getInventoryReport();
    final slowMoving = data['slow_moving_products'] as List<dynamic>? ?? [];

    final headers = [
      'المنتج',
      'الباركود',
      'الكمية المتاحة',
      'السعر',
      'التكلفة'
    ];
    final rows = slowMoving
        .map((product) => [
              product['name'] as String? ?? '',
              product['barcode'] as String? ?? '',
              '${product['quantity'] ?? 0}',
              Formatters.currencyIQD(product['price'] ?? 0.0),
              Formatters.currencyIQD(product['cost'] ?? 0.0),
            ])
        .toList();

    await PrintService.printTableReport(
      reportType: 'بطيء_الحركة',
      title: 'المنتجات بطيئة الحركة',
      headers: headers,
      rows: rows,
      reportDate: DateTime.now(),
      shopName: storeConfig.shopName,
      phone: storeConfig.phone,
      address: storeConfig.address,
      context: context,
    );
  }

  Future<void> _printInventoryAnalysis(
      DatabaseService db, StoreConfig storeConfig) async {
    final data = await db.getInventoryReport();
    final items = <MapEntry<String, String>>[
      MapEntry('إجمالي المنتجات', '${data['total_products'] ?? 0} منتج'),
      MapEntry('إجمالي الكمية', '${data['total_quantity'] ?? 0} وحدة'),
      MapEntry('القيمة الإجمالية',
          Formatters.currencyIQD(data['total_value'] ?? 0.0)),
      MapEntry('التكلفة الإجمالية',
          Formatters.currencyIQD(data['total_cost'] ?? 0.0)),
      MapEntry('معدل دوران المخزون',
          '${(data['inventory_turnover'] ?? 0.0).toStringAsFixed(2)} مرة'),
      MapEntry('منخفض الكمية', '${data['low_stock_count'] ?? 0} منتج'),
      MapEntry('نفد من المخزون', '${data['out_of_stock_count'] ?? 0} منتج'),
      MapEntry('هامش الربح',
          '${(data['profit_margin'] ?? 0.0).toStringAsFixed(1)}%'),
    ];

    await PrintService.printInventoryReport(
      reportType: 'تحليل_المخزون',
      title: 'تحليل المخزون الشامل',
      items: items,
      reportDate: DateTime.now(),
      shopName: storeConfig.shopName,
      phone: storeConfig.phone,
      address: storeConfig.address,
      context: context,
    );
  }
}
