import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/db/database_service.dart';
import '../services/auth/auth_provider.dart';
import '../utils/format.dart';
import '../utils/dark_mode_utils.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  String _query = '';
  int _refreshKey = 0;

  void _refreshSuppliers() {
    setState(() {
      _refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();
    final scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: DarkModeUtils.getShadowColor(context),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7)),
                  hintText: 'بحث بالاسم أو الهاتف',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor.withOpacity(0.4),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor.withOpacity(0.4),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: scheme.primary, width: 1.5),
                  ),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add),
                label: const Text('إضافة مورد')),
          ]),
        ),
        const SizedBox(height: 12),
        // ملاحظة توضيحية
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(isDark ? 0.10 : 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade400, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'المستحق: هو المبلغ الواجب دفعه للمورد (الحسابات الدائنة). يظهر بالبرتقالي إن كان عليك مستحقات وبالأخضر إن لم يكن.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.orange.shade200
                        : Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<Map<String, Object?>>>(
            key: ValueKey(_refreshKey),
            future: db.getSuppliers(query: _query),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final items = snapshot.data!;

              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                Theme.of(context).dividerColor.withOpacity(0.3),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: DarkModeUtils.getShadowColor(context),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.business_outlined,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'لا يوجد موردين',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _query.isEmpty
                                  ? 'قم بإضافة موردين جدد للبدء'
                                  : 'لم يتم العثور على موردين مطابقين للبحث',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _openEditor(),
                              icon: const Icon(Icons.add),
                              label: const Text('إضافة مورد جديد'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: scheme.primary,
                                foregroundColor: scheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: items.length,
                padding: const EdgeInsets.only(bottom: 12),
                itemBuilder: (context, i) {
                  final s = items[i];
                  final name = s['name']?.toString() ?? '';
                  final phone = s['phone']?.toString() ?? '';
                  final payable =
                      (s['total_payable'] as num?)?.toDouble() ?? 0.0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withOpacity(0.3),
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: null,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: scheme.primaryContainer,
                              child: Icon(Icons.business,
                                  color: scheme.onPrimaryContainer, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: scheme.onSurface),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.phone,
                                          size: 14,
                                          color: DarkModeUtils
                                              .getSecondaryTextColor(context)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          phone.isEmpty ? '-' : phone,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: DarkModeUtils
                                                  .getSecondaryTextColor(
                                                      context)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('المستحق',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            DarkModeUtils.getSecondaryTextColor(
                                                context),
                                        fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text(
                                  Formatters.currencyIQD(payable),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: payable > 0
                                        ? Colors.orange.shade600
                                        : DarkModeUtils.getSuccessColor(
                                            context),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    IconButton(
                                      tooltip: 'سجل المستحقات والمدفوعات',
                                      onPressed: () => _showPaymentsHistory(s),
                                      icon: const Icon(
                                        Icons.receipt_long,
                                        size: 18,
                                        color: Colors.purple,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'إضافة مستحقات',
                                      onPressed: () => _addPayable(s),
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        size: 18,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    if (payable > 0)
                                      IconButton(
                                        tooltip: 'إضافة دفعة (دفع مستحقات)',
                                        onPressed: () => _addPayment(s),
                                        icon: const Icon(
                                          Icons.payment,
                                          size: 18,
                                          color: Colors.green,
                                        ),
                                      ),
                                    IconButton(
                                      tooltip: 'تعديل',
                                      onPressed: () => _openEditor(supplier: s),
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'حذف',
                                      onPressed: () => _delete(s['id'] as int),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  Future<void> _delete(int id) async {
    final db = context.read<DatabaseService>();
    final auth = context.read<AuthProvider>();
    final currentUser = auth.currentUser;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف المورد'),
        content: const Text('هل تريد حذف هذا المورد؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حذف')),
        ],
      ),
    );
    if (ok != true) {
      return;
    }

    try {
      final deletedRows = await db.deleteSupplier(
        id,
        userId: currentUser?.id,
        username: currentUser?.username,
        name: currentUser?.name,
      );
      if (!mounted) {
        return;
      }

      if (deletedRows > 0) {
        _refreshSuppliers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف المورد بنجاح'),
            backgroundColor: Color(0xFF059669), // Professional Green
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لم يتم العثور على المورد أو حدث خطأ في الحذف'),
            backgroundColor: Color(0xFFF59E0B), // Professional Orange
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      String errorMessage = 'خطأ في حذف المورد';
      final errorStr = e.toString();

      if (errorStr.contains('مرتبط ببيانات مهمة') ||
          errorStr.contains('لا يمكن حذف المورد')) {
        // رسالة الخطأ من الدالة نفسها
        errorMessage = errorStr.replaceAll('Exception: ', '');
      } else if (errorStr.contains('FOREIGN KEY constraint failed')) {
        errorMessage = 'لا يمكن حذف المورد لأنه مرتبط ببيانات أخرى';
      } else if (errorStr.contains('database is locked')) {
        errorMessage = 'قاعدة البيانات قيد الاستخدام، حاول مرة أخرى';
      } else {
        errorMessage =
            'خطأ في حذف المورد: ${errorStr.replaceAll('Exception: ', '')}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Color(0xFFDC2626), // Professional Red
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _openEditor({Map<String, Object?>? supplier}) async {
    final db = context.read<DatabaseService>();
    final name =
        TextEditingController(text: supplier?['name']?.toString() ?? '');
    final phone =
        TextEditingController(text: supplier?['phone']?.toString() ?? '');
    final address =
        TextEditingController(text: supplier?['address']?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(supplier == null ? 'إضافة مورد' : 'تعديل مورد'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'الاسم')),
              const SizedBox(height: 8),
              TextField(
                  controller: phone,
                  decoration: const InputDecoration(labelText: 'الهاتف')),
              const SizedBox(height: 8),
              TextField(
                  controller: address,
                  decoration: const InputDecoration(labelText: 'العنوان')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('حفظ')),
        ],
      ),
    );
    if (ok == true) {
      await db.upsertSupplier({
        'name': name.text.trim(),
        'phone': phone.text.trim(),
        'address': address.text.trim()
      }, id: supplier?['id'] as int?);
      if (!mounted) {
        return;
      }
      _refreshSuppliers();
    }
  }

  Future<void> _addPayment(Map<String, Object?> supplier) async {
    final db = context.read<DatabaseService>();
    final amountController = TextEditingController();
    final dateController =
        TextEditingController(text: DateTime.now().toString().substring(0, 10));
    final notesController = TextEditingController();
    final supplierId = supplier['id'] as int;
    final supplierName = supplier['name']?.toString() ?? '';
    final currentPayable =
        (supplier['total_payable'] as num?)?.toDouble() ?? 0.0;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('إضافة دفعة للمورد: $supplierName'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'المستحق الحالي: ${Formatters.currencyIQD(currentPayable)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'المبلغ',
                  hintText: 'أدخل المبلغ المدفوع',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'تاريخ الدفعة',
                  hintText: 'YYYY-MM-DD',
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: _,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    dateController.text = date.toString().substring(0, 10);
                  }
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (amountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى إدخال المبلغ')),
                );
                return;
              }
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى إدخال مبلغ صحيح')),
                );
                return;
              }
              if (amount > currentPayable) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'المبلغ المدخل (${Formatters.currencyIQD(amount)}) أكبر من المستحق (${Formatters.currencyIQD(currentPayable)})')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        final amount = double.parse(amountController.text);
        final paymentDate = DateTime.parse(dateController.text);
        final notes = notesController.text.trim();

        await db.addSupplierPayment(
          supplierId: supplierId,
          amount: amount,
          paymentDate: paymentDate,
          notes: notes.isEmpty ? null : notes,
        );

        if (!mounted) return;

        _refreshSuppliers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة الدفعة بنجاح'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إضافة الدفعة: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// إضافة مستحقات جديدة للمورد (مثل فاتورة شراء)
  Future<void> _addPayable(Map<String, Object?> supplier) async {
    final db = context.read<DatabaseService>();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final supplierId = supplier['id'] as int;
    final supplierName = supplier['name']?.toString() ?? '';
    final currentPayable =
        (supplier['total_payable'] as num?)?.toDouble() ?? 0.0;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('إضافة مستحقات للمورد: $supplierName'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'المستحقات الحالية: ${Formatters.currencyIQD(currentPayable)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'استخدم هذه الوظيفة عند شراء بضاعة من المورد أو إضافة فاتورة جديدة.',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'المبلغ المستحق',
                  hintText: 'أدخل المبلغ المستحق (مثل: 100000)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                  hintText: 'مثال: فاتورة شراء رقم 123',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (amountController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى إدخال المبلغ')),
                );
                return;
              }
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('يرجى إدخال مبلغ صحيح أكبر من صفر')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        final amount = double.parse(amountController.text);
        final notes = notesController.text.trim();

        // إضافة المستحقات (الدالة تضيف total_payable تلقائياً)
        await db.addSupplierPayable(
          supplierId: supplierId,
          amount: amount,
          notes: notes.isEmpty ? null : notes,
        );

        if (!mounted) return;

        _refreshSuppliers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'تم إضافة مستحقات بقيمة ${Formatters.currencyIQD(amount)} بنجاح'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إضافة المستحقات: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// عرض سجل المستحقات والمدفوعات مع إمكانية التعديل والحذف
  Future<void> _showPaymentsHistory(Map<String, Object?> supplier) async {
    final db = context.read<DatabaseService>();
    final auth = context.read<AuthProvider>();
    final currentUser = auth.currentUser;
    final supplierId = supplier['id'] as int;
    final supplierName = supplier['name']?.toString() ?? '';

    int paymentsRefreshKey = 0;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.8,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'سجل المستحقات والمدفوعات - $supplierName',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: FutureBuilder<List<Map<String, Object?>>>(
                          key: ValueKey(paymentsRefreshKey),
                          future:
                              db.getSupplierPayments(supplierId: supplierId),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            final payments = snapshot.data!;

                            if (payments.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.history,
                                      size: 64,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'لا يوجد سجل',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: payments.length,
                              itemBuilder: (context, index) {
                                final payment = payments[index];
                                final amount =
                                    (payment['amount'] as num?)?.toDouble() ??
                                        0.0;
                                final paymentDate =
                                    payment['payment_date']?.toString() ?? '';
                                final notes =
                                    payment['notes']?.toString() ?? '';
                                final isPayable = amount == 0 &&
                                    notes.contains('إضافة مستحقات');
                                final isPayment = amount > 0;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isPayable
                                          ? Colors.orange.withOpacity(0.2)
                                          : Colors.green.withOpacity(0.2),
                                      child: Icon(
                                        isPayable ? Icons.add : Icons.payment,
                                        color: isPayable
                                            ? Colors.orange
                                            : Colors.green,
                                      ),
                                    ),
                                    title: Text(
                                      isPayable ? 'إضافة مستحقات' : 'دفعة',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        if (isPayment)
                                          Text(
                                            'المبلغ: ${Formatters.currencyIQD(amount)}',
                                            style: TextStyle(
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        else if (isPayable)
                                          Text(
                                            notes,
                                            style: TextStyle(
                                              color: Colors.orange.shade700,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'التاريخ: ${paymentDate.substring(0, 10)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: DarkModeUtils
                                                .getSecondaryTextColor(context),
                                          ),
                                        ),
                                        if (notes.isNotEmpty && !isPayable)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Text(
                                              'ملاحظات: $notes',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: DarkModeUtils
                                                    .getSecondaryTextColor(
                                                        context),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isPayment)
                                          IconButton(
                                            tooltip: 'تعديل',
                                            icon: const Icon(
                                                Icons.edit_outlined,
                                                size: 20),
                                            color: Colors.blue,
                                            onPressed: () async {
                                              await _editPayment(
                                                  context,
                                                  payment,
                                                  supplierId,
                                                  setDialogState);
                                            },
                                          ),
                                        IconButton(
                                          tooltip: 'حذف',
                                          icon: const Icon(Icons.delete_outline,
                                              size: 20),
                                          color: Colors.red,
                                          onPressed: () async {
                                            final confirm =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                title: const Text('حذف السجل'),
                                                content: const Text(
                                                    'هل أنت متأكد من حذف هذا السجل؟'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(_, false),
                                                    child: const Text('إلغاء'),
                                                  ),
                                                  FilledButton(
                                                    onPressed: () =>
                                                        Navigator.pop(_, true),
                                                    child: const Text('حذف'),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirm == true) {
                                              try {
                                                final paymentId =
                                                    payment['id'] as int;
                                                await db.deleteSupplierPayment(
                                                  paymentId,
                                                  userId: currentUser?.id,
                                                  username:
                                                      currentUser?.username,
                                                  name: currentUser?.name,
                                                );

                                                if (!context.mounted) return;

                                                // إعادة بناء القائمة
                                                paymentsRefreshKey++;
                                                setDialogState(() {});

                                                // التحقق من أن القائمة أصبحت فارغة
                                                final remainingPayments =
                                                    await db
                                                        .getSupplierPayments(
                                                            supplierId:
                                                                supplierId);
                                                if (remainingPayments.isEmpty &&
                                                    context.mounted) {
                                                  // إغلاق النافذة تلقائياً إذا أصبحت القائمة فارغة
                                                  Navigator.pop(context);
                                                  _refreshSuppliers();
                                                }

                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'تم حذف السجل بنجاح'),
                                                      backgroundColor:
                                                          Color(0xFF059669),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                if (!context.mounted) return;

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'خطأ في حذف السجل: ${e.toString()}'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// تعديل سجل دفعة
  Future<void> _editPayment(
      BuildContext context, Map<String, Object?> payment, int supplierId,
      [StateSetter? setDialogState]) async {
    final db = context.read<DatabaseService>();
    final paymentId = payment['id'] as int;
    final currentAmount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final currentDate = payment['payment_date']?.toString() ?? '';
    final currentNotes = payment['notes']?.toString() ?? '';

    final amountController = TextEditingController(
        text: currentAmount > 0 ? currentAmount.toString() : '');
    final dateController = TextEditingController(
        text: currentDate.isNotEmpty
            ? currentDate.substring(0, 10)
            : DateTime.now().toString().substring(0, 10));
    final notesController = TextEditingController(text: currentNotes);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تعديل السجل'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'المبلغ',
                  hintText: 'أدخل المبلغ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'تاريخ الدفعة',
                  hintText: 'YYYY-MM-DD',
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: _,
                    initialDate: currentDate.isNotEmpty
                        ? DateTime.parse(currentDate)
                        : DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    dateController.text = date.toString().substring(0, 10);
                  }
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (amountController.text.isEmpty) {
                ScaffoldMessenger.of(_).showSnackBar(
                  const SnackBar(content: Text('يرجى إدخال المبلغ')),
                );
                return;
              }
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(_).showSnackBar(
                  const SnackBar(content: Text('يرجى إدخال مبلغ صحيح')),
                );
                return;
              }
              Navigator.pop(_, true);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );

    if (ok == true) {
      try {
        final amount = double.parse(amountController.text);
        final paymentDate = DateTime.parse(dateController.text);
        final notes = notesController.text.trim();

        await db.updateSupplierPayment(
          paymentId: paymentId,
          newAmount: amount,
          newPaymentDate: paymentDate,
          newNotes: notes.isEmpty ? null : notes,
        );

        if (!context.mounted) return;

        if (setDialogState != null) {
          setDialogState(() {});
        } else {
          _refreshSuppliers();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تعديل السجل بنجاح'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تعديل السجل: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
