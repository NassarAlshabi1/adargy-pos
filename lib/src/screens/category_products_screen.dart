// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../services/db/database_service.dart';
import '../services/auth/auth_provider.dart';
import '../utils/format.dart';

class CategoryProductsScreen extends StatefulWidget {
  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    this.onProductAdded,
  });

  final int categoryId;
  final String categoryName;
  final Color categoryColor;
  final VoidCallback? onProductAdded;

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface
            : Colors.white,
      ),
      child: Column(
        children: [
          // Header with close button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.categoryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _openProductEditor({}),
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: const Text(
                    'إضافة منتج',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFFFFFF)
                        .withOpacity(0.2), // Professional White with opacity
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.categoryName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Column(
              children: [
                // Search field
                Container(
                  margin: const EdgeInsets.all(16),
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.surface
                        : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: widget.categoryColor.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'البحث في منتجات القسم...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6)
                            : Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.search_rounded,
                          color: widget.categoryColor,
                          size: 20,
                        ),
                      ),
                      prefixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: Colors.grey.shade600,
                                  size: 18,
                                ),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: false,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.black87,
                      fontSize: 16,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                // Products grid
                Expanded(
                  child: FutureBuilder<List<Map<String, Object?>>>(
                    future: db.getAllProducts(
                      query: _searchQuery,
                      categoryId: widget.categoryId,
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final products = snapshot.data!;

                      if (products.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 80,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.5)
                                    : Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'لا توجد منتجات في هذا القسم'
                                    : 'لا توجد منتجات تطابق البحث',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.7)
                                      : Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'قم بإضافة منتجات جديدة لهذا القسم'
                                    : 'جرب البحث بكلمات مختلفة',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.6)
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return _ProductListTile(
                              product: product,
                              categoryColor: widget.categoryColor,
                              onEdit: () => _openProductEditor(product),
                              onDelete: () =>
                                  _deleteProduct(product['id'] as int),
                              onShowBarcode: () => _showBarcode(
                                product['barcode']?.toString() ?? '',
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ProductListTile({
    required Map<String, Object?> product,
    required Color categoryColor,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required VoidCallback onShowBarcode,
  }) {
    final name = product['name']?.toString() ?? 'بدون اسم';
    final price = (product['price'] as num?) ?? 0;
    final cost = (product['cost'] as num?) ?? 0;
    final quantity = (product['quantity'] as num?) ?? 0;
    final barcode = product['barcode']?.toString() ?? '';
    final profit = price - cost;

    // ألوان عشوائية متنوعة لكل منتج
    final cardColors = [
      // ألوان أساسية
      [Colors.blue.shade50, Colors.blue.shade100, Colors.blue.shade600],
      [Colors.green.shade50, Colors.green.shade100, Colors.green.shade600],
      [Colors.purple.shade50, Colors.purple.shade100, Colors.purple.shade600],
      [Colors.orange.shade50, Colors.orange.shade100, Colors.orange.shade600],
      [Colors.pink.shade50, Colors.pink.shade100, Colors.pink.shade600],
      [Colors.teal.shade50, Colors.teal.shade100, Colors.teal.shade600],
      [Colors.indigo.shade50, Colors.indigo.shade100, Colors.indigo.shade600],
      [Colors.cyan.shade50, Colors.cyan.shade100, Colors.cyan.shade600],

      // ألوان إضافية متنوعة
      [Colors.red.shade50, Colors.red.shade100, Colors.red.shade600],
      [Colors.amber.shade50, Colors.amber.shade100, Colors.amber.shade600],
      [Colors.lime.shade50, Colors.lime.shade100, Colors.lime.shade600],
      [
        Colors.deepOrange.shade50,
        Colors.deepOrange.shade100,
        Colors.deepOrange.shade600
      ],
      [
        Colors.deepPurple.shade50,
        Colors.deepPurple.shade100,
        Colors.deepPurple.shade600
      ],
      [
        Colors.lightBlue.shade50,
        Colors.lightBlue.shade100,
        Colors.lightBlue.shade600
      ],
      [
        Colors.lightGreen.shade50,
        Colors.lightGreen.shade100,
        Colors.lightGreen.shade600
      ],
      [Colors.brown.shade50, Colors.brown.shade100, Colors.brown.shade600],

      // ألوان متقدمة
      [Colors.grey.shade50, Colors.grey.shade100, Colors.grey.shade600],
      [
        Colors.blueGrey.shade50,
        Colors.blueGrey.shade100,
        Colors.blueGrey.shade600
      ],
      [Colors.yellow.shade50, Colors.yellow.shade100, Colors.yellow.shade700],
      [
        Colors.lightGreen.shade50,
        Colors.lightGreen.shade100,
        Colors.lightGreen.shade700
      ],
      [
        Colors.deepPurple.shade50,
        Colors.deepPurple.shade100,
        Colors.deepPurple.shade700
      ],
      [Colors.cyan.shade50, Colors.cyan.shade100, Colors.cyan.shade700],
    ];

    // استخدام اسم المنتج + معرف المنتج لضمان تنوع أكبر
    final productId = product['id'] as int? ?? 0;
    final combinedHash = (name.hashCode + productId.hashCode).abs();
    final colorIndex = combinedHash % cardColors.length;
    final cardColor = cardColors[colorIndex];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor[0], cardColor[1]],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cardColor[2].withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(
          color: cardColor[2].withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Action buttons - الجانب الأيسر
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionButton(
                    icon: Icons.edit_rounded,
                    color: Colors.white,
                    backgroundColor: cardColor[2],
                    onTap: onEdit,
                    tooltip: 'تعديل',
                  ),
                  const SizedBox(height: 6),
                  _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    color: Colors.white,
                    backgroundColor: Color(0xFFDC2626), // Professional Red
                    onTap: onDelete,
                    tooltip: 'حذف',
                  ),
                  if (barcode.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _ActionButton(
                      icon: Icons.qr_code_2_rounded,
                      color: Colors.white,
                      backgroundColor: Color(0xFF059669), // Professional Green
                      onTap: onShowBarcode,
                      tooltip: 'عرض الباركود',
                    ),
                  ],
                ],
              ),

              // Product details - الجانب الأيمن
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Product name
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cardColor[2].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: cardColor[2].withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: cardColor[2],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Barcode if exists
                    if (barcode.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context).colorScheme.outline
                                    : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.qr_code_2_rounded,
                              size: 12,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7)
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              barcode,
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.grey.shade700,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Price, cost, profit and quantity row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Price
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade50,
                                Colors.green.shade100
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.shade300,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.shade200.withOpacity(0.15),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.attach_money_rounded,
                                size: 14,
                                color: Colors.green.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'السعر: ${Formatters.currencyIQD(price)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Cost
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.purple.shade50,
                                Colors.purple.shade100
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.purple.shade300,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.shade200.withOpacity(0.3),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shopping_bag_rounded,
                                size: 14,
                                color: Colors.purple.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'التكلفة: ${Formatters.currencyIQD(cost)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Profit
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber.shade50,
                                Colors.amber.shade100
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.shade300,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.shade200.withOpacity(0.3),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.trending_up_rounded,
                                size: 14,
                                color: Colors.amber.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'الربح: ${Formatters.currencyIQD(profit)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Quantity
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.orange.shade50,
                                Colors.orange.shade100
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.orange.shade300,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.shade200.withOpacity(0.3),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_rounded,
                                size: 14,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'الكمية: ${quantity.toString()}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ActionButton({
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteProduct(int id) async {
    final db = context.read<DatabaseService>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: const Text('هل أنت متأكد من حذف هذا المنتج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final auth = context.read<AuthProvider>();
      final currentUser = auth.currentUser;
      await db.deleteProduct(
        id,
        userId: currentUser?.id,
        username: currentUser?.username,
        name: currentUser?.name,
      );
      if (!mounted) return;
      setState(() {}); // تحديث الواجهة بعد الحذف
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف المنتج بنجاح'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _openProductEditor(Map<String, Object?> product) async {
    final db = context.read<DatabaseService>();
    final isEdit = product['id'] != null;

    final nameCtrl = TextEditingController(
      text: product['name']?.toString() ?? '',
    );
    final barcodeCtrl = TextEditingController(
      text: product['barcode']?.toString() ?? '',
    );
    final priceCtrl = TextEditingController(
      text: (product['price'] as num?)?.toString() ?? '',
    );
    final costCtrl = TextEditingController(
      text: (product['cost'] as num?)?.toString() ?? '',
    );
    final qtyCtrl = TextEditingController(
      text: (product['quantity'] as num?)?.toString() ?? '',
    );

    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(
            isEdit ? 'تعديل منتج' : 'إضافة منتج',
            textAlign: TextAlign.right,
          ),
          content: SizedBox(
            width: 500,
            height: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // قسم المعلومات الأساسية
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1)
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3)
                              : Colors.blue.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.blue.shade700,
                                  size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'المعلومات الأساسية',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Colors.blue.shade800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: nameCtrl,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            decoration: const InputDecoration(
                              labelText: 'اسم المنتج',
                              hintText: 'مطلوب',
                              helperText: 'اسم المنتج كما سيظهر في الفواتير',
                              prefixIcon: Icon(Icons.inventory_2),
                              alignLabelWithHint: true,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'اسم المنتج مطلوب'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: barcodeCtrl,
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  decoration: const InputDecoration(
                                    labelText: 'الباركود',
                                    hintText: 'اختياري',
                                    helperText: 'رقم الباركود للمنتج',
                                    prefixIcon: Icon(Icons.qr_code),
                                    alignLabelWithHint: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () {
                                  // توليد باركود عشوائي
                                  final random = DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString();
                                  barcodeCtrl.text =
                                      random.substring(random.length - 8);
                                },
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('توليد'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // قسم الأسعار والمخزون
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.1)
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.3)
                              : Colors.green.shade200,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.attach_money,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(context).colorScheme.secondary
                                      : Colors.green.shade700,
                                  size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'الأسعار والمخزون',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Colors.green.shade800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: priceCtrl,
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'السعر',
                                    hintText: 'مطلوب',
                                    helperText: 'سعر البيع للعميل',
                                    prefixIcon: Icon(Icons.sell),
                                    alignLabelWithHint: true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9.]')),
                                  ],
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'السعر مطلوب';
                                    }
                                    final price = double.tryParse(v.trim());
                                    if (price == null || price < 0) {
                                      return 'يرجى إدخال سعر صحيح';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: TextFormField(
                                  controller: costCtrl,
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'الكلفة',
                                    hintText: 'اختياري',
                                    helperText: 'تكلفة الشراء',
                                    prefixIcon: Icon(Icons.shopping_cart),
                                    alignLabelWithHint: true,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9.]')),
                                  ],
                                  validator: (v) {
                                    if (v != null && v.trim().isNotEmpty) {
                                      final cost = double.tryParse(v.trim());
                                      if (cost == null || cost < 0) {
                                        return 'يرجى إدخال كلفة صحيحة';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                          TextFormField(
                            controller: qtyCtrl,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            keyboardType: const TextInputType.numberWithOptions(
                                signed: false),
                            decoration: const InputDecoration(
                              labelText: 'الكمية',
                              hintText: 'مطلوب',
                              helperText: 'الكمية المتوفرة في المخزون',
                              prefixIcon: Icon(Icons.inventory),
                              alignLabelWithHint: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'الكمية مطلوبة';
                              }
                              final qty = int.tryParse(v.trim());
                              if (qty == null || qty < 1) {
                                return 'الكمية يجب أن تكون 1 أو أكثر';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;

                final values = <String, Object?>{
                  'name': nameCtrl.text.trim(),
                  'barcode': barcodeCtrl.text.trim().isEmpty
                      ? null
                      : barcodeCtrl.text.trim(),
                  'price': priceCtrl.text.trim().isEmpty
                      ? 0.0
                      : double.parse(priceCtrl.text.trim()),
                  'cost': costCtrl.text.trim().isEmpty
                      ? 0.0
                      : double.parse(costCtrl.text.trim()),
                  'quantity': (int.tryParse(qtyCtrl.text.trim()) ?? 1)
                      .clamp(1, double.infinity)
                      .toInt(),
                  'min_quantity': 1, // قيمة افتراضية
                  'category_id': widget.categoryId,
                };

                if (isEdit) {
                  await db.updateProduct(product['id'] as int, values);
                } else {
                  await db.insertProduct(values);
                }

                if (context.mounted) Navigator.pop(context, true);
              },
              child: const Text('حفظ'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && mounted) {
      setState(() {}); // تحديث الواجهة بعد التعديل
      // استدعاء callback لتحديث عدد المنتجات في كارت القسم
      if (!isEdit && widget.onProductAdded != null) {
        widget.onProductAdded!();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'تم تحديث المنتج' : 'تم إضافة المنتج'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showBarcode(String code) async {
    // Sanitize barcode to only include ASCII characters for CODE 128
    // CODE 128 only supports ASCII characters (0-127)
    String sanitizedCode = code.replaceAll(RegExp(r'[^\x00-\x7F]'), '');
    bool hasNonAscii = sanitizedCode.length != code.length;

    // If barcode is empty after sanitization, use a placeholder
    if (sanitizedCode.isEmpty && code.isNotEmpty) {
      sanitizedCode = 'INVALID';
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.qr_code_2_rounded, color: widget.categoryColor),
            const SizedBox(width: 8),
            const Text('باركود المنتج'),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.surface
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.outline
                  : widget.categoryColor.withOpacity(0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (code.isNotEmpty) ...[
                if (hasNonAscii)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'الباركود يحتوي على أحرف غير مدعومة. تم إزالتها للعرض.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.surface
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.outline
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      BarcodeWidget(
                        barcode: Barcode.code128(),
                        data: sanitizedCode.isNotEmpty
                            ? sanitizedCode
                            : 'INVALID',
                        width: 300,
                        height: 120,
                        color: Colors.black,
                        backgroundColor:
                            Color(0xFFFFFFFF), // Professional White
                        drawText: false,
                        errorBuilder: (context, error) => Container(
                          width: 300,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline,
                                    color: Colors.red.shade700, size: 32),
                                const SizedBox(height: 8),
                                Text(
                                  'خطأ في الترميز',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context).colorScheme.outline
                                    : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          code,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.grey.shade800,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (hasNonAscii && sanitizedCode != 'INVALID')
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'الباركود المرمّز: $sanitizedCode',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.qr_code_2_rounded,
                  size: 48,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                      : Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'لا يوجد باركود لهذا المنتج',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7)
                        : Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
