import 'package:flutter/material.dart';
import '../../services/db/database_service.dart';
import '../debts_widgets/customer_debt_card.dart';

/// تبويب العملاء المدفوعين بالكامل
class FullyPaidCustomersTab extends StatelessWidget {
  final DatabaseService db;
  final String searchQuery;
  final int refreshKey;

  const FullyPaidCustomersTab({
    super.key,
    required this.db,
    required this.searchQuery,
    required this.refreshKey,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey('fully_paid_$refreshKey'),
      future: db.getCustomers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Map<String, dynamic>> customers = snapshot.data!;

        // تصفية العملاء حسب البحث
        if (searchQuery.isNotEmpty) {
          customers = customers.where((customer) {
            return customer['name']
                .toString()
                .toLowerCase()
                .contains(searchQuery.toLowerCase());
          }).toList();
        }

        if (customers.isEmpty) {
          return Center(
            child: Text(
              'لا توجد عملاء',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: customers.length,
          itemBuilder: (context, index) {
            final customer = customers[index];
            return CustomerDebtCard(
              context: context,
              customer: customer,
              db: db,
              refreshKey: refreshKey,
              showOnlyFullyPaid: true,
            );
          },
        );
      },
    );
  }
}
