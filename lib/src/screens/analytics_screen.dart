// ignore_for_file: use_build_context_synchronously

import 'dart:ui' as ui show TextDirection;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/db/database_service.dart';
import '../services/auth/auth_provider.dart';
import '../models/user_model.dart';
import '../utils/format.dart';
import '../utils/export.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _fromDate;
  DateTime? _toDate;
  int _selectedMonths = 6;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    // تعيين الفترة الافتراضية
    _toDate = DateTime.now();
    _fromDate = DateTime.now().subtract(Duration(days: 30));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.hasPermission(UserPermission.viewReports)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('التحليلات'),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'ليس لديك صلاحية للوصول إلى هذه الصفحة',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('التحليلات والتحليلات'),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.picture_as_pdf,
                color: Colors.deepOrange,
              ),
              tooltip: 'تصدير PDF',
              onPressed: () => _exportCurrentTab(),
            ),
            IconButton(
              icon: const Icon(Icons.date_range),
              onPressed: _showDateRangePicker,
              tooltip: 'اختيار الفترة',
            ),
            PopupMenuButton<int>(
              tooltip: 'عدد الأشهر',
              icon: const Icon(Icons.timeline),
              onSelected: (value) {
                setState(() {
                  _selectedMonths = value;
                  _toDate = DateTime.now();
                  _fromDate =
                      DateTime.now().subtract(Duration(days: value * 30));
                });
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 1, child: Text('آخر شهر')),
                const PopupMenuItem(value: 3, child: Text('آخر 3 أشهر')),
                const PopupMenuItem(value: 6, child: Text('آخر 6 أشهر')),
                const PopupMenuItem(value: 12, child: Text('آخر سنة')),
              ],
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.analytics), text: 'مؤشرات الأداء'),
              Tab(icon: Icon(Icons.shopping_bag), text: 'تحليل المبيعات'),
              Tab(icon: Icon(Icons.people), text: 'تحليل العملاء'),
              Tab(icon: Icon(Icons.warning), text: 'التنبؤ بالطلب'),
              Tab(icon: Icon(Icons.compare_arrows), text: 'مقارنات زمنية'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildKPIsTab(),
            _buildSalesAnalysisTab(),
            _buildCustomersAnalysisTab(),
            _buildDemandForecastTab(),
            _buildTimeComparisonTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      future: context.read<DatabaseService>().getSalesKPIs(
            from: _fromDate,
            to: _toDate,
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('خطأ: ${snapshot.error}'),
              ],
            ),
          );
        }

        final kpis = snapshot.data?['current_period'] ?? {};
        final changes = snapshot.data?['changes'];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بطاقات KPIs الرئيسية
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  int crossAxisCount;
                  double aspectRatio;

                  if (width < 600) {
                    crossAxisCount = 2;
                    aspectRatio = 1.3;
                  } else if (width < 1024) {
                    crossAxisCount = 2;
                    aspectRatio = 1.5;
                  } else if (width < 1440) {
                    crossAxisCount = 4;
                    aspectRatio = 1.8;
                  } else {
                    crossAxisCount = 4;
                    aspectRatio = 2.0;
                  }

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: aspectRatio,
                    children: [
                      _KPICard(
                        title: 'إجمالي المبيعات',
                        value: '${kpis['total_sales'] ?? 0}',
                        subtitle: 'عملية بيع',
                        color: Colors.blue,
                        icon: Icons.shopping_cart,
                        change: changes?['sales_change'],
                      ),
                      _KPICard(
                        title: 'إجمالي الإيرادات',
                        value: Formatters.currencyIQD(
                            (kpis['total_revenue'] as num?)?.toDouble() ?? 0.0),
                        subtitle: 'دينار عراقي',
                        color: Colors.green,
                        icon: Icons.trending_up,
                        change: changes?['sales_change'],
                      ),
                      _KPICard(
                        title: 'إجمالي الأرباح',
                        value: Formatters.currencyIQD(
                            (kpis['total_profit'] as num?)?.toDouble() ?? 0.0),
                        subtitle:
                            'معدل الربح: ${(kpis['profit_margin'] as num?)?.toStringAsFixed(1) ?? '0'}%',
                        color: Colors.teal,
                        icon: Icons.account_balance_wallet,
                        change: changes?['profit_change'],
                      ),
                      _KPICard(
                        title: 'متوسط قيمة البيع',
                        value: Formatters.currencyIQD(
                            (kpis['avg_sale_amount'] as num?)?.toDouble() ??
                                0.0),
                        subtitle: 'دينار عراقي',
                        color: Colors.orange,
                        icon: Icons.attach_money,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              // تفاصيل إضافية
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تفاصيل إضافية',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(
                        label: 'عدد العملاء',
                        value: '${kpis['unique_customers'] ?? 0}',
                        icon: Icons.people,
                      ),
                      _DetailRow(
                        label: 'عدد المنتجات المباعة',
                        value: '${kpis['unique_products_sold'] ?? 0}',
                        icon: Icons.inventory_2,
                      ),
                      _DetailRow(
                        label: 'المبيعات النقدية',
                        value: Formatters.currencyIQD(
                            (kpis['cash_sales'] as num?)?.toDouble() ?? 0.0),
                        icon: Icons.money,
                        color: Colors.green,
                      ),
                      _DetailRow(
                        label: 'المبيعات الآجلة',
                        value: Formatters.currencyIQD(
                            (kpis['credit_sales'] as num?)?.toDouble() ?? 0.0),
                        icon: Icons.credit_card,
                        color: Colors.orange,
                      ),
                      _DetailRow(
                        label: 'المبيعات بالأقساط',
                        value: Formatters.currencyIQD(
                            (kpis['installment_sales'] as num?)?.toDouble() ??
                                0.0),
                        icon: Icons.payment,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSalesAnalysisTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'أكثر المنتجات مبيعاً'),
              Tab(text: 'أقل المنتجات مبيعاً'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildTopSellingProducts(),
                _buildLeastSellingProducts(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSellingProducts() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: context.read<DatabaseService>().getTopSellingProducts(
            from: _fromDate,
            to: _toDate,
            limit: 20,
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }

        final products = snapshot.data!;

        if (products.isEmpty) {
          return const Center(child: Text('لا توجد بيانات'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final quantity =
                (product['total_quantity_sold'] as num?)?.toInt() ?? 0;
            final revenue =
                (product['total_revenue'] as num?)?.toDouble() ?? 0.0;
            final profit = (product['total_profit'] as num?)?.toDouble() ?? 0.0;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withOpacity(0.2),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                title: Text(
                  product['name']?.toString() ?? 'غير معروف',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الكمية المباعة: $quantity'),
                    Text('الإيرادات: ${Formatters.currencyIQD(revenue)}'),
                    Text('الربح: ${Formatters.currencyIQD(profit)}'),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      Formatters.currencyIQD(revenue),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      '${product['sales_count'] ?? 0} عملية',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLeastSellingProducts() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: context.read<DatabaseService>().getLeastSellingProducts(
            from: _fromDate,
            to: _toDate,
            limit: 20,
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }

        final products = snapshot.data!;

        if (products.isEmpty) {
          return const Center(child: Text('لا توجد بيانات'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final quantity =
                (product['total_quantity_sold'] as num?)?.toInt() ?? 0;
            final stock = (product['current_stock'] as num?)?.toInt() ?? 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.2),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
                title: Text(
                  product['name']?.toString() ?? 'غير معروف',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الكمية المباعة: $quantity'),
                    Text('المخزون الحالي: $stock'),
                    if (stock <= 10)
                      Text(
                        'تحذير: مخزون منخفض!',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                trailing: Icon(
                  quantity == 0 ? Icons.warning : Icons.info,
                  color: quantity == 0 ? Colors.red : Colors.orange,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCustomersAnalysisTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'أفضل العملاء'),
              Tab(text: 'عملاء متأخرون'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildTopCustomers(),
                _buildOverdueCustomers(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCustomers() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: context.read<DatabaseService>().getTopCustomers(
            from: _fromDate,
            to: _toDate,
            limit: 20,
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }

        final customers = snapshot.data!;

        if (customers.isEmpty) {
          return const Center(child: Text('لا توجد بيانات'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: customers.length,
          itemBuilder: (context, index) {
            final customer = customers[index];
            final totalSpent =
                (customer['total_spent'] as num?)?.toDouble() ?? 0.0;
            final purchases = customer['total_purchases'] as int? ?? 0;
            final debt = (customer['total_debt'] as num?)?.toDouble() ?? 0.0;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.2),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                title: Text(
                  customer['name']?.toString() ?? 'غير معروف',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (customer['phone'] != null)
                      Text('الهاتف: ${customer['phone']}'),
                    Text('عدد المشتريات: $purchases'),
                    if (debt > 0)
                      Text(
                        'الدين: ${Formatters.currencyIQD(debt)}',
                        style: const TextStyle(color: Colors.orange),
                      ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      Formatters.currencyIQD(totalSpent),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOverdueCustomers() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: context.read<DatabaseService>().getOverdueCustomers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }

        final customers = snapshot.data!;

        if (customers.isEmpty) {
          return const Center(
            child: Text('لا يوجد عملاء متأخرين في الدفع'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: customers.length,
          itemBuilder: (context, index) {
            final customer = customers[index];
            final debt = (customer['total_debt'] as num?)?.toDouble() ?? 0.0;
            final daysOverdue =
                (customer['days_overdue'] as num?)?.toDouble() ?? 0.0;
            final overdueAmount =
                (customer['overdue_amount'] as num?)?.toDouble() ?? 0.0;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.withOpacity(0.2),
                  child: const Icon(Icons.warning, color: Colors.red),
                ),
                title: Text(
                  customer['name']?.toString() ?? 'غير معروف',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (customer['phone'] != null)
                      Text('الهاتف: ${customer['phone']}'),
                    Text(
                        'مبلغ التأخير: ${Formatters.currencyIQD(overdueAmount)}'),
                    Text(
                      'أيام التأخير: ${daysOverdue.toInt()}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      Formatters.currencyIQD(debt),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDemandForecastTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: context.read<DatabaseService>().getProductsAtRisk(
            daysAhead: 30,
            riskThreshold: 0.3,
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }

        final products = snapshot.data!;

        if (products.isEmpty) {
          return const Center(
            child: Text('لا توجد منتجات معرضة للخطر حالياً'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final stock = (product['current_stock'] as num?)?.toInt() ?? 0;
            final minQty = (product['min_quantity'] as num?)?.toInt() ?? 0;
            final riskScore =
                (product['risk_score'] as num?)?.toDouble() ?? 0.0;
            final avgDaily =
                (product['avg_daily_sales'] as num?)?.toDouble() ?? 0.0;
            final daysLeft = avgDaily > 0 ? (stock / avgDaily).toInt() : 0;

            Color riskColor;
            String riskLevel;
            if (riskScore >= 0.8) {
              riskColor = Colors.red;
              riskLevel = 'خطر عالي';
            } else if (riskScore >= 0.6) {
              riskColor = Colors.orange;
              riskLevel = 'خطر متوسط';
            } else {
              riskColor = Colors.yellow.shade700;
              riskLevel = 'خطر منخفض';
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: riskColor.withOpacity(0.2),
                  child: Icon(Icons.warning, color: riskColor),
                ),
                title: Text(
                  product['name']?.toString() ?? 'غير معروف',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('المخزون الحالي: $stock'),
                    Text('الحد الأدنى: $minQty'),
                    if (avgDaily > 0) Text('متوقع النفاد خلال: $daysLeft يوم'),
                    Text(
                      'مستوى الخطر: $riskLevel',
                      style: TextStyle(
                        color: riskColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(riskScore * 100).toInt()}%',
                        style: TextStyle(
                          color: riskColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeComparisonTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: context.read<DatabaseService>().getMonthlySalesTrend(
            months: _selectedMonths,
          ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }

        final data = snapshot.data!;

        if (data.isEmpty) {
          return const Center(child: Text('لا توجد بيانات'));
        }

        // إعداد البيانات للرسم البياني
        final spots = data.asMap().entries.map((entry) {
          final index = entry.key.toDouble();
          final revenue =
              (entry.value['total_revenue'] as num?)?.toDouble() ?? 0.0;
          return FlSpot(index, revenue);
        }).toList();

        final maxRevenue =
            spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اتجاه المبيعات الشهرية',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: true),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      Formatters.currencyIQD(value),
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() < data.length) {
                                      return Text(
                                        data[value.toInt()]['month']
                                                ?.toString() ??
                                            '',
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: Colors.blue,
                                barWidth: 3,
                                dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(show: true),
                              ),
                            ],
                            minY: 0,
                            maxY: maxRevenue * 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // جدول البيانات
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تفاصيل الشهري',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ...data.map((month) {
                        final revenue =
                            (month['total_revenue'] as num?)?.toDouble() ?? 0.0;
                        final profit =
                            (month['total_profit'] as num?)?.toDouble() ?? 0.0;
                        final sales = month['sales_count'] as int? ?? 0;

                        return ListTile(
                          title: Text(month['month']?.toString() ?? ''),
                          subtitle: Text('عدد المبيعات: $sales'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                Formatters.currencyIQD(revenue),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                'ربح: ${Formatters.currencyIQD(profit)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    DateTime? startDate = _fromDate;
    DateTime? endDate = _toDate;

    final result = await showDialog<DateTimeRange?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            title: const Text('اختيار الفترة'),
            content: SizedBox(
              width: 350,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? now,
                        firstDate: DateTime(2020),
                        lastDate: endDate ?? now,
                        builder: (context, child) {
                          return Directionality(
                            textDirection: ui.TextDirection.rtl,
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setDialogState(() => startDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('من تاريخ',
                                    style: TextStyle(fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(
                                  startDate != null
                                      ? DateFormat('yyyy-MM-dd')
                                          .format(startDate!)
                                      : 'اختر التاريخ',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate ?? now,
                        firstDate: startDate ?? DateTime(2020),
                        lastDate: now,
                        builder: (context, child) {
                          return Directionality(
                            textDirection: ui.TextDirection.rtl,
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setDialogState(() => endDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('إلى تاريخ',
                                    style: TextStyle(fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(
                                  endDate != null
                                      ? DateFormat('yyyy-MM-dd')
                                          .format(endDate!)
                                      : 'اختر التاريخ',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    startDate != null && endDate != null
                        ? DateTimeRange(start: startDate!, end: endDate!)
                        : null,
                  );
                },
                child: const Text('تطبيق'),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _fromDate = result.start;
        _toDate = result.end;
      });
    }
  }

  Future<void> _exportCurrentTab() async {
    final currentIndex = _tabController.index;
    final db = context.read<DatabaseService>();
    String? savedPath;

    try {
      switch (currentIndex) {
        case 0: // مؤشرات الأداء
          savedPath = await _exportKPIsTab(db);
          break;
        case 1: // تحليل المبيعات
          savedPath = await _exportSalesAnalysisTab(db);
          break;
        case 2: // تحليل العملاء
          savedPath = await _exportCustomersAnalysisTab(db);
          break;
        case 3: // التنبؤ بالطلب
          savedPath = await _exportDemandForecastTab(db);
          break;
        case 4: // مقارنات زمنية
          savedPath = await _exportTimeComparisonTab(db);
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

  String _formatDateForFilename(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatDateForDisplay(DateTime date) {
    return DateFormat('d - M - yyyy', 'ar').format(date);
  }

  Future<String?> _exportKPIsTab(DatabaseService db) async {
    final data = await db.getSalesKPIs(from: _fromDate, to: _toDate);
    final kpis = data['current_period'] ?? {};

    final items = <MapEntry<String, String>>[
      MapEntry('إجمالي المبيعات', '${kpis['total_sales'] ?? 0} عملية بيع'),
      MapEntry(
          'إجمالي الإيرادات',
          Formatters.currencyIQD(
              (kpis['total_revenue'] as num?)?.toDouble() ?? 0.0)),
      MapEntry(
          'إجمالي الأرباح',
          Formatters.currencyIQD(
              (kpis['total_profit'] as num?)?.toDouble() ?? 0.0)),
      MapEntry(
          'متوسط قيمة البيع',
          Formatters.currencyIQD(
              (kpis['avg_sale_amount'] as num?)?.toDouble() ?? 0.0)),
      MapEntry('عدد العملاء', '${kpis['unique_customers'] ?? 0} عميل'),
      MapEntry(
          'عدد المنتجات المباعة', '${kpis['unique_products_sold'] ?? 0} منتج'),
      MapEntry(
          'المبيعات النقدية',
          Formatters.currencyIQD(
              (kpis['cash_sales'] as num?)?.toDouble() ?? 0.0)),
      MapEntry(
          'المبيعات الآجلة',
          Formatters.currencyIQD(
              (kpis['credit_sales'] as num?)?.toDouble() ?? 0.0)),
      MapEntry(
          'المبيعات بالأقساط',
          Formatters.currencyIQD(
              (kpis['installment_sales'] as num?)?.toDouble() ?? 0.0)),
    ];

    final dateStr = _fromDate != null && _toDate != null
        ? '${_formatDateForFilename(_fromDate!)}_${_formatDateForFilename(_toDate!)}'
        : _formatDateForFilename(DateTime.now());

    return await PdfExporter.exportKeyValue(
      filename: 'مؤشرات_الأداء_$dateStr.pdf',
      title:
          'مؤشرات الأداء - ${_fromDate != null && _toDate != null ? '${_formatDateForDisplay(_fromDate!)} إلى ${_formatDateForDisplay(_toDate!)}' : 'الفترة الحالية'}',
      items: items,
    );
  }

  Future<String?> _exportSalesAnalysisTab(DatabaseService db) async {
    final topProducts = await db.getTopSellingProducts(
      from: _fromDate,
      to: _toDate,
      limit: 20,
    );

    final rows = <List<String>>[
      ['المنتج', 'الكمية المباعة', 'الإيرادات', 'الربح'],
      ...topProducts.map((product) => [
            product['name']?.toString() ?? 'غير معروف',
            '${product['total_quantity_sold'] ?? 0}',
            Formatters.currencyIQD(
                (product['total_revenue'] as num?)?.toDouble() ?? 0.0),
            Formatters.currencyIQD(
                (product['total_profit'] as num?)?.toDouble() ?? 0.0),
          ]),
    ];

    final dateStr = _fromDate != null && _toDate != null
        ? '${_formatDateForFilename(_fromDate!)}_${_formatDateForFilename(_toDate!)}'
        : _formatDateForFilename(DateTime.now());

    return await PdfExporter.exportDataTable(
      filename: 'تحليل_المبيعات_$dateStr.pdf',
      title:
          'تحليل المبيعات - ${_fromDate != null && _toDate != null ? '${_formatDateForDisplay(_fromDate!)} إلى ${_formatDateForDisplay(_toDate!)}' : 'الفترة الحالية'}',
      headers: ['المنتج', 'الكمية المباعة', 'الإيرادات', 'الربح'],
      rows: rows.skip(1).toList(),
    );
  }

  Future<String?> _exportCustomersAnalysisTab(DatabaseService db) async {
    final topCustomers = await db.getTopCustomers(
      from: _fromDate,
      to: _toDate,
      limit: 20,
    );

    final rows = <List<String>>[
      ['العميل', 'إجمالي المشتريات', 'عدد المشتريات', 'الدين'],
      ...topCustomers.map((customer) => [
            customer['name']?.toString() ?? 'غير معروف',
            Formatters.currencyIQD(
                (customer['total_spent'] as num?)?.toDouble() ?? 0.0),
            '${customer['total_purchases'] ?? 0}',
            Formatters.currencyIQD(
                (customer['total_debt'] as num?)?.toDouble() ?? 0.0),
          ]),
    ];

    final dateStr = _fromDate != null && _toDate != null
        ? '${_formatDateForFilename(_fromDate!)}_${_formatDateForFilename(_toDate!)}'
        : _formatDateForFilename(DateTime.now());

    return await PdfExporter.exportDataTable(
      filename: 'تحليل_العملاء_$dateStr.pdf',
      title:
          'تحليل العملاء - ${_fromDate != null && _toDate != null ? '${_formatDateForDisplay(_fromDate!)} إلى ${_formatDateForDisplay(_toDate!)}' : 'الفترة الحالية'}',
      headers: ['العميل', 'إجمالي المشتريات', 'عدد المشتريات', 'الدين'],
      rows: rows.skip(1).toList(),
    );
  }

  Future<String?> _exportDemandForecastTab(DatabaseService db) async {
    final products = await db.getProductsAtRisk(
      daysAhead: 30,
      riskThreshold: 0.3,
    );

    final rows = <List<String>>[
      ['المنتج', 'المخزون الحالي', 'الحد الأدنى', 'مستوى الخطر', 'أيام متبقية'],
      ...products.map((product) {
        final stock = (product['current_stock'] as num?)?.toInt() ?? 0;
        final minQty = (product['min_quantity'] as num?)?.toInt() ?? 0;
        final riskScore = (product['risk_score'] as num?)?.toDouble() ?? 0.0;
        final avgDaily =
            (product['avg_daily_sales'] as num?)?.toDouble() ?? 0.0;
        final daysLeft = avgDaily > 0 ? (stock / avgDaily).toInt() : 0;

        String riskLevel;
        if (riskScore >= 0.8) {
          riskLevel = 'خطر عالي';
        } else if (riskScore >= 0.6) {
          riskLevel = 'خطر متوسط';
        } else {
          riskLevel = 'خطر منخفض';
        }

        return [
          product['name']?.toString() ?? 'غير معروف',
          '$stock',
          '$minQty',
          riskLevel,
          '$daysLeft',
        ];
      }),
    ];

    final dateStr = _formatDateForFilename(DateTime.now());

    return await PdfExporter.exportDataTable(
      filename: 'التنبؤ_بالطلب_$dateStr.pdf',
      title: 'التنبؤ بالطلب - ${_formatDateForDisplay(DateTime.now())}',
      headers: [
        'المنتج',
        'المخزون الحالي',
        'الحد الأدنى',
        'مستوى الخطر',
        'أيام متبقية'
      ],
      rows: rows.skip(1).toList(),
    );
  }

  Future<String?> _exportTimeComparisonTab(DatabaseService db) async {
    final data = await db.getMonthlySalesTrend(months: _selectedMonths);

    final rows = <List<String>>[
      ['الشهر', 'الإيرادات', 'الأرباح', 'عدد المبيعات'],
      ...data.map((month) => [
            month['month']?.toString() ?? '',
            Formatters.currencyIQD(
                (month['total_revenue'] as num?)?.toDouble() ?? 0.0),
            Formatters.currencyIQD(
                (month['total_profit'] as num?)?.toDouble() ?? 0.0),
            '${month['sales_count'] ?? 0}',
          ]),
    ];

    return await PdfExporter.exportDataTable(
      filename: 'مقارنات_زمنية_${_selectedMonths}_شهر.pdf',
      title: 'مقارنات زمنية - آخر $_selectedMonths أشهر',
      headers: ['الشهر', 'الإيرادات', 'الأرباح', 'عدد المبيعات'],
      rows: rows.skip(1).toList(),
    );
  }
}

class _KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;
  final double? change;

  const _KPICard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
    this.change,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 18),
                if (change != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: change! >= 0 ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${change! >= 0 ? '+' : ''}${change!.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 14,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
