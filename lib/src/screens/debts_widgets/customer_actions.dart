// هذا الملف سيحتوي على جميع الإجراءات المتعلقة بالعملاء

import 'package:flutter/material.dart';
import '../../services/db/database_service.dart';
import '../debts_screen.dart';

/// فئة لإدارة إجراءات العملاء
/// تم تحميل الدوال من DebtsScreen مباشرة عبر context
class CustomerActions {
  /// معالجة الإجراءات المختارة من القائمة
  static void handleAction({
    required BuildContext context,
    required String value,
    required Map<String, dynamic> customer,
    required DatabaseService db,
  }) {
    // البحث عن DebtsScreen state
    final state = context.findAncestorStateOfType<DebtsScreenState>();
    if (state == null) {
      return;
    }

    switch (value) {
      case 'payments':
        state.showCustomerPayments(context, customer, db);
        break;
      case 'add_payment':
        state.showAddPaymentDialog(context, db, customer: customer);
        break;
      case 'add_debt':
        state.showAddDebtDialog(context, db, customer: customer);
        break;
      case 'add_installment':
        state.showAddInstallmentDialog(context, db, customer: customer);
        break;
      case 'print_statement':
        state.printCustomerStatement(context, customer, db);
        break;
      case 'view_installments':
        state.showCustomerInstallments(context, customer, db);
        break;
      case 'delete':
        state.showDeleteCustomerDialog(context, customer, db);
        break;
    }
  }

  /// عرض تفاصيل العميل
  static void showCustomerDetails(
    BuildContext context,
    Map<String, dynamic> customer,
    DatabaseService db,
  ) {
    final state = context.findAncestorStateOfType<DebtsScreenState>();
    if (state == null) {
      return;
    }

    state.showCustomerDetailedPreview(context, customer, db);
  }
}
