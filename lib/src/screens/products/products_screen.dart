// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../services/db/database_service.dart';
import '../../services/auth/auth_provider.dart';
import '../../utils/dark_mode_utils.dart';
import '../../utils/responsive_utils.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key, this.initialCategoryId});

  final int? initialCategoryId;

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _searchQuery = '';
  int? _selectedCategoryId;
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Pagination variables
  static const int _pageSize = 50;
  int _currentPage = 0;
  List<Map<String, Object?>> _products = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    _verticalScrollController.addListener(_onScroll);
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_verticalScrollController.position.pixels >=
            _verticalScrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMore) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadProducts({bool reset = false}) async {
    if (reset) {
      _currentPage = 0;
      _products.clear();
      _hasMore = true;
    }

    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final db = context.read<DatabaseService>();
      final offset = _currentPage * _pageSize;

      final products = await db.getAllProducts(
        query: _searchQuery.isEmpty ? null : _searchQuery,
        categoryId: _selectedCategoryId,
        limit: _pageSize,
        offset: offset,
      );

      if (mounted) {
        setState(() {
          // إنشاء نسخة قابلة للتعديل من القائمة لتجنب خطأ read-only
          final modifiableProducts = List<Map<String, Object?>>.from(products);
          if (reset) {
            _products = modifiableProducts;
          } else {
            _products.addAll(modifiableProducts);
          }
          _hasMore = products.length == _pageSize;
          _isLoading = false;

          // تحديث العدد الإجمالي عند إعادة التحميل
          if (reset) {
            _totalCount = products.length;
            // تحميل العدد الإجمالي في الخلفية
            db
                .getProductsCount(
              query: _searchQuery.isEmpty ? null : _searchQuery,
              categoryId: _selectedCategoryId,
            )
                .then((count) {
              if (mounted) {
                setState(() => _totalCount = count);
              }
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل المنتجات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoading || !_hasMore) return;
    _currentPage++;
    await _loadProducts();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    _loadProducts(reset: true);
  }

  void _onCategoryChanged(int? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _loadProducts(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);
    final isVerySmallScreen = ResponsiveUtils.isVerySmallScreen(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          // Header with search and filters
          _buildHeader(context, isSmallScreen, isVerySmallScreen),

          // Products table
          Expanded(
            child: Container(
              margin: ResponsiveUtils.getResponsiveMargin(context),
              decoration: BoxDecoration(
                color: DarkModeUtils.getSurfaceColor(context),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Table header
                  _buildTableHeader(context, isSmallScreen, isVerySmallScreen),

                  // Table content
                  Expanded(
                    child: _buildTableContent(
                        context, db, isSmallScreen, isVerySmallScreen),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, bool isSmallScreen, bool isVerySmallScreen) {
    return Container(
      padding: ResponsiveUtils.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title and add button
          Row(
            children: [
              Expanded(
                child: Text(
                  'إدارة المنتجات',
                  style: TextStyle(
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 24),
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _openProductEditor({}),
                icon: const Icon(Icons.add_rounded),
                label: Text(isSmallScreen ? 'إضافة' : 'إضافة منتج'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16,
                    vertical: isSmallScreen ? 8 : 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Search and filter row
          isSmallScreen
              ? Column(
                  children: [
                    _buildSearchField(context, isVerySmallScreen),
                    const SizedBox(height: 12),
                    _buildCategoryFilter(context),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                        flex: 2,
                        child: _buildSearchField(context, isVerySmallScreen)),
                    const SizedBox(width: 16),
                    Expanded(flex: 1, child: _buildCategoryFilter(context)),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, bool isVerySmallScreen) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.arrowUp):
            DoNothingAndStopPropagationIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowDown):
            DoNothingAndStopPropagationIntent(),
      },
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'البحث في المنتجات...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: DarkModeUtils.getBorderColor(context),
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: isVerySmallScreen ? 12 : 16,
            vertical: isVerySmallScreen ? 8 : 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context) {
    final db = context.read<DatabaseService>();

    return FutureBuilder<List<Map<String, Object?>>>(
      future: db.getCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final categories = snapshot.data!;

        return DropdownButtonFormField<int>(
          initialValue: _selectedCategoryId,
          decoration: InputDecoration(
            labelText: 'الفئة',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: DarkModeUtils.getBorderColor(context),
              ),
            ),
          ),
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text('جميع الفئات'),
            ),
            ...categories.map((category) => DropdownMenuItem<int>(
                  value: category['id'] as int,
                  child: Text(category['name']?.toString() ?? ''),
                )),
          ],
          onChanged: _onCategoryChanged,
        );
      },
    );
  }

  Widget _buildTableHeader(
      BuildContext context, bool isSmallScreen, bool isVerySmallScreen) {
    final columnWidths =
        ResponsiveUtils.getResponsiveTableColumnWidths(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.85),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _horizontalScrollController,
        physics: const BouncingScrollPhysics(),
        child: Table(
          columnWidths: columnWidths,
          border: TableBorder.symmetric(
            inside: BorderSide(
              color: DarkModeUtils.getBorderColor(context),
              width: isVerySmallScreen ? 0.5 : 1,
            ),
          ),
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: Colors.transparent,
              ),
              children: [
                _buildHeaderCell(
                    'التسلسل', context, isSmallScreen, isVerySmallScreen),
                _buildHeaderCell(
                    'الاسم', context, isSmallScreen, isVerySmallScreen),
                _buildHeaderCell(
                    'الباركود', context, isSmallScreen, isVerySmallScreen),
                _buildHeaderCell(
                    'الكمية', context, isSmallScreen, isVerySmallScreen),
                _buildHeaderCell(
                    'التكلفة', context, isSmallScreen, isVerySmallScreen),
                _buildHeaderCell(
                    'السعر', context, isSmallScreen, isVerySmallScreen),
                _buildHeaderCell(
                    'الإجراءات', context, isSmallScreen, isVerySmallScreen),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String title, BuildContext context,
      bool isSmallScreen, bool isVerySmallScreen) {
    return Container(
      height: isVerySmallScreen ? 50 : 65,
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmallScreen ? 8 : 12,
        vertical: isVerySmallScreen ? 8 : 16,
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.w700,
            fontSize: isVerySmallScreen
                ? 11
                : isSmallScreen
                    ? 13
                    : 15,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }

  Widget _buildTableContent(BuildContext context, DatabaseService db,
      bool isSmallScreen, bool isVerySmallScreen) {
    if (_isLoading && _products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final products = _products;

    if (products.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                  : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'لا توجد منتجات' : 'لا توجد نتائج للبحث',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                    : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'قم بإضافة منتجات جديدة'
                  : 'جرب البحث بكلمات مختلفة',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                    : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openProductEditor({}),
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة منتج'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: _verticalScrollController,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _horizontalScrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Table(
              columnWidths:
                  ResponsiveUtils.getResponsiveTableColumnWidths(context),
              border: TableBorder.symmetric(
                inside: BorderSide(
                  color: DarkModeUtils.getBorderColor(context),
                  width: isVerySmallScreen ? 0.5 : 1,
                ),
              ),
              children: [
                ...List.generate(products.length, (index) {
                  final product = products[index];
                  final quantity = (product['quantity'] as num?)?.toInt() ?? 0;
                  final isOutOfStock = quantity == 0;
                  return TableRow(
                    decoration: BoxDecoration(
                      color:
                          _getRowBackgroundColor(context, index, isOutOfStock),
                    ),
                    children: [
                      _buildDataCell('${index + 1}', context, isSmallScreen,
                          isVerySmallScreen),
                      _buildDataCell(
                        product['name']?.toString() ?? 'بدون اسم',
                        context,
                        isSmallScreen,
                        isVerySmallScreen,
                        maxLines: isVerySmallScreen ? 1 : 2,
                        showTooltip: true,
                      ),
                      _buildBarcodeCell(
                        product['barcode']?.toString() ?? '',
                        context,
                        isSmallScreen,
                        isVerySmallScreen,
                      ),
                      _buildDataCell(
                        product['quantity']?.toString() ?? '0',
                        context,
                        isSmallScreen,
                        isVerySmallScreen,
                        textColor: isOutOfStock ? Colors.red.shade700 : null,
                      ),
                      _buildDataCell(
                        _formatCurrency(product['cost'] ?? 0),
                        context,
                        isSmallScreen,
                        isVerySmallScreen,
                        textColor: Colors.red,
                      ),
                      _buildDataCell(
                        _formatCurrency(product['price'] ?? 0),
                        context,
                        isSmallScreen,
                        isVerySmallScreen,
                        textColor: Theme.of(context).colorScheme.primary,
                      ),
                      _buildActionsCell(
                          product, context, isSmallScreen, isVerySmallScreen),
                    ],
                  );
                }),
              ],
            ),
            // Loading indicator at the bottom
            if (_isLoading && _products.isNotEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            // Show total count if available
            if (_totalCount > 0 && !_isLoading)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'عرض ${_products.length} من $_totalCount منتج',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getRowBackgroundColor(
      BuildContext context, int index, bool isOutOfStock) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // إذا كانت الكمية 0، استخدم لون مختلف بالكامل
    if (isOutOfStock) {
      return isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50;
    }

    // Subtle zebra striping with slight hue shift and hover-like sheen
    if (index % 2 == 0) {
      return isDark
          ? theme.colorScheme.surface.withOpacity(0.95)
          : theme.colorScheme.surface;
    }

    // Accented alternate row
    final base = isDark
        ? theme.colorScheme.primary.withOpacity(0.06)
        : theme.colorScheme.primary.withOpacity(0.05);
    return base;
  }

  Widget _buildDataCell(String text, BuildContext context, bool isSmallScreen,
      bool isVerySmallScreen,
      {int maxLines = 1, Color? textColor, bool showTooltip = false}) {
    final textWidget = Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: isVerySmallScreen
            ? 10
            : isSmallScreen
                ? 12
                : 14,
        color: textColor ?? Theme.of(context).colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );

    return Container(
      height: isVerySmallScreen ? 60 : 85,
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmallScreen ? 8 : 12,
        vertical: isVerySmallScreen ? 8 : 16,
      ),
      child: Center(
        child: showTooltip
            ? Tooltip(
                message: text,
                child: textWidget,
              )
            : textWidget,
      ),
    );
  }

  Widget _buildBarcodeCell(String barcode, BuildContext context,
      bool isSmallScreen, bool isVerySmallScreen) {
    final displayBarcode =
        _abbreviateMiddle(barcode, head: 6, tail: 4, minLength: 14);

    return Container(
      height: isVerySmallScreen ? 60 : 80,
      padding: EdgeInsets.all(isVerySmallScreen ? 8 : 16),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Tooltip(
                message: barcode,
                child: Text(
                  displayBarcode,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    fontSize: isVerySmallScreen
                        ? 9
                        : isSmallScreen
                            ? 11
                            : 13,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (barcode.isNotEmpty) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _showBarcode(context, barcode),
                child: Icon(
                  Icons.qr_code_2_rounded,
                  size: isVerySmallScreen ? 16 : 18,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCell(Map<String, Object?> product, BuildContext context,
      bool isSmallScreen, bool isVerySmallScreen) {
    return Container(
      height: isVerySmallScreen ? 60 : 80,
      padding: EdgeInsets.all(isVerySmallScreen ? 4 : 8),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Edit button
            IconButton(
              onPressed: () => _openProductEditor(product),
              icon: Icon(
                Icons.edit_rounded,
                size: isVerySmallScreen ? 16 : 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: 'تعديل',
              padding: EdgeInsets.all(isVerySmallScreen ? 2 : 4),
              constraints: BoxConstraints(
                minWidth: isVerySmallScreen ? 24 : 32,
                minHeight: isVerySmallScreen ? 24 : 32,
              ),
            ),

            // Delete button
            IconButton(
              onPressed: () => _deleteProduct(context, product['id'] as int),
              icon: Icon(
                Icons.delete_rounded,
                size: isVerySmallScreen ? 16 : 18,
                color: Colors.red,
              ),
              tooltip: 'حذف',
              padding: EdgeInsets.all(isVerySmallScreen ? 2 : 4),
              constraints: BoxConstraints(
                minWidth: isVerySmallScreen ? 24 : 32,
                minHeight: isVerySmallScreen ? 24 : 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _abbreviateMiddle(String text,
      {int head = 6, int tail = 4, int minLength = 14}) {
    if (text.length <= minLength) return text;
    if (head + tail >= text.length) return text;
    return '${text.substring(0, head)}...${text.substring(text.length - tail)}';
  }

  String _formatCurrency(dynamic value) {
    final numValue =
        value is num ? value : (double.tryParse(value.toString()) ?? 0);
    final formattedNumber = _formatNumber(numValue.toStringAsFixed(0));
    return '$formattedNumber د.ع';
  }

  String _formatNumber(String number) {
    if (number.length <= 3) return number;

    String result = '';
    int count = 0;

    for (int i = number.length - 1; i >= 0; i--) {
      if (count == 3) {
        result = ',$result';
        count = 0;
      }
      result = number[i] + result;
      count++;
    }

    return result;
  }

  Widget _buildCategoryDropdown(
    DatabaseService db,
    int? selectedCategoryId,
    Function setDialogState,
    void Function(int?) onChanged,
  ) {
    return FutureBuilder<List<Map<String, Object?>>>(
      future: db.getCategories(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final categories = snapshot.data!;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<int>(
            initialValue: selectedCategoryId,
            menuMaxHeight: 200,
            isDense: true,
            decoration: InputDecoration(
              labelText: 'الفئة',
              prefixIcon: Icon(
                Icons.category_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: DarkModeUtils.getBorderColor(context),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: DarkModeUtils.getBorderColor(context),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: [
              DropdownMenuItem<int>(
                value: null,
                child: Row(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      color: Colors.grey,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'بدون فئة (اختياري)',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              ...categories.map((category) => DropdownMenuItem<int>(
                    value: category['id'] as int,
                    child: Row(
                      children: [
                        Icon(
                          Icons.category_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          category['name']?.toString() ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  )),
            ],
            onChanged: (value) {
              onChanged(value);
              setDialogState(() {});
            },
          ),
        );
      },
    );
  }

  Future<void> _deleteProduct(BuildContext context, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المنتج'),
        content: const Text(
          'هل أنت متأكد من حذف هذا المنتج؟\nسيتم حذف المنتج فقط دون التأثير على المبيعات السابقة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = context.read<DatabaseService>();
      final auth = context.read<AuthProvider>();
      final currentUser = auth.currentUser;
      await db.deleteProduct(
        id,
        userId: currentUser?.id,
        username: currentUser?.username,
        name: currentUser?.name,
      );
      if (!mounted) return;
      // إعادة تحميل المنتجات من قاعدة البيانات
      await _loadProducts(reset: true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف المنتج بنجاح')),
      );
    }
  }

  Future<void> _openProductEditor(Map<String, Object?> product) async {
    final db = context.read<DatabaseService>();
    final isEdit = product['id'] != null;

    final nameCtrl =
        TextEditingController(text: product['name']?.toString() ?? '');
    final barcodeCtrl =
        TextEditingController(text: product['barcode']?.toString() ?? '');
    final quantityCtrl =
        TextEditingController(text: product['quantity']?.toString() ?? '0');
    final costCtrl =
        TextEditingController(text: product['cost']?.toString() ?? '0');
    final priceCtrl =
        TextEditingController(text: product['price']?.toString() ?? '0');

    int? selectedCategoryId = product['category_id'] as int?;

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(
              isEdit ? 'تعديل منتج' : 'إضافة منتج',
              textAlign: TextAlign.right,
            ),
            content: SizedBox(
              width: 520,
              height: 540,
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
                            color:
                                Theme.of(context).brightness == Brightness.dark
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
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurface
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
                      const SizedBox(height: 12),
                      // قسم الفئة
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context)
                                  .colorScheme
                                  .tertiary
                                  .withOpacity(0.08)
                              : Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context)
                                        .colorScheme
                                        .tertiary
                                        .withOpacity(0.3)
                                    : Colors.purple.shade200,
                          ),
                        ),
                        child: _buildCategoryDropdown(
                          db,
                          selectedCategoryId,
                          setDialogState,
                          (value) => selectedCategoryId = value,
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
                            color:
                                Theme.of(context).brightness == Brightness.dark
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
                                        ? Theme.of(context)
                                            .colorScheme
                                            .secondary
                                        : Colors.green.shade700,
                                    size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'الأسعار والمخزون',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurface
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
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: quantityCtrl,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
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
                    'quantity': (int.tryParse(quantityCtrl.text.trim()) ?? 1)
                        .clamp(1, double.infinity)
                        .toInt(),
                    'min_quantity': 1,
                    'category_id': selectedCategoryId,
                  };

                  try {
                    if (isEdit) {
                      await db.updateProduct(product['id'] as int, values);
                    } else {
                      await db.insertProduct(values);
                    }
                    if (context.mounted) Navigator.pop(context, true);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('خطأ: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
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
      ),
    );

    if (result == true && mounted) {
      // إعادة تحميل المنتجات من قاعدة البيانات
      await _loadProducts(reset: true);
    }
  }

  Future<void> _showBarcode(BuildContext context, String barcode) async {
    // Sanitize barcode to only include ASCII characters for CODE 128
    // CODE 128 only supports ASCII characters (0-127)
    String sanitizedBarcode = barcode.replaceAll(RegExp(r'[^\x00-\x7F]'), '');
    bool hasNonAscii = sanitizedBarcode.length != barcode.length;

    // If barcode is empty after sanitization, use a placeholder
    if (sanitizedBarcode.isEmpty) {
      sanitizedBarcode = 'INVALID';
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.qr_code_2_rounded, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            const Text('الباركود'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: BarcodeWidget(
                barcode: Barcode.code128(),
                data: sanitizedBarcode,
                width: 200,
                height: 100,
                errorBuilder: (context, error) => Container(
                  width: 200,
                  height: 100,
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
            ),
            const SizedBox(height: 16),
            Text(
              barcode,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (hasNonAscii && sanitizedBarcode != 'INVALID')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'الباركود المرمّز: $sanitizedBarcode',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
