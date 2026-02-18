import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:daily/database/customer_database_helper.dart';
import 'package:daily/models/customer.dart';
import 'package:daily/screens/customer_screen/details_screen/widgets/transaction_table.dart';
import 'package:daily/screens/customer_screen/details_screen/widgets/summary_card.dart';
import 'package:daily/screens/customer_screen/details_screen/utils/pdf_utils.dart';
import 'package:daily/screens/customer_screen/details_screen/utils/dialog_utils.dart';

/// Main screen for displaying customer details and transactions
class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;
  final CustomerDatabaseHelper dbHelper;

  const CustomerDetailScreen({
    super.key,
    required this.customer,
    required this.dbHelper,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  /// Load transactions for the customer
  Future<void> _loadTransactions() async {
    widget.customer.transactions =
        await widget.dbHelper.getTransactions(widget.customer.id);
    setState(() {});
  }

  /// Handle edit transaction
  void _handleEditTransaction(TransactionEntry transaction) {
    showEditTransactionDialog(
      context,
      transaction,
      widget.customer.id,
      widget.dbHelper,
      _loadTransactions,
    );
  }

  /// Handle delete transaction
  void _handleDeleteTransaction(TransactionEntry transaction) async {
    bool confirm = await showDeleteTransactionDialog(context);

    if (confirm) {
      await widget.dbHelper.deleteTransaction(transaction.id!);
      await _loadTransactions();
    }
  }

  /// Show transaction dialog for adding new transactions
  void _showTransactionDialog() {
    // Get currency from customer's last transaction, default to customer.currency
    String customerCurrency = widget.customer.currency;

    if (widget.customer.transactions.isNotEmpty) {
      List<TransactionEntry> sortedTransactions = [
        ...widget.customer.transactions
      ];
      sortedTransactions.sort((a, b) => b.date.compareTo(a.date));
      customerCurrency = sortedTransactions.first.currency;
    }

    showAddTransactionDialog(
      context,
      widget.customer.id,
      widget.dbHelper,
      _loadTransactions,
      customerCurrency,
    );
  }

  /// Handle PDF generation and options
  Future<void> _handlePdfGeneration() async {
    await generateAndSavePdfReport(
      context,
      widget.customer,
      (pdfFile) => showPdfOptionsDialog(
        context,
        pdfFile,
        (file) => viewPdf(context, file, widget.customer.name),
        (file) => printPdf(file),
        (file) => savePdfToDownloads(context, file),
      ),
    );
  }

  /// Show edit customer dialog
  void _showEditCustomerDialog() {
    final nameController = TextEditingController(text: widget.customer.name);
    String selectedCurrency = widget.customer.currency;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Directionality(
              textDirection: ui.TextDirection.rtl,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    const Text(
                      'تعديل بيانات العميل',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'اسم العميل',
                          prefixIcon:
                              Icon(Icons.person, color: Colors.blue.shade700),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.blue.shade700, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'العملة الافتراضية',
                          prefixIcon: Icon(Icons.monetization_on,
                              color: Colors.blue.shade700),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.blue.shade700, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedCurrency,
                            isExpanded: true,
                            items: <String>['YER', 'SAR', 'USD', 'AED']
                                .map((value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value,
                                        style: TextStyle())))
                                .toList(),
                            onChanged: (newValue) {
                              setStateDialog(() {
                                selectedCurrency = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'تغيير العملة الافتراضية سيؤثر على المعاملات الجديدة فقط',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'إلغاء',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final newName = nameController.text.trim();
                      if (newName.isEmpty) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'يرجى إدخال اسم العميل',
                                style: TextStyle(),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }

                      // Update customer data
                      final updatedCustomer = Customer(
                        id: widget.customer.id,
                        name: newName,
                        balance: widget.customer.balance,
                        currency: selectedCurrency,
                        transactions: widget.customer.transactions,
                        isSettled: widget.customer.isSettled,
                      );

                      // Update in database
                      await widget.dbHelper.updateCustomer(updatedCustomer);

                      // Update local customer object
                      if (mounted) {
                        setState(() {
                          widget.customer.name = newName;
                          widget.customer.currency = selectedCurrency;
                        });

                        if (context.mounted) {
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'تم تحديث بيانات العميل بنجاح',
                                style: TextStyle(),
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('حفظ التغييرات', style: TextStyle()),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryColor = Colors.blue.shade700;
    final accentColor = isDark ? Colors.blue.shade300 : Colors.blue.shade600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.customer.name,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? Colors.grey.shade900 : primaryColor,
        elevation: 0,
        actions: [
          // Edit customer button
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'تعديل العميل',
            onPressed: _showEditCustomerDialog,
          ),
          // Generate PDF report button
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'إنشاء تقرير PDF',
            onPressed: _handlePdfGeneration,
          ),
        ],
      ),
      body: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Column(
          children: [
            // Transactions table
            Expanded(
              child: widget.customer.transactions.isEmpty
                  ? _buildEmptyState(isDark)
                  : TransactionTable(
                      transactions: widget.customer.transactions,
                      onEditTransaction: _handleEditTransaction,
                      onDeleteTransaction: _handleDeleteTransaction,
                    ),
            ),

            // Summary card
            SummaryCard(transactions: widget.customer.transactions),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showTransactionDialog,
        backgroundColor: accentColor,
        tooltip: 'إضافة معاملة',
        elevation: 4,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  /// Build empty state widget when no transactions exist
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد معاملات حتى الآن',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
