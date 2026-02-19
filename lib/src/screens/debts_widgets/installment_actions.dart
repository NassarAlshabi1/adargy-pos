// هذا الملف سيحتوي على جميع الإجراءات المتعلقة بالأقساط

import 'package:flutter/material.dart';
import '../../services/db/database_service.dart';
import '../debts_screen.dart';

/// فئة لإدارة إجراءات الأقساط
class InstallmentActions {
  /// معالجة الإجراءات المختارة من القائمة
  static void handleAction({
    required BuildContext context,
    required String value,
    required Map<String, dynamic> installment,
    required DatabaseService db,
  }) {
    // البحث عن DebtsScreen state
    final state = context.findAncestorStateOfType<DebtsScreenState>();
    if (state == null) {
      return;
    }

    switch (value) {
      case 'pay':
        state.showPayInstallmentDialog(context, installment, db);
        break;
      case 'edit':
        state.editInstallment(context, installment, db);
        break;
      case 'print':
        state.printInstallmentReport(context, installment, db);
        break;
      case 'delete':
        state.deleteInstallment(context, installment, db);
        break;
    }
  }

  /// عرض تفاصيل العميل من القسط
  static void showCustomerDetails(
    BuildContext context,
    Map<String, dynamic> installment,
    DatabaseService db,
  ) {
    final state = context.findAncestorStateOfType<DebtsScreenState>();
    if (state == null) {
      return;
    }

    // الحصول على بيانات العميل من القسط
    final customerId = installment['customer_id'] as int?;
    if (customerId != null) {
      db.getCustomers().then((customers) {
        final customer = customers.firstWhere(
          (c) => c['id'] == customerId,
          orElse: () => <String, dynamic>{},
        );
        if (customer.isNotEmpty) {
          state.showCustomerDetailedPreview(context, customer, db);
        }
      });
    }
  }
}
