import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import '../models/entry.dart';
import 'entry_form.dart';
import 'package:provider/provider.dart';
import '../providers/entry_provider.dart';

class EntryDetailsScreen extends StatelessWidget {
  final Entry entry;

  const EntryDetailsScreen({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final entryProvider = Provider.of<EntryProvider>(context, listen: false);
    final entryFormHelper = EntryFormHelper();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.teal.shade300 : Colors.teal.shade700;
    final secondaryColor = isDark ? Colors.blue.shade300 : Colors.blue.shade700;
    final cardColor = isDark ? Colors.grey.shade800 : Colors.white;
    final cardShadowColor =
        isDark ? Colors.black54 : Colors.grey.withOpacity(0.2);
    final valueColor = isDark ? Colors.white : Colors.grey.shade800;
    final backgroundColor =
        isDark ? Colors.grey.shade900 : Colors.grey.shade100;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(
            'تفاصيل الإدخال',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          backgroundColor: primaryColor,
          elevation: isDark ? 0 : 2,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                _showInfoDialog(context, isDark);
              },
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // بطاقة معلومات المنتج
                  _buildHeaderCard(context, entry, isDark, primaryColor),

                  const SizedBox(height: 16),

                  // البيانات التفصيلية
                  _buildDataTable(context, entry, isDark, cardColor,
                      cardShadowColor, valueColor),

                  // ملخص الأرباح
                  const SizedBox(height: 20),
                  _buildSummaryCard(
                      context, entry, isDark, secondaryColor, valueColor),

                  // أزرار التعديل والحذف
                  const SizedBox(height: 16),
                  _buildActionButtons(context, entry, isDark, primaryColor,
                      entryFormHelper, entryProvider),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
      BuildContext context, Entry entry, bool isDark, Color primaryColor) {
    return Card(
      elevation: isDark ? 1 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? Colors.grey.shade800 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.category_outlined,
                color: primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.item,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('yyyy-MM-dd').format(entry.date),
                        style: TextStyle(
                          fontSize: 14,
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
    );
  }

  Widget _buildDataTable(BuildContext context, Entry entry, bool isDark,
      Color cardColor, Color cardShadowColor, Color valueColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cardShadowColor,
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان البطاقة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Colors.blue.shade700, Colors.blue.shade900]
                    : [Colors.blue.shade400, Colors.blue.shade700],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                topLeft: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.analytics_outlined, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'البيانات التفصيلية',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // جدول البيانات
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: FlexColumnWidth(1.5),
                1: FlexColumnWidth(2),
              },
              border: TableBorder.symmetric(
                inside:
                    BorderSide(width: 0.5, color: Colors.grey.withOpacity(0.3)),
              ),
              children: [
                _buildTableRow(context, 'المبلغ الإجمالي',
                    '${entry.totalAmount.toStringAsFixed(2)} ريال', valueColor),
                _buildTableRow(context, 'سعر القطعة',
                    '${entry.piecePrice.toStringAsFixed(2)} ريال', valueColor),
                _buildTableRow(
                    context,
                    'صرف اليوم',
                    '${entry.dailyExchange.toStringAsFixed(2)} ريال',
                    valueColor),
                _buildTableRow(
                    context,
                    'سعر القطعة بالعملة المحلية',
                    '${entry.piecePriceInLocalCurrency.toStringAsFixed(2)} ريال',
                    valueColor),
                // اسم العميل بخط أكبر ولون مميز
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 4),
                      child: Text(
                        'المورد',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 4),
                      child: Text(
                        entry.customerName ?? 'غير محدد',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                // إظهار العملة فقط إذا لم تكن محلي
                if (entry.customerCurrency != null &&
                    entry.customerCurrency != 'محلي')
                  _buildTableRow(context, 'عملة العميل',
                      entry.customerCurrency!, valueColor),
                _buildTableRow(
                    context,
                    'المواصلات',
                    '${entry.transportation.toStringAsFixed(2)} ريال',
                    valueColor),
                _buildTableRow(context, 'صافي الربح',
                    '${entry.netProfit.toStringAsFixed(2)} ريال', valueColor,
                    isHighlighted: true),
                _buildTableRow(
                    context,
                    'ربح المهندس',
                    '${entry.engineerProfit.toStringAsFixed(2)} ريال',
                    valueColor),
                _buildTableRow(
                    context,
                    'ربح المدير',
                    '${entry.managerProfit.toStringAsFixed(2)} ريال',
                    valueColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, Entry entry, bool isDark,
      Color secondaryColor, Color valueColor) {
    return Card(
      elevation: isDark ? 1 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? Colors.grey.shade800 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان البطاقة
            Row(
              children: [
                Icon(
                  Icons.assessment_outlined,
                  color: secondaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'ملخص الأرباح',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: secondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // عرض العناصر بشكل عمودي لتجنب overflow
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryItem(
                  context,
                  'صافي الربح',
                  '${entry.netProfit.toStringAsFixed(2)} ريال',
                  Icons.account_balance_wallet_outlined,
                  isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                  isDark,
                ),
                const SizedBox(height: 8),
                _buildSummaryItem(
                  context,
                  'ربح المهندس',
                  '${entry.engineerProfit.toStringAsFixed(2)} ريال',
                  Icons.engineering_outlined,
                  isDark ? Colors.amber.shade300 : Colors.amber.shade600,
                  isDark,
                ),
                const SizedBox(height: 8),
                _buildSummaryItem(
                  context,
                  'ربح المدير',
                  '${entry.managerProfit.toStringAsFixed(2)} ريال',
                  Icons.business_center_outlined,
                  isDark ? Colors.green.shade300 : Colors.green.shade600,
                  isDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value,
      IconData icon, Color color, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.grey.shade800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context,
      Entry entry,
      bool isDark,
      Color primaryColor,
      EntryFormHelper entryFormHelper,
      EntryProvider entryProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              // فتح مربع حوار التعديل
              entryFormHelper.showEntryInputDialog(context, entry: entry);
            },
            icon: const Icon(Icons.edit_outlined, size: 20),
            label: Text(
              'تعديل',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: isDark ? 0 : 2,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              // تأكيد الحذف
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) {
                  final localIsDark =
                      Theme.of(context).brightness == Brightness.dark;
                  final dialogBgColor =
                      localIsDark ? Colors.grey.shade800 : Colors.white;

                  return AlertDialog(
                    backgroundColor: dialogBgColor,
                    title: Text(
                      'تأكيد الحذف',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            localIsDark ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                    content: Text(
                      'هل أنت متأكد أنك تريد حذف هذا الإدخال؟',
                      style: TextStyle(
                        color: localIsDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade700,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(
                          'إلغاء',
                          style: TextStyle(
                            color: localIsDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(
                          'حذف',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );

              if (confirm == true) {
                // حذف الإدخال وعرض رسالة
                entryProvider.deleteEntry(entry.id);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'تم حذف الإدخال بنجاح',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      backgroundColor: Colors.red.shade700,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                  );

                  // العودة للشاشة السابقة
                  Navigator.pop(context);
                }
              }
            },
            icon: const Icon(Icons.delete_outline, size: 20),
            label: Text(
              'حذف',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: isDark ? 0 : 2,
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(
      BuildContext context, String label, String value, Color valueColor,
      {bool isHighlighted = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textLabelColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;

    return TableRow(
      decoration: isHighlighted
          ? BoxDecoration(
              color: isDark
                  ? Colors.blue.shade900.withOpacity(0.15)
                  : Colors.blue.shade50,
              border: Border(
                bottom: BorderSide(
                    color: isDark
                        ? Colors.blue.shade700.withOpacity(0.3)
                        : Colors.blue.shade200,
                    width: 1),
                top: BorderSide(
                    color: isDark
                        ? Colors.blue.shade700.withOpacity(0.3)
                        : Colors.blue.shade200,
                    width: 1),
              ),
            )
          : null,
      children: [
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.bold,
                color: isHighlighted
                    ? (isDark ? Colors.blue.shade300 : Colors.blue.shade700)
                    : textLabelColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.w500,
                color: isHighlighted
                    ? (isDark ? Colors.blue.shade300 : Colors.blue.shade700)
                    : valueColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ],
    );
  }

  void _showInfoDialog(BuildContext context, bool isDark) {
    final dialogBgColor = isDark ? Colors.grey.shade800 : Colors.white;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: dialogBgColor,
        title: Text(
          'معلومات الإدخال',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey.shade800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem('المنتج', entry.item, isDark),
            _buildInfoItem(
                'التاريخ', DateFormat('yyyy-MM-dd').format(entry.date), isDark),
            _buildInfoItem('رقم التعريف', entry.id, isDark),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'إغلاق',
              style: TextStyle(
                color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
