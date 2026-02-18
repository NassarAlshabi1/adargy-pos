import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'statistics_controller.dart';
import 'statistics_widgets.dart';

class StatisticsUIComponents {
  // بناء أزرار الفلترة
  static Widget buildFilterButtons({
    required StatisticsController controller,
    required bool isDark,
    required VoidCallback onFilterChanged,
    required VoidCallback onDateRangePressed,
  }) {
    final primaryColor = Colors.blue.shade700;
    final accentColor = isDark ? Colors.blue.shade300 : Colors.blue.shade600;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'فترة التقرير',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.filters.length,
                    itemBuilder: (context, index) {
                      final filter = controller.filters[index];
                      final isSelected = controller.isFilterSelected(filter);

                      // إذا كان الفلتر هو "مخصص" فلا نعرضه في القائمة
                      if (filter == 'مخصص' && !isSelected) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(left: 0.0),
                        child: InkWell(
                          onTap: () {
                            controller.changeFilter(filter);
                            onFilterChanged();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? accentColor : primaryColor)
                                  : (isDark
                                      ? Colors.grey[800]
                                      : Colors.grey[200]),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: isSelected && filter == 'مخصص'
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        controller.getCustomFilterText(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    filter,
                                    style: const TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.white70
                                              : Colors.black87),
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // زر اختيار نطاق التاريخ
              InkWell(
                onTap: onDateRangePressed,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.date_range,
                    size: 22,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // بناء عنوان الصفحة مع زر تقرير PDF
  static Widget buildPageHeader({
    required bool isDark,
    required VoidCallback onPdfButtonPressed,
  }) {
    final primaryColor = Colors.blue.shade700;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'الإحصائيات',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : primaryColor,
          ),
        ),
        // زر تقرير PDF
        InkWell(
          onTap: onPdfButtonPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFFFFA000) : const Color(0xFFFFA000),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFFFFA000) : Colors.grey.shade300,
                width: 1.5,
              ),
              boxShadow: [
                if (!isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  size: 20,
                  color: isDark ? Colors.white : Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'تقرير PDF',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // بناء بطاقات الإحصائيات الفرعية
  static Widget buildStatisticsCards({
    required double totalEngineerProfit,
    required double totalManagerProfit,
    required int entriesCount,
    required double highestProfit,
    required bool isDark,
    required NumberFormat numberFormat,
  }) {
    return Column(
      children: [
        // بطاقات الإحصائيات الفرعية (ربح المهندس وربح المدير)
        Row(
          children: [
            Expanded(
              child: StatisticsWidgets.buildStatisticCard(
                label: 'ربح المهندس',
                value: totalEngineerProfit,
                icon: Icons.engineering,
                color: Colors.blue.shade600,
                numberFormat: numberFormat,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatisticsWidgets.buildStatisticCard(
                label: 'ربح المدير',
                value: totalManagerProfit,
                icon: Icons.business_center,
                color: Colors.orange.shade700,
                numberFormat: numberFormat,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // بطاقات إحصائيات إضافية (عدد العناصر ومتوسط الربح)
        Row(
          children: [
            Expanded(
              child: StatisticsWidgets.buildStatisticCard(
                label: 'عدد العناصر',
                value: entriesCount.toDouble(),
                icon: Icons.format_list_numbered,
                color: Colors.purple.shade600,
                numberFormat: numberFormat,
                isCount: true,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: StatisticsWidgets.buildStatisticCard(
                label: 'أعلى ربح',
                value: highestProfit,
                icon: Icons.trending_up,
                color: Colors.green.shade600,
                numberFormat: numberFormat,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // بناء عنوان القسم
  static Widget buildSectionTitle({
    required String title,
    required bool isDark,
    required Color primaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : primaryColor,
        ),
      ),
    );
  }
}
