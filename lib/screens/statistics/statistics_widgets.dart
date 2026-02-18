import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../../models/entry.dart';
import '../../models/customer.dart';
import '../../database/customer_database_helper.dart';
import '../customer_screen/details_screen/customer_detail_screen.dart';

class StatisticsWidgets {
  // بناء بطاقة إحصائيات العملاء
  static Widget buildCustomerStatsCard({
    required bool isDark,
    required List<Customer> customers,
    required List<Map<String, dynamic>> topCustomers,
    required bool isLoadingCustomers,
    required CustomerDatabaseHelper customerDbHelper,
  }) {
    final primaryColor = Colors.blue.shade700;
    const secondaryColor = Colors.teal;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? Colors.grey.shade800 : Colors.white;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.group,
                      color: secondaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'إحصائيات العملاء',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                // عدد العملاء الكلي
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: secondaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: secondaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'العدد: ${customers.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // حالة التحميل محسنة
          if (isLoadingCustomers)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: secondaryColor,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'جاري تحميل بيانات العملاء...',
                      style: const TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (topCustomers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.group_outlined,
                      size: 48,
                      color:
                          isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'لا يوجد بيانات للعملاء',
                      style: const TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // قائمة العملاء الأكثر نشاطًا محسنة
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      'العملاء الأكثر نشاطًا',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.grey.shade800,
                      ),
                    ),
                  ),
                  // استخدام ListView.builder محسن
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: topCustomers.length,
                    itemBuilder: (context, index) {
                      return _buildCustomerListItem(
                        context,
                        topCustomers[index],
                        index,
                        isDark,
                        textColor,
                        primaryColor,
                        customerDbHelper,
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // بناء عنصر قائمة العميل
  static Widget _buildCustomerListItem(
    BuildContext context,
    Map<String, dynamic> customerData,
    int index,
    bool isDark,
    Color textColor,
    Color primaryColor,
    CustomerDatabaseHelper customerDbHelper,
  ) {
    final customer = customerData['customer'] as Customer;
    final transactionCount = customerData['transactionCount'] as int;
    final balance = customerData['balance'] as double;
    final lastTx = customerData['lastTransaction'] as DateTime?;
    final isPositiveBalance = balance >= 0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerDetailScreen(
              customer: customer,
              dbHelper: customerDbHelper,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // رقم الترتيب
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // بيانات العميل
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // اسم العميل
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: textColor,
                          ),
                        ),

                        // عدد المعاملات
                        Row(
                          children: [
                            Icon(
                              Icons.swap_horiz,
                              size: 16,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              transactionCount.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // الرصيد
                        Row(
                          children: [
                            Icon(
                              isPositiveBalance
                                  ? Icons.arrow_circle_up
                                  : Icons.arrow_circle_down,
                              size: 16,
                              color:
                                  isPositiveBalance ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${balance.toStringAsFixed(0)} ر.ي',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isPositiveBalance
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),

                        // آخر معاملة
                        if (lastTx != null)
                          Text(
                            'آخر معاملة: ${DateFormat('dd/MM', 'ar').format(lastTx)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: (index * 100).ms).slideY(
          begin: 0.2,
          end: 0.0,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
  }

  // بناء الرسم البياني للأرباح والمبيعات
  static Widget buildProfitChart(List<Entry> entries, bool isDark) {
    if (entries.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          'لا توجد بيانات لعرضها',
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    // تصنيف البيانات حسب التاريخ
    final sortedEntries = List<Entry>.from(entries);
    sortedEntries.sort((a, b) => a.date.compareTo(b.date));

    // الحد الأقصى لعدد النقاط في الرسم البياني
    const maxPoints = 7;
    final dataPoints = sortedEntries.length > maxPoints
        ? sortedEntries.sublist(sortedEntries.length - maxPoints)
        : sortedEntries;

    // إعداد نقاط البيانات
    final profitSpots = <FlSpot>[];
    final salesSpots = <FlSpot>[];

    for (int i = 0; i < dataPoints.length; i++) {
      profitSpots.add(FlSpot(i.toDouble(), dataPoints[i].netProfit));
      salesSpots.add(FlSpot(i.toDouble(), dataPoints[i].totalAmount));
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تطور الأرباح والمبيعات',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildChartLegendItem(Colors.blue.shade500, 'المبيعات', isDark),
              const SizedBox(width: 16),
              _buildChartLegendItem(Colors.green.shade500, 'الأرباح', isDark),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  horizontalInterval: null,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < dataPoints.length) {
                          final date = dataPoints[value.toInt()].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '${date.day}/${date.month}',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                      reservedSize: 30,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (dataPoints.length - 1).toDouble(),
                minY: 0,
                lineBarsData: [
                  // خط المبيعات
                  LineChartBarData(
                    spots: salesSpots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: Colors.blue.shade500,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color:
                          Colors.blue.shade100.withOpacity(isDark ? 0.1 : 0.2),
                    ),
                  ),
                  // خط الأرباح
                  LineChartBarData(
                    spots: profitSpots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: Colors.green.shade500,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color:
                          Colors.green.shade100.withOpacity(isDark ? 0.1 : 0.2),
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

  // إنشاء عنصر شرح الرسم البياني
  static Widget _buildChartLegendItem(Color color, String label, bool isDark) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[300] : Colors.grey[800],
          ),
        ),
      ],
    );
  }

  // بناء بطاقة الإحصائيات الرئيسية
  static Widget buildMainStatsCard({
    required double totalNetProfit,
    required double totalAmount,
    required String profitPercentage,
    required NumberFormat numberFormat,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Colors.blue.shade700,
            Colors.blue.shade500,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'صافي الربح',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.trending_up,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$profitPercentage%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${numberFormat.format(totalNetProfit)} ج.م',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إجمالي المبالغ',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${numberFormat.format(totalAmount)} ج.م',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.monetization_on,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(
          begin: 0.3,
          end: 0.0,
          duration: 600.ms,
          curve: Curves.easeOutCubic,
        );
  }

  // بناء بطاقة إحصائية فردية
  static Widget buildStatisticCard({
    required String label,
    required double value,
    required IconData icon,
    required Color color,
    required NumberFormat numberFormat,
    bool isCount = false,
    required bool isDark,
  }) {
    return Card(
      elevation: 3,
      color: isDark ? Colors.grey.shade800 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isCount
                    ? numberFormat.format(value.toInt())
                    : '${numberFormat.format(value)} ج.م',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(
          begin: 0.3,
          end: 0.0,
          duration: 600.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
