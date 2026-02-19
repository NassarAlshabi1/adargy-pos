import '../../services/db/database_service.dart';

/// دوال مساعدة لشاشة الديون
class DebtsHelpers {
  /// الحصول على بيانات دين العميل
  static Future<Map<String, dynamic>> getCustomerDebtData(
    int customerId,
    DatabaseService db,
  ) async {
    try {
      // الحصول على بيانات العميل مباشرة
      final customers = await db.getCustomers();
      final customer = customers.firstWhere(
        (c) => c['id'] == customerId,
        orElse: () => {'total_debt': 0.0},
      );

      // الحصول على المدفوعات
      final payments = await db.getCustomerPayments(customerId: customerId);
      double totalPaid = 0;
      for (final payment in payments) {
        totalPaid += (payment['amount'] as num).toDouble();
      }

      // total_debt في جدول العملاء يحتوي على المتبقي بعد المدفوعات
      // لذلك نحتاج لحساب إجمالي الدين الأصلي
      final remainingDebt = (customer['total_debt'] as num).toDouble();
      final originalDebt = remainingDebt + totalPaid;

      return {
        'totalDebt': originalDebt,
        'totalPaid': totalPaid,
        'remainingDebt': remainingDebt,
      };
    } catch (e) {
      return {
        'totalDebt': 0.0,
        'totalPaid': 0.0,
        'remainingDebt': 0.0,
      };
    }
  }

  /// الحصول على تفاصيل الأقساط للعميل
  static Future<List<Map<String, dynamic>>> getCustomerInstallments(
    int customerId,
    DatabaseService db,
  ) async {
    try {
      final installments = await db.getInstallments(customerId: customerId);
      return installments.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// الحصول على أنواع الديون للعميل (credit أو installment أو كليهما)
  static Future<Map<String, bool>> getCustomerDebtTypes(
    int customerId,
    DatabaseService db,
  ) async {
    try {
      // التحقق من وجود ديون آجلة (credit) غير مدفوعة
      final creditSales = await db.creditSales(customerId: customerId);
      final hasCreditDebt = creditSales.isNotEmpty;
      // نتحقق من وجود أي بيع آجل، لأن creditSales ترجع فقط المبيعات الآجلة

      // التحقق من وجود ديون بالأقساط (installment) غير مدفوعة
      final installments = await db.getInstallments(customerId: customerId);
      final hasInstallmentDebt = installments.isNotEmpty &&
          installments.any((inst) {
            final paid = (inst['paid'] as int?) ?? 0;
            return paid == 0; // قسط غير مدفوع
          });

      return {
        'hasCredit': hasCreditDebt,
        'hasInstallment': hasInstallmentDebt,
      };
    } catch (e) {
      return {
        'hasCredit': false,
        'hasInstallment': false,
      };
    }
  }

  /// حساب ملخص الأقساط
  static Future<Map<String, double>> getInstallmentsSummary(
    DatabaseService db,
  ) async {
    try {
      final installments = await db.getInstallments();
      double installmentTotal = 0.0;
      double creditTotal = 0.0;

      for (final installment in installments) {
        final amount = (installment['amount'] as num?)?.toDouble() ?? 0.0;
        final saleType = installment['sale_type']?.toString();

        if (saleType == 'installment') {
          installmentTotal += amount;
        } else if (saleType == 'credit') {
          creditTotal += amount;
        }
      }

      return {
        'installment': installmentTotal,
        'credit': creditTotal,
      };
    } catch (e) {
      return {'installment': 0.0, 'credit': 0.0};
    }
  }

  /// الحصول على معرف منتج الدين أو إنشاؤه إذا لم يكن موجوداً
  static Future<int> getDebtProductId(DatabaseService db) async {
    try {
      // البحث عن منتج الدين الموجود
      final existingProducts = await db.database.query(
        'products',
        where: 'name = ? AND category_id IS NULL',
        whereArgs: ['دين/قرض'],
        limit: 1,
      );

      if (existingProducts.isNotEmpty) {
        return existingProducts.first['id'] as int;
      }

      // إنشاء منتج الدين إذا لم يكن موجوداً
      final productId = await db.database.insert('products', {
        'name': 'دين/قرض',
        'description': 'منتج وهمي لتمثيل الديون والقروض',
        'price': 0.0,
        'cost': 0.0,
        'quantity': 999999, // كمية كبيرة جداً
        'min_quantity': 0,
        'barcode': 'DEBT_PRODUCT',
        'category_id': null,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      return productId;
    } catch (e) {
      // في حالة الخطأ، إرجاع معرف افتراضي
      return 1; // معرف افتراضي
    }
  }
}
