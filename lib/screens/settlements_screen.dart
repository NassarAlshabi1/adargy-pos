import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import '../database/customer_database_helper.dart';
import '../models/customer.dart';

class SettlementsScreen extends StatefulWidget {
  const SettlementsScreen({Key? key}) : super(key: key);

  @override
  State<SettlementsScreen> createState() => _SettlementsScreenState();
}

class _SettlementsScreenState extends State<SettlementsScreen> {
  final CustomerDatabaseHelper _dbHelper = CustomerDatabaseHelper();
  List<Customer> _settledCustomers = [];
  List<Map<String, dynamic>> _settlements = [];
  bool _isLoading = true;

  // دالة لمعالجة النص المختلط (عربي + إنجليزي)
  String _processMixedText(String text) {
    // التحقق من وجود حروف عربية في النص
    bool hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    // التحقق من وجود حروف إنجليزية في النص
    bool hasEnglish = RegExp(r'[a-zA-Z]').hasMatch(text);

    // إذا كان النص يحتوي على حروف عربية وإنجليزية معاً
    if (hasArabic && hasEnglish) {
      // إضافة علامة LRM (Left-to-Right Mark) قبل الحروف الإنجليزية
      String processedText = text;
      // إضافة LRM قبل كل مجموعة من الحروف الإنجليزية
      processedText = processedText.replaceAllMapped(
          RegExp(r'[a-zA-Z]+'), (match) => '\u200E${match.group(0)}\u200E');
      return processedText;
    }

    return text;
  }

