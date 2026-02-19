import 'package:flutter/material.dart';
import '../../services/db/database_service.dart';
import '../../utils/format.dart';
import 'installment_actions.dart';

/// بطاقة القسط
class InstallmentCard extends StatelessWidget {
  final BuildContext context;
  final Map<String, dynamic> installment;
  final DatabaseService db;

  const InstallmentCard({
    super.key,
    required this.context,
    required this.installment,
    required this.db,
  });

  @override
  Widget build(BuildContext context) {
    final dueDate = DateTime.parse(installment['due_date'] as String);
    final isOverdue = dueDate.isBefore(DateTime.now());
    final isPaid = (installment['paid'] as int) == 1;
    final amount = (installment['amount'] as num).toDouble();
    final customerName = installment['customer_name'] ?? 'غير محدد';

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 1,
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: isPaid
              ? Colors.green.shade100
              : isOverdue
                  ? Colors.red.shade100
                  : Colors.orange.shade100,
          child: Icon(
            isPaid
                ? Icons.check_circle
                : isOverdue
                    ? Icons.warning
                    : Icons.schedule,
            color: isPaid
                ? Colors.green
                : isOverdue
                    ? Colors.red
                    : Colors.orange,
            size: 16,
          ),
        ),
        title: Text(
          customerName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المبلغ: ${Formatters.currencyIQD(amount)}',
                style: const TextStyle(fontSize: 11)),
            Text(
                'تاريخ الاستحقاق: ${dueDate.day}/${dueDate.month}/${dueDate.year}',
                style: const TextStyle(fontSize: 11)),
            if (isPaid)
              Text(
                'تم الدفع في: ${DateTime.parse(installment['paid_at'] as String).day}/${DateTime.parse(installment['paid_at'] as String).month}/${DateTime.parse(installment['paid_at'] as String).year}',
                style: const TextStyle(color: Colors.green, fontSize: 11),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            InstallmentActions.handleAction(
              context: context,
              value: value,
              installment: installment,
              db: db,
            );
          },
          itemBuilder: (context) => [
            if (!isPaid) ...[
              const PopupMenuItem(
                value: 'pay',
                child: Row(
                  children: [
                    Icon(Icons.payment, size: 16, color: Colors.green),
                    SizedBox(width: 8),
                    Text('دفع القسط'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('تعديل القسط'),
                  ],
                ),
              ),
            ],
            const PopupMenuItem(
              value: 'print',
              child: Row(
                children: [
                  Icon(Icons.print, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('طباعة كشف القسط'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('حذف القسط'),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          InstallmentActions.showCustomerDetails(context, installment, db);
        },
      ),
    );
  }
}
