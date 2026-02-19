import 'package:flutter/material.dart';
import '../../services/db/database_service.dart';
import '../../utils/format.dart';

/// تبويب التقارير
class ReportsTab extends StatelessWidget {
  final DatabaseService db;

  const ReportsTab({
    super.key,
    required this.db,
  });

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String count,
    String amount,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // إحصائيات الأقساط
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إحصائيات الأقساط',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<Map<String, dynamic>>(
                    future: db.getInstallmentStatistics(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final stats = snapshot.data!;
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  'إجمالي الأقساط',
                                  '${stats['total_count']}',
                                  Formatters.currencyIQD(stats['total_amount']),
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  'المدفوعة',
                                  '${stats['paid_count']}',
                                  Formatters.currencyIQD(stats['paid_amount']),
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  'غير المدفوعة',
                                  '${stats['unpaid_count']}',
                                  Formatters.currencyIQD(
                                      stats['unpaid_amount']),
                                  Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: _buildStatCard(
                                  context,
                                  'المتأخرة',
                                  '${stats['overdue_count']}',
                                  Formatters.currencyIQD(
                                      stats['overdue_amount']),
                                  Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // الأقساط المتأخرة
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الأقساط المتأخرة',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: db.getOverdueInstallments(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final overdueInstallments = snapshot.data!;

                      if (overdueInstallments.isEmpty) {
                        return const Center(
                          child: Text(
                            'لا توجد أقساط متأخرة',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: overdueInstallments.length,
                        itemBuilder: (context, index) {
                          final installment = overdueInstallments[index];
                          final daysOverdue =
                              (installment['days_overdue'] as num).toInt();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: Colors.red.shade50,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFFEE2E2),
                                child: Icon(
                                  Icons.warning,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                installment['customer_name'] ?? 'غير محدد',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'المبلغ: ${Formatters.currencyIQD(installment['amount'])}'),
                                  Text('متأخر $daysOverdue يوم'),
                                ],
                              ),
                              trailing: Text(
                                '${DateTime.parse(installment['due_date']).day}/${DateTime.parse(installment['due_date']).month}/${DateTime.parse(installment['due_date']).year}',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // الأقساط المستحقة هذا الشهر
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الأقساط المستحقة هذا الشهر',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: db.getCurrentMonthInstallments(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final currentMonthInstallments = snapshot.data!;

                      if (currentMonthInstallments.isEmpty) {
                        return const Center(
                          child: Text(
                            'لا توجد أقساط مستحقة هذا الشهر',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: currentMonthInstallments.length,
                        itemBuilder: (context, index) {
                          final installment = currentMonthInstallments[index];
                          final dueDate =
                              DateTime.parse(installment['due_date']);
                          final isOverdue = dueDate.isBefore(DateTime.now());

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: isOverdue
                                ? Colors.orange.shade50
                                : Colors.blue.shade50,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isOverdue
                                    ? Colors.orange.shade100
                                    : Colors.blue.shade100,
                                child: Icon(
                                  isOverdue ? Icons.warning : Icons.schedule,
                                  color:
                                      isOverdue ? Colors.orange : Colors.blue,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                installment['customer_name'] ?? 'غير محدد',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                  'المبلغ: ${Formatters.currencyIQD(installment['amount'])}'),
                              trailing: Text(
                                '${dueDate.day}/${dueDate.month}/${dueDate.year}',
                                style: TextStyle(
                                  color:
                                      isOverdue ? Colors.orange : Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
