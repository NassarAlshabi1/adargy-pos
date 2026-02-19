import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/db/database_service.dart';
import '../services/auth/auth_provider.dart';
import '../models/user_model.dart';
import '../utils/export.dart';
import '../widgets/require_permission.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  int _slowDays = 30;

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();
    final auth = context.watch<AuthProvider>();

    // فحص صلاحية إدارة المخزون
    if (!auth.hasPermission(UserPermission.manageInventory)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المخزون'),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'ليس لديك صلاحية للوصول إلى هذه الصفحة',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'هذه الصفحة متاحة للمديرين والمشرفين فقط',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('العودة'),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المخزون'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'نقص الكمية'),
              Tab(text: 'بطيء الحركة'),
              Tab(text: 'نفاد'),
            ],
          ),
          actions: [
            PopupMenuButton<int>(
              tooltip: 'تحديد فترة البطء',
              onSelected: (v) => setState(() => _slowDays = v),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 7, child: Text('آخر 7 أيام')),
                PopupMenuItem(value: 30, child: Text('آخر 30 يوماً')),
                PopupMenuItem(value: 90, child: Text('آخر 90 يوماً')),
              ],
              icon: const Icon(Icons.trending_down),
            ),
            RequirePermission(
              permission: UserPermission.exportReports,
              child: IconButton(
                onPressed: () async {
                  await _exportInventory(db);
                },
                tooltip: 'تصدير PDF',
                icon: const Icon(Icons.picture_as_pdf),
              ),
            ),
            IconButton(
              onPressed: _refresh,
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<Map<String, Object?>>>(
                future: db.getLowStock(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _ErrorState(
                        message: snapshot.error.toString(), onRetry: _refresh);
                  }
                  final items = snapshot.data ?? const <Map<String, Object?>>[];
                  if (items.isEmpty) {
                    return const _EmptyState(
                      icon: Icons.inventory_2_outlined,
                      message: 'لا توجد أصناف منخفضة الكمية',
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = items[i];
                      final name = p['name']?.toString() ?? '';
                      final quantity = p['quantity']?.toString() ?? '0';
                      final minQuantity = p['min_quantity']?.toString() ?? '0';
                      final productId = p['id'] as int?;
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(name.isNotEmpty ? name[0] : '?'),
                        ),
                        title: Text(name, textAlign: TextAlign.right),
                        subtitle: Text(
                            'الكمية: $quantity | الحد الأدنى: $minQuantity',
                            textAlign: TextAlign.right),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _StatusChip(
                                label: 'منخفض',
                                color: Theme.of(context)
                                    .colorScheme
                                    .errorContainer,
                                textColor: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              color: Theme.of(context).colorScheme.primary,
                              tooltip: 'زيادة الكمية',
                              onPressed: productId != null
                                  ? () => _showAddQuantityDialog(
                                      context,
                                      db,
                                      productId,
                                      name,
                                      int.tryParse(quantity) ?? 0)
                                  : null,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<Map<String, Object?>>>(
                future: db.slowMovingProducts(days: _slowDays),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _ErrorState(
                        message: snapshot.error.toString(), onRetry: _refresh);
                  }
                  final items = snapshot.data ?? const <Map<String, Object?>>[];
                  if (items.isEmpty) {
                    return _EmptyState(
                      icon: Icons.hourglass_empty,
                      message:
                          'لا توجد أصناف بطيئة الحركة خلال آخر $_slowDays يوماً',
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = items[i];
                      final name = p['name']?.toString() ?? '';
                      return ListTile(
                        leading: const CircleAvatar(
                            child: Icon(Icons.trending_down)),
                        title: Text(name, textAlign: TextAlign.right),
                        subtitle: Text('لا توجد مبيعات خلال $_slowDays يوماً',
                            textAlign: TextAlign.right),
                        trailing: _StatusChip(
                            label: 'بطيء',
                            color:
                                Theme.of(context).colorScheme.tertiaryContainer,
                            textColor: Theme.of(context)
                                .colorScheme
                                .onTertiaryContainer),
                      );
                    },
                  );
                },
              ),
            ),
            RefreshIndicator(
              onRefresh: _refresh,
              child: FutureBuilder<List<Map<String, Object?>>>(
                future: db.getOutOfStock(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _ErrorState(
                        message: snapshot.error.toString(), onRetry: _refresh);
                  }
                  final items = snapshot.data ?? const <Map<String, Object?>>[];
                  if (items.isEmpty) {
                    return const _EmptyState(
                      icon: Icons.inventory_outlined,
                      message: 'لا توجد أصناف نافدة من المخزون',
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = items[i];
                      final name = p['name']?.toString() ?? '';
                      final productId = p['id'] as int?;
                      return ListTile(
                        leading: const CircleAvatar(
                            child: Icon(Icons.report_gmailerrorred_outlined)),
                        title: Text(name, textAlign: TextAlign.right),
                        subtitle:
                            const Text('الكمية: 0', textAlign: TextAlign.right),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _StatusChip(
                                label: 'نفاد',
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                textColor: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              color: Theme.of(context).colorScheme.primary,
                              tooltip: 'زيادة الكمية',
                              onPressed: productId != null
                                  ? () => _showAddQuantityDialog(
                                      context, db, productId, name, 0)
                                  : null,
                            ),
                          ],
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
  }
}

extension on _InventoryScreenState {
  Future<void> _showAddQuantityDialog(BuildContext context, DatabaseService db,
      int productId, String productName, int currentQuantity) async {
    final quantityController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('زيادة الكمية'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('المنتج: $productName'),
                const SizedBox(height: 8),
                Text('الكمية الحالية: $currentQuantity'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: quantityController,
                  keyboardType:
                      const TextInputType.numberWithOptions(signed: false),
                  decoration: const InputDecoration(
                    labelText: 'الكمية المضافة',
                    hintText: 'أدخل الكمية المراد إضافتها',
                    prefixIcon: Icon(Icons.add_shopping_cart),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الكمية مطلوبة';
                    }
                    final qty = int.tryParse(value.trim());
                    if (qty == null || qty <= 0) {
                      return 'الكمية يجب أن تكون رقماً صحيحاً أكبر من صفر';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );

    if (result == true && quantityController.text.isNotEmpty) {
      try {
        final quantityToAdd = int.parse(quantityController.text.trim());
        final newQuantity = currentQuantity + quantityToAdd;

        await db.updateProduct(productId, {'quantity': newQuantity});

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'تم إضافة $quantityToAdd إلى الكمية. الكمية الجديدة: $newQuantity'),
            backgroundColor: Colors.green,
          ),
        );

        // تحديث القائمة
        _refresh();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحديث الكمية: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportInventory(DatabaseService db) async {
    try {
      // اجلب كل القوائم مرة واحدة
      final results = await Future.wait<List<Map<String, Object?>>>([
        db.getLowStock(),
        db.slowMovingProducts(days: _slowDays),
        db.getOutOfStock(),
      ]);

      final low = results[0];
      final slow = results[1];
      final out = results[2];

      // ابنِ أسطر الجدول (مقلوبة RTL عبر PdfExporter)
      final rows = <List<String>>[
        ['القسم', 'المنتج', 'الكمية', 'الحد الأدنى/ملاحظة'],
        ...low.map((p) => [
              'منخفض',
              (p['name'] ?? '').toString(),
              (p['quantity'] ?? 0).toString(),
              (p['min_quantity'] ?? 0).toString(),
            ]),
        ...slow.map((p) => [
              'بطيء',
              (p['name'] ?? '').toString(),
              (p['quantity'] ?? 0).toString(),
              'لا مبيعات خلال $_slowDays يوماً',
            ]),
        ...out.map((p) => [
              'نفاد',
              (p['name'] ?? '').toString(),
              '0',
              '-',
            ]),
      ];

      final saved = await PdfExporter.exportSimpleTable(
        filename: 'inventory_report.pdf',
        title: 'تقرير المخزون',
        rows: rows,
      );
      if (!mounted) return;
      if (saved != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حفظ التقرير في: $saved')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل تصدير تقرير المخزون: $e')),
      );
    }
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 56, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => onRetry(),
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          )
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _StatusChip(
      {required this.label, required this.color, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
    );
  }
}
