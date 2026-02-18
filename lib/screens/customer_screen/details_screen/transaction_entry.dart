import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:daily/database/customer_database_helper.dart';
import 'package:daily/models/customer.dart';

class TransactionDialogContent extends StatefulWidget {
  final Function setStateDialog;
  final int customerId;
  final CustomerDatabaseHelper dbHelper;
  final Future<void> Function() loadTransactions;
  final TransactionEntry? transaction;
  final String? defaultCurrency; // معامل جديد لتمرير العملة الافتراضية

  const TransactionDialogContent({
    super.key,
    required this.setStateDialog,
    required this.customerId,
    required this.dbHelper,
    required this.loadTransactions,
    this.transaction,
    this.defaultCurrency, // إضافة العملة الافتراضية كمعامل اختياري
  });

  @override
  _TransactionDialogContentState createState() =>
      _TransactionDialogContentState();
}

class _TransactionDialogContentState extends State<TransactionDialogContent> {
  late TextEditingController amountController;
  late TextEditingController detailsController;
  late String selectedCurrency;
  late DateTime selectedDate;
  late bool isLeh;
  late bool isAlaih;

  @override
  void initState() {
    super.initState();
    // Initialize values from transaction if exists
    amountController = TextEditingController(
        text: widget.transaction?.amount.toString() ?? '');
    detailsController =
        TextEditingController(text: widget.transaction?.item ?? '');
    // استخدام العملة من المعاملة إذا كانت موجودة، وإلا استخدام العملة الافتراضية إذا تم تمريرها، وإلا استخدام 'محلي'
    selectedCurrency =
        widget.transaction?.currency ?? widget.defaultCurrency ?? 'محلي';
    selectedDate = widget.transaction?.date ?? DateTime.now();
    isLeh = widget.transaction?.isCredit ?? true;
    isAlaih = !isLeh;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.blue.shade300 : Colors.blue.shade700;
    final textColor = isDark ? Colors.white : Colors.black87;
    final formBackgroundColor = isDark ? Colors.grey.shade800 : Colors.white;
    final cardColor = isDark ? Colors.grey.shade900 : Colors.grey.shade50;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: formBackgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  labelText: 'المبلغ',
                  labelStyle: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                  prefixIcon: Icon(Icons.attach_money, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: cardColor,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: detailsController,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  labelText: 'التفاصيل',
                  labelStyle: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                  prefixIcon: Icon(Icons.description, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: cardColor,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(16),
                        color: cardColor,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today,
                              color: primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'التاريخ: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              style: TextStyle(
                                fontSize: 15,
                                color: textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.date_range,
                          color: Colors.white, size: 20),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          widget.setStateDialog(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          widget.setStateDialog(() {
                            isLeh = !isLeh;
                            if (isLeh) {
                              isAlaih = false;
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 4),
                          decoration: BoxDecoration(
                            color: isLeh
                                ? (isDark
                                    ? Colors.green.shade900
                                    : Colors.green.shade50)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: isLeh
                                ? Border.all(
                                    color: isDark
                                        ? Colors.green.shade300
                                        : Colors.green)
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  value: isLeh,
                                  activeColor: isDark
                                      ? Colors.green.shade300
                                      : Colors.green,
                                  checkColor:
                                      isDark ? Colors.black : Colors.white,
                                  onChanged: (value) {
                                    widget.setStateDialog(() {
                                      isLeh = value ?? false;
                                      if (isLeh) {
                                        isAlaih = false;
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'له',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isLeh
                                      ? (isDark
                                          ? Colors.green.shade300
                                          : Colors.green.shade700)
                                      : textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          widget.setStateDialog(() {
                            isAlaih = !isAlaih;
                            if (isAlaih) {
                              isLeh = false;
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 4),
                          decoration: BoxDecoration(
                            color: isAlaih
                                ? (isDark
                                    ? Colors.red.shade900
                                    : Colors.red.shade50)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: isAlaih
                                ? Border.all(
                                    color: isDark
                                        ? Colors.red.shade300
                                        : Colors.red)
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  value: isAlaih,
                                  activeColor:
                                      isDark ? Colors.red.shade300 : Colors.red,
                                  checkColor:
                                      isDark ? Colors.black : Colors.white,
                                  onChanged: (value) {
                                    widget.setStateDialog(() {
                                      isAlaih = value ?? false;
                                      if (isAlaih) {
                                        isLeh = false;
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'عليه',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isAlaih
                                      ? (isDark
                                          ? Colors.red.shade300
                                          : Colors.red.shade700)
                                      : textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  double amount = double.tryParse(amountController.text) ?? 0.0;
                  if (!isLeh && !isAlaih) {
                    isLeh = true;
                  }

                  if (amount.abs() > 0) {
                    final newTransaction = TransactionEntry(
                      id: widget.transaction?.id,
                      customerId: widget.customerId,
                      date: selectedDate,
                      item: detailsController.text,
                      amount: amount.abs(),
                      currency: selectedCurrency,
                      isCredit: isLeh, // "له" = دائن، "عليه" = مدين
                    );
                    if (widget.transaction != null) {
                      await widget.dbHelper.updateTransaction(newTransaction);
                    } else {
                      await widget.dbHelper.insertTransaction(newTransaction);
                    }
                    widget.loadTransactions();
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
                child: Text(
                  'حفظ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
