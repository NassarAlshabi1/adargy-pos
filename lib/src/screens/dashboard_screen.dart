import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/dashboard_view_model.dart';
import '../utils/format.dart';
import '../services/store_config.dart';
import '../utils/dark_mode_utils.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_display_widgets.dart' as errw;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DashboardViewModel>().load();
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  // ViewModel handles loading

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    return Scaffold(
      backgroundColor: DarkModeUtils.getBackgroundColor(context),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.error != null
              ? errw.ErrorWidget(
                  error: vm.error,
                  onRetry: () => context.read<DashboardViewModel>().load(),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Section
                          _buildHeader(),
                          const SizedBox(height: 32),

                          // Stats Cards
                          _buildStatsSection(vm),
                          const SizedBox(height: 32),

                          // Charts Section
                          _buildChartsSection(vm),
                          const SizedBox(height: 32),

                          // Bottom Section
                          _buildBottomSection(vm),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding:
          EdgeInsets.all(MediaQuery.of(context).size.width > 800 ? 16 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
            Theme.of(context).colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.2)
                : Colors.white.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 800;

          return isWideScreen
              ? _buildWideHeaderLayout()
              : _buildCompactHeaderLayout();
        },
      ),
    );
  }

  Widget _buildWideHeaderLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isMediumScreen = constraints.maxWidth < 1000;
            return Container(
              padding: EdgeInsets.all(isMediumScreen ? 16 : 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isDark ? 0.15 : 0.2),
                borderRadius: BorderRadius.circular(isMediumScreen ? 16 : 20),
                border: Border.all(
                  color: Colors.white.withOpacity(isDark ? 0.2 : 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.analytics_rounded,
                color: Theme.of(context).colorScheme.onSurface,
                size: isMediumScreen ? 32 : 36,
              ),
            );
          },
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMediumScreen = constraints.maxWidth < 1000;
                  return Text(
                    'مرحباً بك في لوحة التحكم',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: isMediumScreen ? 22 : 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMediumScreen = constraints.maxWidth < 1000;
                  return Text(
                    'نظرة شاملة على أداء متجرك وإحصائيات المبيعات',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                      fontSize: isMediumScreen ? 14 : 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMediumScreen = constraints.maxWidth < 1000;
            return Container(
              padding: EdgeInsets.symmetric(
                  horizontal: isMediumScreen ? 16 : 20,
                  vertical: isMediumScreen ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isDark ? 0.15 : 0.2),
                borderRadius: BorderRadius.circular(isMediumScreen ? 14 : 16),
                border: Border.all(
                  color: Colors.white.withOpacity(isDark ? 0.2 : 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: isMediumScreen ? 18 : 20,
                  ),
                  SizedBox(height: isMediumScreen ? 6 : 8),
                  Text(
                    DateTime.now().toString().substring(0, 10),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: isMediumScreen ? 14 : 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCompactHeaderLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isVerySmall = constraints.maxWidth < 400;
            return Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isVerySmall ? 12 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(isDark ? 0.15 : 0.2),
                    borderRadius: BorderRadius.circular(isVerySmall ? 12 : 16),
                    border: Border.all(
                      color: Colors.white.withOpacity(isDark ? 0.2 : 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.analytics_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: isVerySmall ? 24 : 28,
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: isVerySmall ? 12 : 16,
                        vertical: isVerySmall ? 8 : 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isDark ? 0.15 : 0.2),
                      borderRadius:
                          BorderRadius.circular(isVerySmall ? 10 : 12),
                      border: Border.all(
                        color: Colors.white.withOpacity(isDark ? 0.2 : 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: isVerySmall ? 14 : 16,
                        ),
                        SizedBox(width: isVerySmall ? 6 : 8),
                        Flexible(
                          child: Text(
                            DateTime.now().toString().substring(0, 10),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: isVerySmall ? 12 : 14,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final isVerySmall = constraints.maxWidth < 400;
            return SizedBox(height: isVerySmall ? 12 : 16);
          },
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final isVerySmall = constraints.maxWidth < 400;
            return Text(
              'مرحباً بك في لوحة التحكم ${context.watch<StoreConfig>().shopName}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: isVerySmall ? 18 : 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                height: 1.3,
              ),
              maxLines: isVerySmall ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final isVerySmall = constraints.maxWidth < 400;
            return SizedBox(height: isVerySmall ? 6 : 8);
          },
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final isVerySmall = constraints.maxWidth < 400;
            return Text(
              'نظرة شاملة على أداء متجرك وإحصائيات المبيعات',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: isVerySmall ? 12 : 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
              maxLines: isVerySmall ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatsSection(DashboardViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الإحصائيات السريعة',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: DarkModeUtils.getTextColor(context),
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 6,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.0,
          children: [
            _buildStatCard(
              'مبيعات اليوم',
              Formatters.currencyIQD(vm.todaySales),
              Icons.trending_up,
              Colors.blue.shade600,
              Colors.blue.shade50,
            ),
            _buildStatCard(
              'ربح اليوم',
              Formatters.currencyIQD(vm.todayProfit),
              Icons.monetization_on,
              Colors.green.shade600,
              Colors.green.shade50,
            ),
            _buildStatCard(
              'مبيعات الشهر',
              Formatters.currencyIQD(vm.monthlySales),
              Icons.calendar_month,
              Colors.purple.shade600,
              Colors.purple.shade50,
            ),
            _buildStatCard(
              'ربح الشهر',
              Formatters.currencyIQD(vm.monthlyProfit),
              Icons.account_balance_wallet,
              Colors.orange.shade600,
              Colors.orange.shade50,
            ),
            _buildStatCard(
              'إجمالي المنتجات',
              '${vm.totalProducts}',
              Icons.inventory_2,
              Colors.indigo.shade600,
              Colors.indigo.shade50,
            ),
            _buildStatCard(
              'إجمالي الكمية في المخزون',
              '${vm.totalProductQuantity}',
              Icons.warehouse,
              Colors.brown.shade600,
              Colors.brown.shade50,
            ),
            _buildStatCard(
              'عدد المنتجات المتوفرة',
              '${vm.availableProductsCount}',
              Icons.inventory,
              Colors.deepPurple.shade600,
              Colors.deepPurple.shade50,
            ),
            _buildStatCard(
              'العملاء',
              '${vm.totalCustomers}',
              Icons.people,
              Colors.teal.shade600,
              Colors.teal.shade50,
            ),
            _buildStatCard(
              'الموردون',
              '${vm.totalSuppliers}',
              Icons.local_shipping,
              Colors.cyan.shade600,
              Colors.cyan.shade50,
            ),
            _buildStatCard(
              'تنبيهات المخزون',
              '${vm.lowStockCount}',
              vm.lowStockCount == 0 ? Icons.check_circle : Icons.warning,
              vm.lowStockCount == 0
                  ? Colors.green.shade600
                  : Colors.red.shade600,
              vm.lowStockCount == 0 ? Colors.green.shade50 : Colors.red.shade50,
              iconSize: vm.lowStockCount == 0 ? 14 : 10,
            ),
            _buildStatCard(
              'إجمالي الديون',
              Formatters.currencyIQD(vm.totalDebt),
              Icons.account_balance_wallet,
              Colors.deepOrange.shade600,
              Colors.deepOrange.shade50,
            ),
            _buildStatCard(
              'ديون متأخرة',
              Formatters.currencyIQD(vm.overdueDebt),
              Icons.warning_amber,
              Colors.pink.shade600,
              Colors.pink.shade50,
            ),
            _buildStatCard(
              'عملاء مدينون',
              '${vm.customersWithDebt}',
              Icons.people_outline,
              Colors.amber.shade600,
              Colors.amber.shade50,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, Color bgColor,
      {double iconSize = 10}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.3),
                        color.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: color.withOpacity(0.4),
                      width: 0.5,
                    ),
                  ),
                  child: Icon(icon, color: color, size: iconSize),
                ),
                const Spacer(),
                Icon(
                  Icons.trending_up,
                  color: color.withOpacity(0.7),
                  size: 10,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 8,
                  color: DarkModeUtils.getSecondaryTextColor(context),
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(DashboardViewModel vm) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildSalesChart(),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: _buildTopProductsChart(vm),
        ),
      ],
    );
  }

  Widget _buildSalesChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DarkModeUtils.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: DarkModeUtils.getShadowColor(context).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart,
                  color: DarkModeUtils.getInfoColor(context), size: 24),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  'مبيعات الأسبوع',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 1,
                  verticalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: DarkModeUtils.getBorderColor(context),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: DarkModeUtils.getBorderColor(context),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const days = [
                          'أحد',
                          'اثنين',
                          'ثلاثاء',
                          'أربعاء',
                          'خميس',
                          'جمعة',
                          'سبت'
                        ];
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            days[value.toInt()],
                            style: TextStyle(
                              color:
                                  DarkModeUtils.getSecondaryTextColor(context),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            '${value.toInt()}K',
                            style: TextStyle(
                              color:
                                  DarkModeUtils.getSecondaryTextColor(context),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                      reservedSize: 42,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border:
                      Border.all(color: DarkModeUtils.getBorderColor(context)),
                ),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 6,
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 3),
                      const FlSpot(1, 2),
                      const FlSpot(2, 5),
                      const FlSpot(3, 3.1),
                      const FlSpot(4, 4),
                      const FlSpot(5, 3),
                      const FlSpot(6, 4),
                    ],
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        DarkModeUtils.getInfoColor(context),
                        Colors.purple.shade400,
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: DarkModeUtils.getCardColor(context),
                          strokeWidth: 2,
                          strokeColor: DarkModeUtils.getInfoColor(context),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade400.withOpacity(0.3),
                          Colors.purple.shade400.withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductsChart(DashboardViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DarkModeUtils.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: DarkModeUtils.getShadowColor(context).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'أفضل المنتجات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: vm.topProducts.isEmpty
                ? EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'لا توجد منتجات لعرضها',
                    message: 'أضف منتجات أو حدث البيانات لعرض الأفضل مبيعاً',
                    actionLabel: 'تحديث',
                    onAction: () => context.read<DashboardViewModel>().load(),
                  )
                : ListView.builder(
                    itemCount: vm.topProducts.length,
                    itemBuilder: (context, index) {
                      final product = vm.topProducts[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: DarkModeUtils.getBackgroundColor(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: DarkModeUtils.getInfoColor(context)
                                    .withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.inventory_2,
                                color: DarkModeUtils.getInfoColor(context),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    product['name']?.toString() ?? 'منتج',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  Text(
                                    'الكمية: ${product['quantity']}',
                                    style: TextStyle(
                                      color:
                                          DarkModeUtils.getSecondaryTextColor(
                                              context),
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: Text(
                                Formatters.currencyIQD(
                                    (product['price'] as num?) ?? 0),
                                style: TextStyle(
                                  color: DarkModeUtils.getSuccessColor(context),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(DashboardViewModel vm) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: _buildRecentSales(vm),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 1,
          child: _buildLowStockAlert(vm),
        ),
      ],
    );
  }

  Widget _buildRecentSales(DashboardViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DarkModeUtils.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: DarkModeUtils.getShadowColor(context).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long,
                  color: DarkModeUtils.getSuccessColor(context), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'آخر المنتجات المباعة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: vm.recentSales.isEmpty
                ? Center(
                    child: EmptyState(
                      icon: Icons.shopping_cart_outlined,
                      title: 'لا توجد مبيعات حديثة',
                      message: 'ابدأ بعملية بيع لعرض أحدث المبيعات هنا',
                      actionLabel: 'تحديث',
                      onAction: () => context.read<DashboardViewModel>().load(),
                    ),
                  )
                : ListView.builder(
                    itemCount: vm.recentSales.length,
                    itemBuilder: (context, index) {
                      final product = vm.recentSales[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: DarkModeUtils.getBackgroundColor(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: DarkModeUtils.getSuccessColor(context)
                                    .withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.inventory_2,
                                color: DarkModeUtils.getSuccessColor(context),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    product['name']?.toString() ?? 'منتج',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  Flexible(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            'الكمية: ${product['quantity']}',
                                            style: TextStyle(
                                              color: DarkModeUtils
                                                  .getSecondaryTextColor(
                                                      context),
                                              fontSize: 10,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            product['created_at']
                                                    ?.toString()
                                                    .substring(0, 16) ??
                                                '',
                                            style: TextStyle(
                                              color: DarkModeUtils
                                                  .getSecondaryTextColor(
                                                      context),
                                              fontSize: 10,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: Text(
                                Formatters.currencyIQD(
                                    (product['sale_price'] as num?) ?? 0),
                                style: TextStyle(
                                  color: DarkModeUtils.getSuccessColor(context),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockAlert(DashboardViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DarkModeUtils.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: DarkModeUtils.getShadowColor(context).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                vm.lowStockProducts.isEmpty
                    ? Icons.check_circle
                    : Icons.warning,
                color: vm.lowStockProducts.isEmpty
                    ? Colors.green.shade600
                    : Colors.orange.shade600,
                size: vm.lowStockProducts.isEmpty ? 28 : 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تنبيهات المخزون',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: vm.lowStockProducts.isEmpty
                ? Center(
                    child: EmptyState(
                      icon: Icons.check_circle_outline,
                      iconColor: Colors.green.shade600,
                      title: 'المخزون آمن',
                      message: 'لا توجد منتجات منخفضة المخزون حالياً',
                      actionLabel: 'تحديث',
                      onAction: () => context.read<DashboardViewModel>().load(),
                    ),
                  )
                : ListView.builder(
                    itemCount: vm.lowStockProducts.length,
                    itemBuilder: (context, index) {
                      final product = vm.lowStockProducts[index];
                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      final warn = DarkModeUtils.getWarningColor(context);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: warn.withOpacity(isDark ? 0.12 : 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: warn.withOpacity(isDark ? 0.45 : 0.25)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: warn.withOpacity(isDark ? 0.25 : 0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.inventory_2,
                                color: warn,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    product['name']?.toString() ?? 'منتج',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'الكمية: ${product['quantity']} (الحد الأدنى: ${product['min_quantity']})',
                                    style: TextStyle(
                                      color: warn,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: warn.withOpacity(isDark ? 0.25 : 0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'منخفض',
                                style: TextStyle(
                                  color: warn,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
