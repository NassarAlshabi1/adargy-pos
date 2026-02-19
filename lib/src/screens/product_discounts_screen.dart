import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/db/database_service.dart';
import '../utils/dark_mode_utils.dart';
import '../utils/format.dart';

class ProductDiscountsScreen extends StatefulWidget {
  const ProductDiscountsScreen({super.key});

  @override
  State<ProductDiscountsScreen> createState() => _ProductDiscountsScreenState();
}

class _ProductDiscountsScreenState extends State<ProductDiscountsScreen> {
  String _query = '';
  Future<List<Map<String, Object?>>>? _discountsFuture;

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
        _loadDiscounts();
      }
    });
  }

  void _loadDiscounts() {
    final db = context.read<DatabaseService>();
    setState(() {
      _discountsFuture = db.getProductDiscounts();
    });
  }

  InputDecoration _pill(BuildContext context, String hint, IconData icon) {
    return DarkModeUtils.createPillInputDecoration(
      context,
      hintText: hint,
      prefixIcon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('خصومات المنتجات'),
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
                    label: const Text('إضافة خصم')),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    decoration: _pill(context, 'بحث عن خصم', Icons.search),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<Map<String, Object?>>>(
                  future: _discountsFuture,
                  builder: (context, snap) {
                    if (!snap.hasData)
                      return const Center(child: CircularProgressIndicator());
                    var items = snap.data!;
                    if (_query.isNotEmpty) {
                      items = items.where((item) {
                        final productName =
                            item['product_name']?.toString() ?? '';
                        return productName
                            .toLowerCase()
                            .contains(_query.toLowerCase());
                      }).toList();
                    }
                    if (items.isEmpty)
                      return const Center(child: Text('لا توجد خصومات'));
                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final discount = items[index];
                        final isActive = (discount['active'] as int? ?? 0) == 1;
                        final discountPercent =
                            (discount['discount_percent'] as num?)
                                    ?.toDouble() ??
                                0.0;
                        final discountAmount =
                            (discount['discount_amount'] as num?)?.toDouble();
                        final startDate = discount['start_date'] != null
                            ? DateTime.parse(discount['start_date'] as String)
                            : null;
                        final endDate = discount['end_date'] != null
                            ? DateTime.parse(discount['end_date'] as String)
                            : null;
                        final now = DateTime.now();
                        final isExpired =
                            endDate != null && now.isAfter(endDate);
                        final isPending =
                            startDate != null && now.isBefore(startDate);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  isActive && !isExpired && !isPending
                                      ? Colors.green
                                      : Colors.grey,
                              child: Icon(
                                isActive && !isExpired && !isPending
                                    ? Icons.check
                                    : Icons.close,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              discount['product_name']?.toString() ??
                                  'منتج غير معروف',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                if (discountPercent > 0)
                                  Text(
                                      'نسبة الخصم: ${discountPercent.toStringAsFixed(1)}%'),
                                if (discountAmount != null &&
                                    discountAmount > 0)
                                  Text(
                                      'مبلغ الخصم: ${Formatters.currencyIQD(discountAmount)}'),
                                if (startDate != null)
                                  Text('من: ${_formatDate(startDate)}'),
                                if (endDate != null)
                                  Text('إلى: ${_formatDate(endDate)}'),
                                if (isExpired)
                                  const Text('منتهي الصلاحية',
                                      style: TextStyle(color: Colors.red)),
                                if (isPending)
                                  const Text('لم يبدأ بعد',
                                      style: TextStyle(color: Colors.orange)),
                                if (!isActive)
                                  const Text('غير مفعّل',
                                      style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () =>
                                      _openEditor(db, discount: discount),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _deleteDiscount(
                                      db, discount['id'] as int),
                                ),
                              ],
                            ),
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

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  Future<void> _deleteDiscount(DatabaseService db, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الخصم'),
        content: const Text('هل تريد حذف هذا الخصم؟'),
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
        await db.deleteProductDiscount(id);
        if (!mounted) return;
        _loadDiscounts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الخصم بنجاح'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حذف الخصم: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openEditor(DatabaseService db,
      {Map<String, Object?>? discount}) async {
    final formKey = GlobalKey<FormState>();
    int? selectedProductId = discount?['product_id'] as int?;
    final discountPercentCtrl = TextEditingController(
        text: (discount?['discount_percent'] as num?)?.toString() ?? '');
    final discountAmountCtrl = TextEditingController(
        text: (discount?['discount_amount'] as num?)?.toString() ?? '');
    DateTime? startDate = discount != null && discount['start_date'] != null
        ? DateTime.parse(discount['start_date'] as String)
        : null;
    DateTime? endDate = discount != null && discount['end_date'] != null
        ? DateTime.parse(discount['end_date'] as String)
        : null;
    bool isActive = (discount?['active'] as int? ?? 1) == 1;
    String discountType =
        discountPercentCtrl.text.isNotEmpty ? 'percent' : 'amount';

    await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
              child: Padding(
                padding: const EdgeInsets.all(20),
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
                              discount == null ? 'إضافة خصم' : 'تعديل خصم',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Spacer(),
                            IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // اختيار المنتج
                        FutureBuilder<List<Map<String, Object?>>>(
                          future: db.getAllProducts(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }
                            final products = snapshot.data!;
                            Map<int, String> productMap = {};
                            for (var p in products) {
                              productMap[p['id'] as int] =
                                  p['name']?.toString() ?? '';
                            }
                            return DropdownButtonFormField<int>(
                              initialValue: selectedProductId,
                              decoration: _pill(
                                  context, 'اختر المنتج', Icons.shopping_bag),
                              items: products.map((p) {
                                return DropdownMenuItem<int>(
                                  value: p['id'] as int,
                                  child: Text(p['name']?.toString() ?? ''),
                                );
                              }).toList(),
                              onChanged: (v) {
                                setDialogState(() => selectedProductId = v);
                              },
                              validator: (v) =>
                                  v == null ? 'يجب اختيار منتج' : null,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        // نوع الخصم
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                                value: 'percent', label: Text('نسبة %')),
                            ButtonSegment(value: 'amount', label: Text('مبلغ')),
                          ],
                          selected: {discountType},
                          onSelectionChanged: (Set<String> newSelection) {
                            setDialogState(() {
                              discountType = newSelection.first;
                              if (discountType == 'percent') {
                                discountAmountCtrl.clear();
                              } else {
                                discountPercentCtrl.clear();
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        // نسبة الخصم
                        if (discountType == 'percent')
                          TextFormField(
                            controller: discountPercentCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textAlign: TextAlign.right,
                            decoration:
                                _pill(context, 'نسبة الخصم (%)', Icons.percent),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'مطلوب';
                              }
                              final val = double.tryParse(v);
                              if (val == null || val < 0 || val > 100) {
                                return 'يجب أن تكون بين 0 و 100';
                              }
                              return null;
                            },
                          ),
                        // مبلغ الخصم
                        if (discountType == 'amount')
                          TextFormField(
                            controller: discountAmountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textAlign: TextAlign.right,
                            decoration: _pill(
                                context, 'مبلغ الخصم', Icons.attach_money),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'مطلوب';
                              }
                              final val = double.tryParse(v);
                              if (val == null || val < 0) {
                                return 'يجب أن يكون أكبر من صفر';
                              }
                              return null;
                            },
                          ),
                        const SizedBox(height: 16),
                        // تاريخ البداية
                        ListTile(
                          title: const Text('تاريخ البداية (اختياري)'),
                          subtitle: Text(startDate != null
                              ? _formatDate(startDate!)
                              : 'لم يتم تحديد تاريخ'),
                          trailing: IconButton(
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
                        ),
                        // تاريخ النهاية
                        ListTile(
                          title: const Text('تاريخ النهاية (اختياري)'),
                          subtitle: Text(endDate != null
                              ? _formatDate(endDate!)
                              : 'لم يتم تحديد تاريخ'),
                          trailing: IconButton(
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
                        ),
                        // تفعيل/إلغاء تفعيل
                        SwitchListTile(
                          title: const Text('مفعّل'),
                          value: isActive,
                          onChanged: (v) {
                            setDialogState(() => isActive = v);
                          },
                        ),
                        const SizedBox(height: 20),
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
                                if (selectedProductId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('يجب اختيار منتج')),
                                  );
                                  return;
                                }

                                try {
                                  final values = <String, Object?>{
                                    'product_id': selectedProductId,
                                    'active': isActive ? 1 : 0,
                                  };

                                  if (discountType == 'percent') {
                                    values['discount_percent'] =
                                        double.parse(discountPercentCtrl.text);
                                    values['discount_amount'] = null;
                                  } else {
                                    values['discount_amount'] =
                                        double.parse(discountAmountCtrl.text);
                                    values['discount_percent'] = 0;
                                  }

                                  if (startDate != null) {
                                    values['start_date'] =
                                        startDate!.toIso8601String();
                                  }
                                  if (endDate != null) {
                                    values['end_date'] =
                                        endDate!.toIso8601String();
                                  }

                                  if (discount == null) {
                                    await db.insertProductDiscount(values);
                                  } else {
                                    await db.updateProductDiscount(
                                        discount['id'] as int, values);
                                  }

                                  if (!context.mounted) return;
                                  Navigator.pop(context, true);
                                  _loadDiscounts();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(discount == null
                                          ? 'تم إضافة الخصم بنجاح'
                                          : 'تم تحديث الخصم بنجاح'),
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
                              child: Text(discount == null ? 'إضافة' : 'حفظ'),
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
