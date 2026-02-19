import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/db/database_service.dart';
import '../utils/dark_mode_utils.dart';
import '../utils/format.dart';

class DiscountCouponsScreen extends StatefulWidget {
  const DiscountCouponsScreen({super.key});

  @override
  State<DiscountCouponsScreen> createState() => _DiscountCouponsScreenState();
}

class _DiscountCouponsScreenState extends State<DiscountCouponsScreen> {
  String _query = '';
  bool _showActiveOnly = false;
  Future<List<Map<String, Object?>>>? _couponsFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final db = context.read<DatabaseService>();
      // التأكد من وجود الجداول قبل التحميل
      try {
        await db.ensureDiscountTables();
      } catch (e) {
        // تجاهل خطأ التأكد من الجداول والاستمرار في التحميل
      }
      if (mounted) {
        _loadCoupons();
      }
    });
  }

  void _loadCoupons() {
    final db = context.read<DatabaseService>();
    setState(() {
      _couponsFuture =
          db.getDiscountCoupons(activeOnly: _showActiveOnly ? true : null);
    });
  }

  InputDecoration _pill(BuildContext context, String hint, IconData icon,
      {String? helperText}) {
    return DarkModeUtils.createPillInputDecoration(
      context,
      hintText: hint,
      prefixIcon: icon,
    ).copyWith(
      helperText: helperText,
      helperMaxLines: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('كوبونات الخصم'),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(children: [
                FilledButton.icon(
                    onPressed: () => _openEditor(db),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة كوبون')),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    decoration: _pill(context, 'بحث عن كوبون', Icons.search),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('المفعّلة فقط'),
                  selected: _showActiveOnly,
                  onSelected: (v) {
                    setState(() => _showActiveOnly = v);
                    _loadCoupons();
                  },
                ),
              ]),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<Map<String, Object?>>>(
                  future: _couponsFuture,
                  builder: (context, snap) {
                    if (!snap.hasData)
                      return const Center(child: CircularProgressIndicator());
                    var items = snap.data!;
                    if (_query.isNotEmpty) {
                      items = items.where((item) {
                        final code = item['code']?.toString() ?? '';
                        final name = item['name']?.toString() ?? '';
                        return code
                                .toLowerCase()
                                .contains(_query.toLowerCase()) ||
                            name.toLowerCase().contains(_query.toLowerCase());
                      }).toList();
                    }
                    if (items.isEmpty)
                      return const Center(child: Text('لا توجد كوبونات'));
                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final coupon = items[index];
                        final isActive = (coupon['active'] as int? ?? 0) == 1;
                        final discountType = coupon['discount_type'] as String;
                        final discountValue =
                            (coupon['discount_value'] as num).toDouble();
                        final usageLimit = coupon['usage_limit'] as int?;
                        final usedCount = (coupon['used_count'] as int? ?? 0);
                        final minPurchase =
                            (coupon['min_purchase_amount'] as num?)
                                    ?.toDouble() ??
                                0.0;
                        final maxDiscount =
                            (coupon['max_discount_amount'] as num?)?.toDouble();
                        final startDate = coupon['start_date'] != null
                            ? DateTime.parse(coupon['start_date'] as String)
                            : null;
                        final endDate = coupon['end_date'] != null
                            ? DateTime.parse(coupon['end_date'] as String)
                            : null;
                        final now = DateTime.now();
                        final isExpired =
                            endDate != null && now.isAfter(endDate);
                        final isPending =
                            startDate != null && now.isBefore(startDate);
                        final isUsedUp =
                            usageLimit != null && usedCount >= usageLimit;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: isActive &&
                                      !isExpired &&
                                      !isPending &&
                                      !isUsedUp
                                  ? Colors.green
                                  : Colors.grey,
                              child: Icon(
                                isActive &&
                                        !isExpired &&
                                        !isPending &&
                                        !isUsedUp
                                    ? Icons.check
                                    : Icons.close,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              coupon['code']?.toString() ?? '',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(coupon['name']?.toString() ?? ''),
                                Text(
                                  discountType == 'percent'
                                      ? 'خصم ${discountValue.toStringAsFixed(1)}%'
                                      : 'خصم ${Formatters.currencyIQD(discountValue)}',
                                ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoRow(
                                        'النوع',
                                        discountType == 'percent'
                                            ? 'نسبة'
                                            : 'مبلغ'),
                                    _buildInfoRow(
                                        'قيمة الخصم',
                                        discountType == 'percent'
                                            ? '${discountValue.toStringAsFixed(1)}%'
                                            : Formatters.currencyIQD(
                                                discountValue)),
                                    if (maxDiscount != null &&
                                        discountType == 'percent')
                                      _buildInfoRow('الحد الأقصى للخصم',
                                          Formatters.currencyIQD(maxDiscount)),
                                    if (minPurchase > 0)
                                      _buildInfoRow('الحد الأدنى للشراء',
                                          Formatters.currencyIQD(minPurchase)),
                                    if (usageLimit != null)
                                      _buildInfoRow('حد الاستخدام',
                                          '$usedCount / $usageLimit'),
                                    if (startDate != null)
                                      _buildInfoRow(
                                          'من', _formatDate(startDate)),
                                    if (endDate != null)
                                      _buildInfoRow(
                                          'إلى', _formatDate(endDate)),
                                    if (isExpired)
                                      const Text('منتهي الصلاحية',
                                          style: TextStyle(color: Colors.red)),
                                    if (isPending)
                                      const Text('لم يبدأ بعد',
                                          style:
                                              TextStyle(color: Colors.orange)),
                                    if (isUsedUp)
                                      const Text('تم الوصول إلى حد الاستخدام',
                                          style: TextStyle(color: Colors.red)),
                                    if (!isActive)
                                      const Text('غير مفعّل',
                                          style: TextStyle(color: Colors.grey)),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () =>
                                              _openEditor(db, coupon: coupon),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () => _deleteCoupon(
                                              db, coupon['id'] as int),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  Future<void> _deleteCoupon(DatabaseService db, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الكوبون'),
        content: const Text('هل تريد حذف هذا الكوبون؟'),
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
    if (ok == true) {
      try {
        await db.deleteDiscountCoupon(id);
        if (!mounted) return;
        _loadCoupons();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الكوبون بنجاح'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حذف الكوبون: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openEditor(DatabaseService db,
      {Map<String, Object?>? coupon}) async {
    final formKey = GlobalKey<FormState>();
    final codeCtrl =
        TextEditingController(text: coupon?['code']?.toString() ?? '');
    final nameCtrl =
        TextEditingController(text: coupon?['name']?.toString() ?? '');
    String discountType = coupon?['discount_type']?.toString() ?? 'percent';
    final discountValueCtrl = TextEditingController(
        text: (coupon?['discount_value'] as num?)?.toString() ?? '0');
    final minPurchaseCtrl = TextEditingController(
        text: (coupon?['min_purchase_amount'] as num?)?.toString() ?? '0');
    final maxDiscountCtrl = TextEditingController(
        text: (coupon?['max_discount_amount'] as num?)?.toString() ?? '');
    final usageLimitCtrl =
        TextEditingController(text: coupon?['usage_limit']?.toString() ?? '');
    DateTime? startDate = coupon != null && coupon['start_date'] != null
        ? DateTime.parse(coupon['start_date'] as String)
        : null;
    DateTime? endDate = coupon != null && coupon['end_date'] != null
        ? DateTime.parse(coupon['end_date'] as String)
        : null;
    bool isActive = (coupon?['active'] as int? ?? 1) == 1;

    await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 550, maxHeight: 700),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Text(
                              coupon == null ? 'إضافة كوبون' : 'تعديل كوبون',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Spacer(),
                            IconButton(
                                iconSize: 20,
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: codeCtrl,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          decoration: _pill(context, 'كود الكوبون', Icons.tag,
                              helperText:
                                  'أدخل كود فريد للكوبون (مثال: SUMMER2024)'),
                          textCapitalization: TextCapitalization.characters,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: nameCtrl,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          decoration: _pill(context, 'اسم الكوبون', Icons.label,
                              helperText:
                                  'أدخل اسم وصفي للكوبون (مثال: خصم الصيف)'),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                        ),
                        const SizedBox(height: 12),
                        // نوع الخصم
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                                value: 'percent', label: Text('نسبة %')),
                            ButtonSegment(value: 'amount', label: Text('مبلغ')),
                          ],
                          selected: {discountType},
                          onSelectionChanged: (Set<String> newSelection) {
                            setDialogState(
                                () => discountType = newSelection.first);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: discountValueCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textAlign: TextAlign.right,
                          decoration: _pill(
                              context,
                              discountType == 'percent'
                                  ? 'قيمة الخصم (%)'
                                  : 'قيمة الخصم',
                              Icons.discount,
                              helperText: discountType == 'percent'
                                  ? 'أدخل نسبة الخصم من 0 إلى 100 (مثال: 10 يعني 10%)'
                                  : 'أدخل مبلغ الخصم بالدينار (مثال: 5000)'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'مطلوب';
                            }
                            final val = double.tryParse(v);
                            if (val == null || val < 0) {
                              return 'يجب أن يكون أكبر من صفر';
                            }
                            if (discountType == 'percent' && val > 100) {
                              return 'يجب أن تكون بين 0 و 100';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        if (discountType == 'percent')
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextFormField(
                              controller: maxDiscountCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              textAlign: TextAlign.right,
                              decoration: _pill(context,
                                  'الحد الأقصى للخصم (اختياري)', Icons.maximize,
                                  helperText:
                                      'أدخل الحد الأقصى لمبلغ الخصم بالدينار (مثال: 50000). اتركه فارغاً إذا لم يكن هناك حد أقصى'),
                            ),
                          ),
                        TextFormField(
                          controller: minPurchaseCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textAlign: TextAlign.right,
                          decoration: _pill(context, 'الحد الأدنى للشراء',
                              Icons.shopping_cart,
                              helperText:
                                  'أدخل الحد الأدنى لمبلغ الشراء بالدينار (مثال: 100000). أدخل 0 أو اتركه فارغاً إذا لم يكن هناك حد أدنى'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return null;
                            }
                            final val = double.tryParse(v);
                            if (val != null && val < 0) {
                              return 'يجب أن يكون أكبر من أو يساوي صفر';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: usageLimitCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          decoration: _pill(context, 'حد الاستخدام',
                              Icons.confirmation_number,
                              helperText:
                                  'أدخل عدد مرات استخدام الكوبون (مثال: 100). اتركه فارغاً إذا لم يكن هناك حد'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return null;
                            }
                            final val = int.tryParse(v);
                            if (val != null && val < 1) {
                              return 'يجب أن يكون أكبر من صفر';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        // تاريخ البداية
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('تاريخ البداية (اختياري)',
                              style: TextStyle(fontSize: 14)),
                          subtitle: Text(
                              startDate != null
                                  ? _formatDate(startDate!)
                                  : 'لم يتم تحديد تاريخ',
                              style: const TextStyle(fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (startDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    setDialogState(() => startDate = null);
                                  },
                                ),
                              IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: startDate ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setDialogState(() => startDate = picked);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        // تاريخ النهاية
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('تاريخ النهاية (اختياري)',
                              style: TextStyle(fontSize: 14)),
                          subtitle: Text(
                              endDate != null
                                  ? _formatDate(endDate!)
                                  : 'لم يتم تحديد تاريخ',
                              style: const TextStyle(fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (endDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    setDialogState(() => endDate = null);
                                  },
                                ),
                              IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: endDate ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null && context.mounted) {
                                    setDialogState(() => endDate = picked);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        // تفعيل/إلغاء تفعيل
                        SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('مفعّل',
                              style: TextStyle(fontSize: 14)),
                          value: isActive,
                          onChanged: (v) {
                            setDialogState(() => isActive = v);
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('إلغاء'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;

                                try {
                                  final values = <String, Object?>{
                                    'code': codeCtrl.text.trim().toUpperCase(),
                                    'name': nameCtrl.text.trim(),
                                    'discount_type': discountType,
                                    'discount_value':
                                        double.parse(discountValueCtrl.text),
                                    'min_purchase_amount': minPurchaseCtrl.text
                                            .trim()
                                            .isEmpty
                                        ? 0.0
                                        : double.parse(minPurchaseCtrl.text),
                                    'active': isActive ? 1 : 0,
                                  };

                                  if (maxDiscountCtrl.text.trim().isNotEmpty &&
                                      discountType == 'percent') {
                                    values['max_discount_amount'] =
                                        double.parse(maxDiscountCtrl.text);
                                  } else {
                                    values['max_discount_amount'] = null;
                                  }

                                  if (usageLimitCtrl.text.trim().isNotEmpty) {
                                    values['usage_limit'] =
                                        int.parse(usageLimitCtrl.text);
                                  } else {
                                    values['usage_limit'] = null;
                                  }

                                  if (startDate != null) {
                                    values['start_date'] =
                                        startDate!.toIso8601String();
                                  } else {
                                    values['start_date'] = null;
                                  }

                                  if (endDate != null) {
                                    values['end_date'] =
                                        endDate!.toIso8601String();
                                  } else {
                                    values['end_date'] = null;
                                  }

                                  if (coupon == null) {
                                    await db.insertDiscountCoupon(values);
                                  } else {
                                    await db.updateDiscountCoupon(
                                        coupon['id'] as int, values);
                                  }

                                  if (!context.mounted) return;
                                  Navigator.pop(context, true);
                                  _loadCoupons();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(coupon == null
                                          ? 'تم إضافة الكوبون بنجاح'
                                          : 'تم تحديث الكوبون بنجاح'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('خطأ: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                              child: Text(coupon == null ? 'إضافة' : 'حفظ'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
