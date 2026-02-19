import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:alhaytham_trade/models/customer.dart';
import 'package:alhaytham_trade/database/customer_database_helper.dart';
import 'package:alhaytham_trade/screens/customer_screen/details_screen/transaction_entry.dart';

/// Utility functions for dialog operations in the customer detail screen

/// Show PDF options dialog
Future<void> showPdfOptionsDialog(
  BuildContext context,
  dynamic pdfFile,
  Function viewPdf,
  Function printPdf,
  Function savePdf,
) async {
  return showModalBottomSheet<void>(
    context: context,
    builder: (BuildContext context) {
      return Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تم إنشاء التقرير بنجاح',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'ماذا تريد أن تفعل بالتقرير؟',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // View report
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      viewPdf(pdfFile);
                    },
                    icon: const Icon(Icons.visibility),
                    label: Text('عرض', style: TextStyle()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                  // Print report
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      printPdf(pdfFile);
                    },
                    icon: const Icon(Icons.print),
                    label: Text('طباعة', style: TextStyle()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                  // Save report
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      savePdf(pdfFile);
                    },
                    icon: const Icon(Icons.save_alt),
                    label: Text('حفظ', style: TextStyle()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Show edit transaction dialog
void showEditTransactionDialog(
  BuildContext context,
  TransactionEntry transaction,
  int customerId,
  CustomerDatabaseHelper dbHelper,
  Future<void> Function() loadTransactions,
) {
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
              title: const Center(child: Text('تعديل العملية')),
              content: TransactionDialogContent(
                setStateDialog: setStateDialog,
                customerId: customerId,
                dbHelper: dbHelper,
                loadTransactions: loadTransactions,
                transaction: transaction,
              ),
            ),
          );
        },
      );
    },
  );
}

/// Show add transaction dialog
void showAddTransactionDialog(
  BuildContext context,
  int customerId,
  CustomerDatabaseHelper dbHelper,
  Future<void> Function() loadTransactions,
  String defaultCurrency,
) {
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return Directionality(
            textDirection: ui.TextDirection.rtl,
            child: AlertDialog(
              shape: const RoundedRectangleBorder(),
              title: const Center(
                child: Text(
                  'اضافه  ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              content: TransactionDialogContent(
                setStateDialog: setStateDialog,
                customerId: customerId,
                dbHelper: dbHelper,
                loadTransactions: loadTransactions,
                defaultCurrency: defaultCurrency,
              ),
            ),
          );
        },
      );
    },
  );
}

/// Show delete transaction confirmation dialog
Future<bool> showDeleteTransactionDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('حذف العميلة'),
          content: const Text('هل أنت متأكد من حذف هذه العملية ؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ) ??
      false;
}
