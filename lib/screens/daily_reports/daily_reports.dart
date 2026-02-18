import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/entry.dart';
import '../../providers/entry_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/custom_button.dart';
import '../entry_details_screen.dart';
import '../entry_form.dart';
import 'pdf_report.dart';

class DailyReportsScreen extends StatefulWidget {
  const DailyReportsScreen({super.key});

  @override
  _DailyReportsScreenState createState() => _DailyReportsScreenState();
}

class _DailyReportsScreenState extends State<DailyReportsScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isExporting = false;

  /// Function to format currency without decimal places and without currency symbol
  String formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'ar',
      symbol: '',
      decimalDigits: 0,
    );
    String formatted = formatter.format(value.abs());
    if (value < 0) {
      formatted = '-$formatted'; // علامة السالب قبل الرقم
    }
    return formatted;
  }

  Future<void> _selectDate(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: isDark ? AppTheme.darkCardColor : Colors.white,
              onSurface: isDark ? Colors.white : Colors.black,
            ),
            dialogBackgroundColor:
                isDark ? AppTheme.darkCardColor : Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          child: Directionality(
            textDirection: ui.TextDirection.rtl,
            child: child!,
          ),
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showExportingSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(width: 10),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
            const SizedBox(width: 20),
            Text(
              'جاري تصدير التقرير...',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  Future<void> _exportToPdf(List<Entry> entries, String formattedDate) async {
    setState(() => _isExporting = true);
    _showExportingSnackbar();

    try {
      await PdfReport.exportToPdf(context, entries, formattedDate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  'تم تصدير التقرير بنجاح',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'حدث خطأ أثناء تصدير التقرير: $e',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(10),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _addEntry(BuildContext context) async {
    final entryFormHelper = EntryFormHelper();
    entryFormHelper.showEntryInputDialog(context);
  }

  void _navigateToDetails(Entry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EntryDetailsScreen(entry: entry),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EntryProvider>(context);
    final allEntries = provider.entries;
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // Filter entries for the selected date
    final entries = allEntries.where((entry) {
      final entryDate = DateFormat('yyyy-MM-dd').format(entry.date);
      return entryDate == formattedDate;
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDateSelector(formattedDate, isDark),

              // Action Buttons Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  color: isDark ? AppTheme.darkCardColor : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الإجراءات', // 'Actions' in Arabic
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : AppTheme.primaryColor,
                          ),
                        ),
                        Row(
                          children: [
                            CustomButton(
                              onPressed: _isExporting
                                  ? () {} // Empty function when disabled
                                  : () {
                                      _addEntry(context);
                                    },
                              text: 'إضافة ',
                              icon: Icons.add_circle,
                              type: ButtonType.primary,
                              size: ButtonSize.small,
                              borderRadius: 12.0,
                            ),
                            const SizedBox(width: 12),
                            CustomButton(
                              onPressed: (_isExporting || entries.isEmpty)
                                  ? () {} // Empty function when disabled
                                  : () {
                                      _exportToPdf(entries, formattedDate);
                                    },
                              text: 'تصدير PDF',
                              icon: Icons.picture_as_pdf,
                              type: ButtonType.secondary,
                              size: ButtonSize.small,
                              borderRadius: 12.0,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              _buildDataTable(entries, isDark),
              const SizedBox(height: 16),
              _buildSummaryCards(entries, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(String formattedDate, bool isDark) {
    return CustomCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.date_range_rounded,
                  size: 22, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'التاريخ',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () => _selectDate(context),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Row(
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? AppTheme.primaryColor : Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down,
                      color: isDark
                          ? AppTheme.primaryColor
                          : Colors.blue.shade800),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<Entry> entries, bool isDark) {
    final totalAmount =
        entries.fold(0.0, (sum, entry) => sum + entry.totalAmount);
    final piecePrice =
        entries.fold(0.0, (sum, entry) => sum + entry.piecePrice);
    final netProfit = entries.fold(0.0, (sum, entry) => sum + entry.netProfit);

    // Calculate percentage of profit relative to total amount
    final profitPercentage = totalAmount > 0
        ? (netProfit / totalAmount * 100).toStringAsFixed(1)
        : '0';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header for Statistics section
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'ملخص الإحصائيات',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.primaryColor,
                ),
              ),
            ),
          ),

          // Main Stats Card
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: isDark
                    ? [
                        AppTheme.primaryColor.withOpacity(0.7),
                        AppTheme.primaryColor.withOpacity(0.3)
                      ]
                    : [
                        AppTheme.primaryColor.withOpacity(0.8),
                        AppTheme.primaryColor
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'صافي الربح',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.arrow_upward,
                                color: Colors.white, size: 16),
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
                  const SizedBox(height: 12),
                  Text(
                    formatCurrency(netProfit),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إجمالي المبيعات',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatCurrency(totalAmount),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تكلفة القطع',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatCurrency(piecePrice),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
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
              curve: Curves.easeOutCubic),

          // Additional Stats
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailCard(
                  'عدد الادخالات',
                  '${entries.length}',
                  Icons.format_list_numbered,
                  AppTheme.primaryColor,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDetailCard(
                  'أعلى ربح',
                  netProfit > 0
                      ? '${entries.map((e) => e.netProfit).reduce((a, b) => a > b ? a : b).toStringAsFixed(0)} ريال'
                      : '0 ريال',
                  Icons.trending_up,
                  Colors.purple.shade600,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
      String title, String value, IconData icon, Color color, bool isDark) {
    return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: isDark ? AppTheme.darkCardColor : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 500.ms).slideY(
            begin: 0.3,
            end: 0.0,
            duration: 500.ms,
            curve: Curves.easeOutCubic));
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color, bool isDark,
      {bool fullWidth = false}) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      elevation: AppTheme.smallElevation,
      borderRadius: AppTheme.smallRadius,
      backgroundColor: isDark ? AppTheme.darkCardColor : Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppTheme.darkSecondaryTextColor
                        : AppTheme.lightSecondaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: fullWidth ? 20 : 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<Entry> entries, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: CustomCard(
        padding: EdgeInsets.zero,
        borderRadius: AppTheme.smallRadius,
        elevation: AppTheme.smallElevation,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: AppTheme.smallRadius.topLeft,
                    topRight: AppTheme.smallRadius.topRight,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'قائمة العناصر',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${entries.length} عنصر',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              // Table Header
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkCardColor.withOpacity(0.7)
                      : Colors.grey.shade100,
                  border: Border(
                    bottom: BorderSide(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade300,
                        width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          'التفاصيل',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'المبلغ',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'سعر القطعة',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'الربح',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              // Table Body
              entries.isEmpty
                  ? _buildEmptyState(isDark)
                  : SizedBox(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return InkWell(
                            onTap: () => _navigateToDetails(entry),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: index.isEven
                                    ? (isDark
                                        ? Colors.grey.shade800.withOpacity(0.3)
                                        : Colors.grey.shade50)
                                    : (isDark
                                        ? Colors.transparent
                                        : Colors.white),
                                border: Border(
                                  bottom: BorderSide(
                                    color: isDark
                                        ? Colors.grey.shade800
                                        : Colors.grey.shade200,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      entry.item,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      formatCurrency(entry.totalAmount),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.cyan.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      formatCurrency(entry.piecePrice),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      formatCurrency(entry.netProfit),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: (index * 70).ms, duration: 400.ms)
                              .slideY(
                                  begin: 0.2,
                                  end: 0.0,
                                  duration: 400.ms,
                                  curve: Curves.easeOut);
                        },
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد بيانات لهذا اليوم',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على زر الإضافة لإنشاء أول مدخل',
            style: const TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Navigation to details is handled by the method above
}
