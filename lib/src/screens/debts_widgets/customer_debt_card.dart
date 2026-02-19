import 'package:flutter/material.dart';
import '../../services/db/database_service.dart';
import '../../utils/format.dart';
import 'debts_helpers.dart';
import 'customer_actions.dart';

/// بطاقة دين العميل
class CustomerDebtCard extends StatelessWidget {
  final BuildContext context;
  final Map<String, dynamic> customer;
  final DatabaseService db;
  final int refreshKey;
  final bool showOnlyDebtors;
  final bool showOnlyPaid;
  final bool showOnlyFullyPaid;

  const CustomerDebtCard({
    super.key,
    required this.context,
    required this.customer,
    required this.db,
    required this.refreshKey,
    this.showOnlyDebtors = false,
    this.showOnlyPaid = false,
    this.showOnlyFullyPaid = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: FutureBuilder<Map<String, dynamic>>(
        key: ValueKey('customer_debt_${customer['id']}_$refreshKey'),
        future: DebtsHelpers.getCustomerDebtData(customer['id'], db),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const ListTile(
              title: Text('جاري التحميل...'),
              leading: CircularProgressIndicator(),
            );
          }

          final debtData = snapshot.data!;
          final remaining = debtData['remainingDebt'] ?? 0.0;

          // تصفية حسب نوع التبويب
          if (showOnlyDebtors && remaining <= 0) {
            return const SizedBox.shrink(); // إخفاء العملاء المدفوعين
          }
          if (showOnlyPaid && remaining > 0) {
            return const SizedBox.shrink(); // إخفاء العملاء الذين لديهم ديون
          }
          if (showOnlyFullyPaid && remaining > 0) {
            return const SizedBox
                .shrink(); // إخفاء العملاء الذين لديهم ديون (المدفوعين بالكامل فقط)
          }

          return FutureBuilder<Map<String, bool>>(
            future: DebtsHelpers.getCustomerDebtTypes(customer['id'], db),
            builder: (context, debtTypesSnapshot) {
              final hasCredit = debtTypesSnapshot.data?['hasCredit'] ?? false;
              final hasInstallment =
                  debtTypesSnapshot.data?['hasInstallment'] ?? false;

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: remaining > 0
                      ? Colors.red.shade100
                      : Colors.green.shade100,
                  child: Icon(
                    remaining > 0 ? Icons.warning : Icons.check_circle,
                    color: remaining > 0 ? Colors.red : Colors.green,
                    size: 16,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        customer['name'] ?? 'غير محدد',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // علامة الدين الآجل (credit)
                    if (hasCredit)
                      Tooltip(
                        message: 'دين آجل',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_long,
                                  size: 12, color: Colors.orange.shade700),
                              const SizedBox(width: 4),
                              Text(
                                'آجل',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // علامة الدين بالأقساط (installment)
                    if (hasInstallment) ...[
                      const SizedBox(width: 4),
                      Tooltip(
                        message: 'دين بالأقساط',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule,
                                  size: 12, color: Colors.blue.shade700),
                              const SizedBox(width: 4),
                              Text(
                                'قسط',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الهاتف: ${customer['phone'] ?? 'غير محدد'}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'المتبقي: ',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          Formatters.currencyIQD(remaining),
                          style: TextStyle(
                            color: remaining > 0 ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    CustomerActions.handleAction(
                      context: context,
                      value: value,
                      customer: customer,
                      db: db,
                    );
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'payments',
                      child: Row(
                        children: [
                          Icon(Icons.history, size: 16),
                          SizedBox(width: 8),
                          Text('سجل المدفوعات'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'add_payment',
                      child: Row(
                        children: [
                          Icon(Icons.payment, size: 16, color: Colors.green),
                          SizedBox(width: 8),
                          Text('إضافة دفعة',
                              style: TextStyle(color: Colors.green)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'add_debt',
                      child: Row(
                        children: [
                          Icon(Icons.add_card, size: 16, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('إضافة دين',
                              style: TextStyle(color: Colors.orange)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'add_installment',
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: Colors.purple),
                          SizedBox(width: 8),
                          Text('إضافة دين بالأقساط',
                              style: TextStyle(color: Colors.purple)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'print_statement',
                      child: Row(
                        children: [
                          Icon(Icons.print, size: 16, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('طباعة كشف حساب',
                              style: TextStyle(color: Colors.blue)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'view_installments',
                      child: Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: Colors.indigo),
                          SizedBox(width: 8),
                          Text('عرض الأقساط',
                              style: TextStyle(color: Colors.indigo)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('حذف العميل',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  CustomerActions.showCustomerDetails(context, customer, db);
                },
              );
            },
          );
        },
      ),
    );
  }
}