  // معالجة النص المختلط (عربي + إنجليزي)
  String fixMixedText(String text) {
    const lrm = '\u200E'; // Left-to-Right Mark
    return text.replaceAllMapped(
      RegExp(r'[A-Za-z0-9.\s\-_/\\]+'),
      (match) => lrm + match.group(0)!,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSettlements();
  }

  Future<void> _loadSettlements() async {
    try {
      final settledCustomers = await _dbHelper.getSettledCustomers();
      final settlements = await _dbHelper.getAllSettlements();

      // تحميل معاملات كل عميل مسدد
      for (var customer in settledCustomers) {
        customer.transactions = await _dbHelper.getTransactions(customer.id);
      }

      setState(() {
        _settledCustomers = settledCustomers;
        _settlements = settlements;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ أثناء تحميل السدادات: $e',
            style: TextStyle(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _restoreCustomer(Customer customer) async {
    try {
      bool confirm = await showDialog(
        context: context,
        builder: (context) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            title: Text(
              'إعادة العميل',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'هل أنت متأكد من إعادة العميل ${customer.name} إلى قائمة العملاء؟',
              style: TextStyle(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('إلغاء', style: TextStyle()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('تأكيد', style: TextStyle()),
              ),
            ],
          ),
        ),
      );

      if (confirm == true) {
        await _dbHelper.unmarkCustomerAsSettled(customer.id);
        _loadSettlements();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم إعادة العميل ${customer.name} إلى قائمة العملاء',
              style: TextStyle(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ أثناء إعادة العميل: $e',
            style: TextStyle(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _settledCustomers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payment_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا توجد سدادات مسجلة',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadSettlements,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _settledCustomers.length,
                    itemBuilder: (context, index) {
                      final customer = _settledCustomers[index];
                      final settlement = _settlements.firstWhere(
                        (s) => s['customerId'] == customer.id,
                        orElse: () => {},
                      );

                      return Card(
                        elevation: isDark ? 2 : 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () =>
                              _showCustomerDetails(customer, settlement),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  isDark
                                      ? Colors.grey.shade800
                                      : Colors.green.shade50,
                                  isDark
                                      ? Colors.grey.shade900
                                      : Colors.green.shade100,
                                ],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // العنوان والتاريخ
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.green.shade600,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'تم تسديد المبلغ  ',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (settlement.isNotEmpty)
                                        Text(
                                          DateFormat('yyyy/MM/dd - HH:mm')
                                              .format(
                                            DateTime.parse(
                                                settlement['settlementDate']),
                                          ),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // معلومات العميل
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.grey.shade700
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.person_outline,
                                              size: 18,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'اسم العميل:',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                customer.name,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        if (settlement.isNotEmpty)
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.monetization_on_outlined,
                                                size: 18,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'المبلغ المسدد:',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${settlement['settledAmount'].toStringAsFixed(0)} ${settlement['currency']}',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.receipt_long_outlined,
                                              size: 18,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'عدد المعاملات:',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${customer.transactions.length}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // أزرار العمليات
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // زر الحذف
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            _deleteSettledCustomer(customer),
                                        icon:
                                            const Icon(Icons.delete, size: 16),
                                        label: Text(
                                          'حذف نهائي',
                                          style:
                                              TextStyle(fontSize: 12),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.shade600,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                      // زر إعادة العميل
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            _restoreCustomer(customer),
                                        icon: const Icon(Icons.undo, size: 16),
                                        label: Text(
                                          'إعادة للعملاء',
                                          style:
                                              TextStyle(fontSize: 12),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.orange.shade600,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _showCustomerDetails(
      Customer customer, Map<String, dynamic> settlement) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.person,
                color: Colors.green.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'تفاصيل العميل المسدد',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // معلومات العميل الأساسية
                _buildDetailCard(
                  title: 'معلومات العميل',
                  icon: Icons.person_outline,
                  color: Colors.blue,
                  children: [
                    _buildDetailRow('الاسم:', customer.name),
                    _buildDetailRow('معرف العميل:', customer.id.toString()),
                    _buildDetailRow('عدد المعاملات:',
                        customer.transactions.length.toString()),
                  ],
                  isDark: isDark,
                ),

                const SizedBox(height: 16),

                // معلومات السداد
                if (settlement.isNotEmpty)
                  _buildDetailCard(
                    title: 'معلومات السداد',
                    icon: Icons.payment,
                    color: Colors.green,
                    children: [
                      _buildDetailRow('المبلغ المسدد:',
                          '${settlement['settledAmount'].toStringAsFixed(0)} ${settlement['currency']}'),
                      _buildDetailRow(
                          'تاريخ السداد:',
                          DateFormat('yyyy/MM/dd - HH:mm').format(
                              DateTime.parse(settlement['settlementDate']))),
                    ],
                    isDark: isDark,
                  ),

                const SizedBox(height: 16),

                // تفاصيل المعاملات
                if (customer.transactions.isNotEmpty)
                  _buildDetailCard(
                    title: 'تفاصيل المعاملات',
                    icon: Icons.receipt_long,
                    color: Colors.orange,
                    children: [
                      ...customer.transactions
                          .take(5)
                          .map((transaction) =>
                              _buildTransactionRow(transaction, isDark))
                          .toList(),
                      if (customer.transactions.length > 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'وعدد ${customer.transactions.length - 5} معاملة أخرى...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                    isDark: isDark,
                  ),
              ],
            ),
          ),
          actions: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _restoreCustomer(customer);
                      },
                      icon: const Icon(Icons.undo, size: 16),
                      label: Text(
                        'إعادة للعملاء',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteSettledCustomer(customer);
                      },
                      icon: const Icon(Icons.delete, size: 16),
                      label: Text(
                        'حذف نهائي',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'إغلاق',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSettledCustomer(Customer customer) async {
    try {
      bool confirm = await showDialog(
        context: context,
        builder: (context) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            title: Text(
              'حذف العميل نهائياً',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'هل أنت متأكد من حذف العميل ${customer.name} نهائياً؟\n\nسيتم حذف:\n• بيانات العميل\n• جميع المعاملات\n• سجل السداد\n\nلا يمكن التراجع عن هذه العملية.',
              style: TextStyle(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('إلغاء', style: TextStyle()),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
                child: Text('حذف نهائي', style: TextStyle()),
              ),
            ],
          ),
        ),
      );

      if (confirm == true) {
        // حذف العميل وجميع بياناته المرتبطة
        await _dbHelper.deleteCustomer(customer.id);

        // إعادة تحميل البيانات
        _loadSettlements();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حذف العميل ${customer.name} وجميع بياناته نهائياً',
              style: TextStyle(),
            ),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ أثناء حذف العميل: $e',
            style: TextStyle(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(TransactionEntry transaction, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade700 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: transaction.isCredit
              ? Colors.green.shade300
              : Colors.red.shade300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _processMixedText(transaction.item),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '${transaction.isCredit ? '+ ' : '- '}${transaction.amount.toStringAsFixed(0)} ${transaction.currency}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: transaction.isCredit
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('yyyy/MM/dd').format(transaction.date),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
