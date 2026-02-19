// ignore_for_file: dead_code, use_build_context_synchronously, unused_field

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/db/database_service.dart';
import '../services/print_service.dart';
import '../services/store_config.dart';
import '../services/auth/auth_provider.dart';
import '../models/user_model.dart';
import '../utils/format.dart';
import '../utils/dark_mode_utils.dart';
import '../widgets/require_permission.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  String _query = '';
  final List<Map<String, Object?>> _cart = [];
  String _type = 'cash';
  List<Map<String, Object?>> _lastInvoiceItems = [];
  String _lastType = 'cash';
  int? _lastInvoiceId; // رقم آخر فاتورة تم إنشاؤها
  final Set<int> _addedToCartProducts = {}; // Track products added to cart
  final TextEditingController _searchController = TextEditingController();

// Customer information controllers
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _customerAddressController =
      TextEditingController();

  // Customers list for autocomplete
  List<Map<String, Object?>> _customersList = [];
  bool _customersLoaded = false;
  final FocusNode _customerNameFocusNode = FocusNode();

// Credit system variables
  DateTime? _dueDate;
  String _customerName = '';
  String _customerPhone = '';
  String _customerAddress = '';

// Installment system variables
  int? _installmentCount;
  double? _downPayment;
  DateTime? _firstInstallmentDate;

// Last invoice credit info
  DateTime? _lastDueDate;
  String _lastCustomerName = '';
  String _lastCustomerPhone = '';
  String _lastCustomerAddress = '';

// Last invoice installment info
  List<Map<String, Object?>>? _lastInstallments;
  double? _lastTotalDebt;
  double? _lastDownPayment;
  double? _lastCouponDiscount;
  double? _lastSubtotal;

// Coupon system variables
  String? _couponCode;
  int? _couponId;
  double _couponDiscount = 0.0;
  Map<String, Object?>? _appliedCoupon;

// Print settings
  String _selectedPrintType = '80'; // نوع الطباعة المختار

  /// تحميل قائمة العملاء
  Future<void> _loadCustomers(DatabaseService db) async {
    if (_customersLoaded) return;
    final customers = await db.getCustomers();
    if (mounted) {
      setState(() {
        _customersList = customers;
        _customersLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerAddressController.dispose();
    _customerNameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();
    final auth = context.watch<AuthProvider>();

    // تحميل قائمة العملاء عند أول تحميل
    if (!_customersLoaded) {
      _loadCustomers(db);
    }

    // فحص صلاحية إدارة المبيعات
    if (!auth.hasPermission(UserPermission.manageSales)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المبيعات'),
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
                'هذه الصفحة متاحة لجميع المستخدمين',
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

    // حساب الإجمالي مع الخصومات
    double subtotal = 0.0;
    int totalQuantity = 0;
    for (final item in _cart) {
      final price = (item['price'] as num).toDouble();
      final quantity = (item['quantity'] as num).toInt();
      final discountPercent =
          ((item['discount_percent'] ?? 0) as num).toDouble();
      final itemTotal =
          price * (1 - (discountPercent.clamp(0, 100) / 100)) * quantity;
      subtotal += itemTotal;
      totalQuantity += quantity;
    }

    // تطبيق خصم الكوبون
    final total = (subtotal - _couponDiscount).clamp(0.0, double.infinity);

    InputDecoration pill(String hint, IconData icon) => InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 11),
          labelStyle: const TextStyle(fontSize: 11),
          isDense: true,
          prefixIcon: Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          filled: true,
          fillColor: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withOpacity(0.25),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.4),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        );

    return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              // Header Section - Compact
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DarkModeUtils.getCardColor(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: DarkModeUtils.getBorderColor(context),
                  ),
                ),
                child: Row(
                  children: [
                    // Title and Icon
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.point_of_sale,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'نظام المبيعات',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: DarkModeUtils.getTextColor(context),
                          ),
                    ),
                    const Spacer(),
                    // Total Amount
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.attach_money,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer
                                    : Theme.of(context).colorScheme.onPrimary,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            Formatters.currencyIQD(total),
                            style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                  : Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Controls Row - Compact
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '🔍 ابحث عن منتج...',
                        isDense: true,
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withOpacity(0.25),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                Theme.of(context).dividerColor.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                Theme.of(context).dividerColor.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              Theme.of(context).dividerColor.withOpacity(0.5),
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: _type,
                        decoration:
                            pill('💳 نوع الدفع', Icons.payments_outlined),
                        items: const [
                          DropdownMenuItem(
                            value: 'cash',
                            child: Row(
                              children: [
                                Icon(Icons.money, size: 16),
                                SizedBox(width: 6),
                                Text('نقدي'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'installment',
                            child: Row(
                              children: [
                                Icon(Icons.credit_card, size: 16),
                                SizedBox(width: 6),
                                Text('أقساط'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'credit',
                            child: Row(
                              children: [
                                Icon(Icons.schedule, size: 16),
                                SizedBox(width: 6),
                                Text('أجل'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _type = v ?? 'cash';
                            // Clear due date only when changing from credit to other types
                            if (_type != 'credit') {
                              _dueDate = null;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Customer information fields - compact version with dynamic colors
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getCustomerInfoBackgroundColor(),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getCustomerInfoBorderColor(),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _getCustomerInfoShadowColor(),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Customer Name with Autocomplete
                    Expanded(
                      flex: 1,
                      child: RawAutocomplete<Map<String, Object?>>(
                        textEditingController: _customerNameController,
                        focusNode: _customerNameFocusNode,
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return _customersList;
                          }
                          final query = textEditingValue.text.toLowerCase();
                          return _customersList.where((customer) {
                            final name =
                                customer['name']?.toString().toLowerCase() ??
                                    '';
                            final phone =
                                customer['phone']?.toString().toLowerCase() ??
                                    '';
                            return name.contains(query) ||
                                phone.contains(query);
                          }).toList();
                        },
                        displayStringForOption: (Map<String, Object?> option) {
                          return option['name']?.toString() ?? '';
                        },
                        onSelected: (Map<String, Object?> selection) {
                          setState(() {
                            _customerName = selection['name']?.toString() ?? '';
                            _customerPhone =
                                selection['phone']?.toString() ?? '';
                            _customerAddress =
                                selection['address']?.toString() ?? '';
                            _customerNameController.text = _customerName;
                            _customerPhoneController.text = _customerPhone;
                            _customerAddressController.text = _customerAddress;
                          });
                        },
                        fieldViewBuilder: (BuildContext context,
                            TextEditingController textEditingController,
                            FocusNode focusNode,
                            VoidCallback onFieldSubmitted) {
                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            decoration: pill(
                                '👤 اسم العميل (اختر أو اكتب)', Icons.person),
                            onChanged: (v) {
                              _customerName = v;
                              // إذا تم مسح الحقل، امسح الحقول الأخرى أيضاً
                              if (v.isEmpty) {
                                _customerPhone = '';
                                _customerAddress = '';
                                _customerPhoneController.clear();
                                _customerAddressController.clear();
                              }
                            },
                            onSubmitted: (String value) {
                              onFieldSubmitted();
                            },
                          );
                        },
                        optionsViewBuilder: (BuildContext context,
                            AutocompleteOnSelected<Map<String, Object?>>
                                onSelected,
                            Iterable<Map<String, Object?>> options) {
                          return Align(
                            alignment: Alignment.topRight,
                            child: Material(
                              elevation: 4.0,
                              borderRadius: BorderRadius.circular(8),
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxHeight: 200),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: options.length,
                                  itemBuilder:
                                      (BuildContext context, int index) {
                                    final customer = options.elementAt(index);
                                    final name =
                                        customer['name']?.toString() ?? '';
                                    final phone =
                                        customer['phone']?.toString() ?? '';
                                    return InkWell(
                                      onTap: () {
                                        onSelected(customer);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        child: Row(
                                          children: [
                                            Icon(Icons.person,
                                                size: 18,
                                                color:
                                                    DarkModeUtils.getInfoColor(
                                                        context)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  if (phone.isNotEmpty)
                                                    Text(
                                                      phone,
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: DarkModeUtils
                                                              .getSecondaryTextColor(
                                                                  context)),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Customer Phone (default)
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _customerPhoneController,
                        decoration: pill('📱 الهاتف', Icons.phone),
                        onChanged: (v) => _customerPhone = v,
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Customer Address (default)
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _customerAddressController,
                        decoration: pill('📍 العنوان', Icons.location_on),
                        onChanged: (v) => _customerAddress = v,
                      ),
                    ),
                    // ملاحظة توضيحية لمعلومات العميل
                    if (_type == 'cash') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              'اختياري',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // ملاحظة توضيحية للبيع الآجل
                    if (_type == 'credit' || _type == 'installment') ...[],
                    // Due Date field - only show for credit payments (default)
                    if (_type == 'credit') ...[
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 1,
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate:
                                  DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() => _dueDate = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _dueDate != null
                                        ? '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'
                                        : '📅 تاريخ الاستحقاق',
                                    style: TextStyle(
                                      color: _dueDate != null
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    // Installment fields - only show for installment payments (default)
                    if (_type == 'installment') ...[
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          decoration: pill('🔢 عدد الأقساط', Icons.numbers),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _installmentCount =
                              v.isEmpty ? null : int.tryParse(v),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          decoration: pill('💰 المقدم (د.ع)', Icons.money),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _downPayment =
                              v.isEmpty ? null : double.tryParse(v),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 1,
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate:
                                  DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() => _firstInstallmentDate = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .dividerColor
                                    .withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _firstInstallmentDate != null
                                        ? '${_firstInstallmentDate!.day}/${_firstInstallmentDate!.month}/${_firstInstallmentDate!.year}'
                                        : '📅 تاريخ أول قسط',
                                    style: TextStyle(
                                      color: _firstInstallmentDate != null
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6),
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Address remains in default position above
                    ],
                  ],
                ),
              ),
              Divider(),
              Expanded(
                child: Row(
                  children: [
                    // Products side
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? 0.3
                                      : 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.inventory_2,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'المنتجات المتاحة',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'اختر المنتجات لإضافتها للسلة',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary
                                                .withOpacity(0.9),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: FutureBuilder<
                                        List<Map<String, Object?>>>(
                                      // في صفحة المبيعات: عدّ المنتجات بعد التصفية بالباركود فقط
                                      future: db.getAllProducts(),
                                      builder: (context, snapshot) {
                                        final items = snapshot.data ?? [];
                                        final query = _query.trim();
                                        final filteredItems = query.isEmpty
                                            ? items
                                            : items.where((item) {
                                                final barcode = item['barcode']
                                                        ?.toString()
                                                        .trim() ??
                                                    '';
                                                // هنا نظهر فقط المطابق تماماً للباركود
                                                return barcode.isNotEmpty &&
                                                    barcode == query;
                                              }).toList();

                                        final count = filteredItems.length;
                                        return Text(
                                          '$count منتج',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Products List
                            Expanded(
                              child: FutureBuilder<List<Map<String, Object?>>>(
                                // في صفحة المبيعات: عرض المنتجات المصفّاة بالباركود فقط
                                future: db.getAllProducts(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CircularProgressIndicator(),
                                          SizedBox(height: 16),
                                          Text('جاري تحميل المنتجات...'),
                                        ],
                                      ),
                                    );
                                  }
                                  final allItems = snapshot.data ?? [];
                                  final query = _query.trim();
                                  final items = query.isEmpty
                                      ? allItems
                                      : allItems.where((item) {
                                          final barcode = item['barcode']
                                                  ?.toString()
                                                  .trim() ??
                                              '';
                                          // إظهار المنتج فقط إذا كان باركوده يطابق النص بالكامل
                                          return barcode.isNotEmpty &&
                                              barcode == query;
                                        }).toList();

                                  if (items.isEmpty) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.search_off,
                                            size: 64,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.3),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'لا توجد منتجات',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.5),
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'جرب إدخال الباركود بشكل صحيح',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.4),
                                                ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  return ListView.separated(
                                    padding: const EdgeInsets.all(8),
                                    itemCount: items.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 6),
                                    itemBuilder: (context, i) {
                                      final p = items[i];
                                      final stock = p['quantity'] as int? ?? 0;
                                      final isOutOfStock = stock <= 0;

                                      return Container(
                                        decoration: BoxDecoration(
                                          gradient: isOutOfStock
                                              ? LinearGradient(
                                                  colors: [
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .surfaceContainerHighest
                                                        .withOpacity(0.35),
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .surface,
                                                  ],
                                                )
                                              : LinearGradient(
                                                  colors: [
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .surface,
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .surfaceContainerHighest
                                                        .withOpacity(0.08),
                                                  ],
                                                ),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isOutOfStock
                                                ? Theme.of(context)
                                                    .dividerColor
                                                    .withOpacity(0.4)
                                                : Theme.of(context)
                                                    .dividerColor
                                                    .withOpacity(0.3),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                  Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? 0.25
                                                      : 0.03),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Row(
                                              children: [
                                                // Product Icon
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: isOutOfStock
                                                        ? Colors.grey.shade300
                                                        : Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Icon(
                                                    Icons.inventory,
                                                    color: isOutOfStock
                                                        ? Colors.grey.shade600
                                                        : Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                    size: 16,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),

                                                // Product Info
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        p['name']?.toString() ??
                                                            '',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: isOutOfStock
                                                              ? Colors
                                                                  .grey.shade600
                                                              : Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onSurface,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Wrap(
                                                        spacing: 8,
                                                        runSpacing: 4,
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical:
                                                                        4),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: isOutOfStock
                                                                  ? Colors.grey
                                                                      .shade200
                                                                  : Colors.green
                                                                      .shade100,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                            ),
                                                            child: Text(
                                                              Formatters
                                                                  .currencyIQD(
                                                                      p['price']
                                                                          as num),
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: isOutOfStock
                                                                    ? Colors
                                                                        .grey
                                                                        .shade600
                                                                    : Colors
                                                                        .green
                                                                        .shade700,
                                                              ),
                                                            ),
                                                          ),
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical:
                                                                        4),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: isOutOfStock
                                                                  ? Colors.red
                                                                      .shade100
                                                                  : Colors.blue
                                                                      .shade100,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                            ),
                                                            child: Text(
                                                              'المتاح: $stock',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: isOutOfStock
                                                                    ? Colors.red
                                                                        .shade700
                                                                    : Colors
                                                                        .blue
                                                                        .shade700,
                                                              ),
                                                            ),
                                                          ),
                                                          // Code/Barcode Display (abbreviated + themed)
                                                          if (p['barcode']
                                                                  ?.toString()
                                                                  .isNotEmpty ==
                                                              true)
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          6,
                                                                      vertical:
                                                                          2),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .primary
                                                                    .withOpacity(
                                                                        0.12),
                                                                border:
                                                                    Border.all(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .primary
                                                                      .withOpacity(
                                                                          0.25),
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8),
                                                              ),
                                                              child: Tooltip(
                                                                message:
                                                                    p['barcode']
                                                                            ?.toString() ??
                                                                        '',
                                                                child: Text(
                                                                  'باركود: ${_shortBarcode(p['barcode'].toString())}',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize: 9,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .primary,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // Add to Cart Button - Enhanced Professional Design
                                                SizedBox(
                                                  height: 40,
                                                  child: ElevatedButton.icon(
                                                    onPressed: isOutOfStock
                                                        ? null
                                                        : () => _addToCart(p),
                                                    icon: Icon(
                                                      isOutOfStock
                                                          ? Icons.block
                                                          : _addedToCartProducts
                                                                  .contains(
                                                                      p['id'])
                                                              ? Icons
                                                                  .check_circle
                                                              : Icons
                                                                  .add_shopping_cart,
                                                      size: 18,
                                                    ),
                                                    label: Text(
                                                      isOutOfStock
                                                          ? 'نفد المخزون'
                                                          : _addedToCartProducts
                                                                  .contains(
                                                                      p['id'])
                                                              ? 'تم الإضافة'
                                                              : 'أضف للسلة',
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          isOutOfStock
                                                              ? Color(
                                                                  0xFF64748B) // Professional Gray
                                                              : (_addedToCartProducts
                                                                      .contains(p[
                                                                          'id'])
                                                                  ? Color(
                                                                      0xFF7C3AED) // Professional Purple
                                                                  : Color(
                                                                      0xFF059669)), // Professional Green
                                                      foregroundColor:
                                                          Colors.white,
                                                      elevation:
                                                          isOutOfStock ? 0 : 3,
                                                      shadowColor: isOutOfStock
                                                          ? null
                                                          : (_addedToCartProducts
                                                                  .contains(
                                                                      p['id'])
                                                              ? Color(0xFF7C3AED)
                                                                  .withOpacity(
                                                                      0.4)
                                                              : Color(0xFF059669)
                                                                  .withOpacity(
                                                                      0.4)),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 16,
                                                        vertical: 10,
                                                      ),
                                                      animationDuration:
                                                          const Duration(
                                                              milliseconds:
                                                                  200),
                                                    ),
                                                  ),
                                                ),
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
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Cart side
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? 0.3
                                      : 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.secondary,
                                    Theme.of(context)
                                        .colorScheme
                                        .secondary
                                        .withOpacity(0.8),
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSecondary
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.shopping_cart_checkout,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSecondary,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'سلة المشتريات',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSecondary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${_cart.length} منتج في السلة • إجمالي الكمية: $totalQuantity',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSecondary
                                                .withOpacity(0.9),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSecondary
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      Formatters.currencyIQD(total),
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Cart Items
                            Expanded(
                              child: _cart.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.shopping_cart_outlined,
                                            size: 64,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.3),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'السلة فارغة',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.5),
                                                ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'أضف منتجات من القائمة',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.4),
                                                ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.all(8),
                                      itemCount: _cart.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 6),
                                      itemBuilder: (context, i) {
                                        final c = _cart[i];
                                        final basePrice =
                                            (c['price'] as num).toDouble();
                                        final discount =
                                            ((c['discount_percent'] ?? 0)
                                                    as num)
                                                .toDouble()
                                                .clamp(0, 100);
                                        final effPrice =
                                            basePrice * (1 - (discount / 100));
                                        // السعر قبل تطبيق الكوبون
                                        final lineTotalBeforeCoupon =
                                            effPrice * (c['quantity'] as num);
                                        var lineTotal = lineTotalBeforeCoupon;

                                        // تطبيق خصم الكوبون على السعر بشكل متناسب
                                        if (_couponDiscount > 0 &&
                                            subtotal > 0) {
                                          final couponDiscountRatio =
                                              _couponDiscount / subtotal;
                                          lineTotal = lineTotal *
                                              (1 - couponDiscountRatio);
                                        }

                                        return Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Theme.of(context)
                                                    .colorScheme
                                                    .surface,
                                                Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest
                                                    .withOpacity(0.08),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .dividerColor
                                                  .withOpacity(0.3),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                    Theme.of(context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? 0.25
                                                        : 0.03),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: Row(
                                              children: [
                                                // Product Icon
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .secondary
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Icon(
                                                    Icons.inventory,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .secondary,
                                                    size: 16,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),

                                                // Product Info
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        c['name']?.toString() ??
                                                            '',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'الكمية: ${c['quantity']}',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .onSurface
                                                              .withOpacity(0.6),
                                                        ),
                                                      ),
                                                      // Code/Barcode in Cart (abbreviated)
                                                      if (c['barcode']
                                                              ?.toString()
                                                              .isNotEmpty ==
                                                          true)
                                                        Tooltip(
                                                          message: c['barcode']
                                                                  ?.toString() ??
                                                              '',
                                                          child: Text(
                                                            'باركود: ${_shortBarcode(c['barcode'].toString())}',
                                                            style: TextStyle(
                                                              fontSize: 9,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primary,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),

                                                // Quantity Controls + Delete + Discount
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    // Delete near minus (protected)
                                                    RequirePermission(
                                                      permission: UserPermission
                                                          .deleteSaleItem,
                                                      child: IconButton(
                                                        tooltip: 'حذف',
                                                        icon: Icon(
                                                          Icons.delete_outline,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .error,
                                                        ),
                                                        onPressed: () {
                                                          final qty = (_cart[i]
                                                                  ['quantity']
                                                              as int);
                                                          final productId = _cart[
                                                                      i]
                                                                  ['product_id']
                                                              as int;
                                                          context
                                                              .read<
                                                                  DatabaseService>()
                                                              .adjustProductQuantity(
                                                                  productId,
                                                                  qty);
                                                          setState(() {
                                                            _cart.removeAt(i);
                                                            _addedToCartProducts
                                                                .remove(
                                                                    productId);
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                    IconButton(
                                                      tooltip: 'إنقاص',
                                                      icon: const Icon(Icons
                                                          .remove_circle_outline),
                                                      onPressed: () =>
                                                          _decrementQty(i),
                                                      style:
                                                          IconButton.styleFrom(
                                                        backgroundColor:
                                                            Theme.of(context)
                                                                .colorScheme
                                                                .errorContainer,
                                                        foregroundColor: Theme
                                                                .of(context)
                                                            .colorScheme
                                                            .onErrorContainer,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 10,
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withOpacity(0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        border: Border.all(
                                                          color: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .primary
                                                              .withOpacity(0.3),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        (c['quantity'] as int)
                                                            .toString(),
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 10,
                                                    ),
                                                    IconButton(
                                                      tooltip: 'زيادة',
                                                      icon: const Icon(Icons
                                                          .add_circle_outline),
                                                      onPressed: () =>
                                                          _incrementQty(i),
                                                      style:
                                                          IconButton.styleFrom(
                                                        backgroundColor: Theme
                                                                .of(context)
                                                            .colorScheme
                                                            .tertiaryContainer,
                                                        foregroundColor: Theme
                                                                .of(context)
                                                            .colorScheme
                                                            .onTertiaryContainer,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        RequirePermission(
                                                          permission:
                                                              UserPermission
                                                                  .applyDiscount,
                                                          child: SizedBox(
                                                            width: 64,
                                                            child: Stack(
                                                              alignment: Alignment
                                                                  .centerRight,
                                                              children: [
                                                                TextFormField(
                                                                  initialValue:
                                                                      discount
                                                                          .toStringAsFixed(
                                                                              0),
                                                                  decoration:
                                                                      InputDecoration(
                                                                    labelText:
                                                                        'الخصم',
                                                                    labelStyle: TextStyle(
                                                                        fontSize:
                                                                            9,
                                                                        color: Theme.of(context)
                                                                            .hintColor),
                                                                    floatingLabelStyle:
                                                                        const TextStyle(
                                                                            fontSize:
                                                                                9),
                                                                    isDense:
                                                                        true,
                                                                    contentPadding: const EdgeInsets
                                                                        .symmetric(
                                                                        horizontal:
                                                                            6,
                                                                        vertical:
                                                                            6),
                                                                    border:
                                                                        const OutlineInputBorder(),
                                                                    counterText:
                                                                        '',
                                                                    suffixText:
                                                                        '%',
                                                                    suffixStyle: TextStyle(
                                                                        fontSize:
                                                                            10,
                                                                        color: Theme.of(context)
                                                                            .hintColor),
                                                                  ),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          12),
                                                                  maxLength: 3,
                                                                  keyboardType: const TextInputType
                                                                      .numberWithOptions(
                                                                      decimal:
                                                                          false),
                                                                  onChanged:
                                                                      (val) {
                                                                    final d =
                                                                        double.tryParse(val) ??
                                                                            0;
                                                                    setState(
                                                                        () {
                                                                      _cart[i][
                                                                              'discount_percent'] =
                                                                          d.clamp(
                                                                              0,
                                                                              100);
                                                                    });
                                                                  },
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),

                                                const SizedBox(width: 12),

                                                // Price with discount display
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    // السعر بعد الخصم والكوبون
                                                    Text(
                                                      Formatters.currencyIQD(
                                                          lineTotal),
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13,
                                                        color: discount > 0 ||
                                                                (_couponDiscount >
                                                                        0 &&
                                                                    subtotal >
                                                                        0)
                                                            ? Colors
                                                                .green.shade700
                                                            : Theme.of(context)
                                                                .colorScheme
                                                                .onSurface,
                                                      ),
                                                    ),
                                                    // عرض السعر قبل الكوبون إذا كان هناك كوبون
                                                    if (_couponDiscount > 0 &&
                                                        subtotal > 0 &&
                                                        lineTotal <
                                                            lineTotalBeforeCoupon)
                                                      Text(
                                                        Formatters.currencyIQD(
                                                            lineTotalBeforeCoupon),
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .onSurface
                                                              .withOpacity(0.6),
                                                          decoration:
                                                              TextDecoration
                                                                  .lineThrough,
                                                        ),
                                                      ),
                                                    // عرض السعر الأصلي إذا كان هناك خصم على العنصر فقط (بدون كوبون)
                                                    if (discount > 0 &&
                                                        !(_couponDiscount > 0 &&
                                                            subtotal > 0))
                                                      Text(
                                                        Formatters.currencyIQD(
                                                            basePrice *
                                                                (c['quantity']
                                                                    as num)),
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .onSurface
                                                              .withOpacity(0.6),
                                                          decoration:
                                                              TextDecoration
                                                                  .lineThrough,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            // Footer with controls
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withOpacity(0.3),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Total Amount
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.2),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        // Coupon Section - تصميم محسّن
                                        if (_cart.isNotEmpty)
                                          Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 8),
                                            child: _appliedCoupon != null
                                                ? Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10,
                                                        vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primaryContainer
                                                          .withOpacity(0.3),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      border: Border.all(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withOpacity(0.3),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.local_offer,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                          size: 14,
                                                        ),
                                                        const SizedBox(
                                                            width: 6),
                                                        Text(
                                                          '${_appliedCoupon!['code']}',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        Text(
                                                          'خصم: ${Formatters.currencyIQD(_couponDiscount)}',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: Colors
                                                                .green.shade700,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 4),
                                                        InkWell(
                                                          onTap: () {
                                                            setState(() {
                                                              _couponCode =
                                                                  null;
                                                              _couponId = null;
                                                              _couponDiscount =
                                                                  0.0;
                                                              _appliedCoupon =
                                                                  null;
                                                            });
                                                          },
                                                          child: Icon(
                                                            Icons.close,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .error,
                                                            size: 16,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : OutlinedButton.icon(
                                                    onPressed: () =>
                                                        _showCouponDialog(
                                                            context),
                                                    icon: const Icon(
                                                        Icons.local_offer,
                                                        size: 18),
                                                    label: const Text(
                                                        'إضافة كوبون خصم'),
                                                    style: OutlinedButton
                                                        .styleFrom(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 16,
                                                          vertical: 12),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      side: BorderSide(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withOpacity(0.5),
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                        // Total Section
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calculate,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'الإجمالي:',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              Formatters.currencyIQD(total),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                    fontSize: 14,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Action Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _cart.isEmpty
                                              ? null
                                              : () async {
                                                  // Return all items to stock before clearing cart
                                                  for (final item in _cart) {
                                                    final qty =
                                                        (item['quantity']
                                                                as int?) ??
                                                            0;
                                                    final productId =
                                                        item['product_id']
                                                            as int?;
                                                    if (productId != null &&
                                                        qty > 0) {
                                                      await context
                                                          .read<
                                                              DatabaseService>()
                                                          .adjustProductQuantity(
                                                              productId, qty);
                                                    }
                                                  }

                                                  // Immediately clear cart and related UI state
                                                  setState(() {
                                                    _cart.clear();
                                                    _addedToCartProducts
                                                        .clear();
                                                    _couponCode = null;
                                                    _couponId = null;
                                                    _couponDiscount = 0.0;
                                                    _appliedCoupon = null;
                                                  });

                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'تم تفريغ السلة وإرجاع المنتجات للمخزون'),
                                                      backgroundColor:
                                                          Colors.orange,
                                                    ),
                                                  );
                                                },
                                          icon: const Icon(Icons.clear_all),
                                          label: const Text('تفريغ السلة'),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                            side: BorderSide(
                                                color: Colors.orange.shade300),
                                            foregroundColor:
                                                Colors.orange.shade700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: _cart.isEmpty
                                              ? null
                                              : () async {
                                                  // Validate customer information requirements for credit and installment
                                                  if (_type == 'credit' ||
                                                      _type == 'installment') {
                                                    if (_customerName
                                                            .trim()
                                                            .isEmpty ||
                                                        _customerPhone
                                                            .trim()
                                                            .isEmpty ||
                                                        _customerAddress
                                                            .trim()
                                                            .isEmpty) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                              SnackBar(
                                                        content: Text(_type ==
                                                                'installment'
                                                            ? 'يرجى ملء جميع معلومات العميل للبيع بالأقساط'
                                                            : 'يرجى ملء جميع معلومات العميل للبيع بالأجل'),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ));
                                                      return;
                                                    }
                                                  }

                                                  // Additional validation for credit sales
                                                  if (_type == 'credit' &&
                                                      _dueDate == null) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                            const SnackBar(
                                                      content: Text(
                                                          'يرجى تحديد تاريخ الاستحقاق للبيع بالأجل'),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ));
                                                    return;
                                                  }

                                                  // التحقق من صحة بيانات الأقساط
                                                  if (_type == 'installment') {
                                                    if (_installmentCount ==
                                                            null ||
                                                        _installmentCount! <=
                                                            0) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              'يرجى إدخال عدد الأقساط صحيح'),
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                      );
                                                      return;
                                                    }

                                                    final totalAmount = _cart
                                                        .fold<double>(0,
                                                            (sum, item) {
                                                      final basePrice =
                                                          (item['price'] as num)
                                                              .toDouble();
                                                      final discount =
                                                          ((item['discount_percent'] ??
                                                                  0) as num)
                                                              .toDouble()
                                                              .clamp(0, 100);
                                                      final effectivePrice =
                                                          basePrice *
                                                              (1 -
                                                                  (discount /
                                                                      100));
                                                      final qty =
                                                          (item['quantity']
                                                                  as num)
                                                              .toDouble();
                                                      return sum +
                                                          (effectivePrice *
                                                              qty);
                                                    });

                                                    if (_downPayment != null &&
                                                        _downPayment! >=
                                                            totalAmount) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              'المقدم يجب أن يكون أقل من إجمالي المبلغ'),
                                                          backgroundColor:
                                                              Colors.red,
                                                        ),
                                                      );
                                                      return;
                                                    }
                                                  }

                                                  // الحصول على معلومات المستخدم الحالي
                                                  final currentUser =
                                                      auth.currentUser;

                                                  final saleId =
                                                      await db.createSale(
                                                    type: _type == 'cash'
                                                        ? 'cash'
                                                        : _type == 'installment'
                                                            ? 'installment'
                                                            : 'credit',
                                                    items: _cart,
                                                    decrementStock: false,
                                                    couponId: _couponId,
                                                    couponDiscount:
                                                        _couponDiscount > 0
                                                            ? _couponDiscount
                                                            : null,
                                                    customerName: (_type ==
                                                                'credit' ||
                                                            _type ==
                                                                'installment')
                                                        ? _customerName
                                                        : _customerName
                                                                .trim()
                                                                .isNotEmpty
                                                            ? _customerName
                                                            : null,
                                                    customerPhone: (_type ==
                                                                'credit' ||
                                                            _type ==
                                                                'installment')
                                                        ? _customerPhone
                                                        : _customerPhone
                                                                .trim()
                                                                .isNotEmpty
                                                            ? _customerPhone
                                                            : null,
                                                    customerAddress: (_type ==
                                                                'credit' ||
                                                            _type ==
                                                                'installment')
                                                        ? _customerAddress
                                                        : _customerAddress
                                                                .trim()
                                                                .isNotEmpty
                                                            ? _customerAddress
                                                            : null,
                                                    dueDate: _type == 'credit'
                                                        ? _dueDate
                                                        : null,
                                                    // إضافة معاملات الأقساط
                                                    installmentCount:
                                                        _type == 'installment'
                                                            ? _installmentCount
                                                            : null,
                                                    downPayment:
                                                        _type == 'installment'
                                                            ? _downPayment
                                                            : null,
                                                    firstInstallmentDate: _type ==
                                                            'installment'
                                                        ? _firstInstallmentDate
                                                        : null,
                                                    // إضافة معلومات المستخدم لتسجيل الحدث
                                                    userId: currentUser?.id,
                                                    username:
                                                        currentUser?.username,
                                                  );
                                                  if (!mounted) return;

                                                  // Save installment info for last invoice
                                                  if (_type == 'installment') {
                                                    _lastInstallments = await db
                                                        .getInstallments(
                                                            saleId: saleId);
                                                    final installmentSummary =
                                                        await db
                                                            .getSaleInstallmentSummary(
                                                                saleId);
                                                    _lastTotalDebt =
                                                        installmentSummary[
                                                                'totalDebt']
                                                            as double?;
                                                    _lastDownPayment =
                                                        _downPayment;
                                                  } else {
                                                    _lastInstallments = null;
                                                    _lastTotalDebt = null;
                                                    _lastDownPayment = null;
                                                  }

                                                  // حساب subtotal للفاتورة
                                                  double invoiceSubtotal = 0.0;
                                                  for (final item in _cart) {
                                                    final price =
                                                        (item['price'] as num)
                                                            .toDouble();
                                                    final quantity =
                                                        (item['quantity']
                                                                as num)
                                                            .toInt();
                                                    final discountPercent =
                                                        ((item['discount_percent'] ??
                                                                0) as num)
                                                            .toDouble();
                                                    final itemTotal = price *
                                                        (1 -
                                                            (discountPercent
                                                                    .clamp(0,
                                                                        100) /
                                                                100)) *
                                                        quantity;
                                                    invoiceSubtotal +=
                                                        itemTotal;
                                                  }

                                                  setState(() {
                                                    _lastInvoiceItems = _cart
                                                        .map((e) => Map<String,
                                                            Object?>.from(e))
                                                        .toList();
                                                    _lastType = _type;
                                                    _lastInvoiceId =
                                                        saleId; // حفظ رقم الفاتورة

                                                    // Save customer info for last invoice
                                                    _lastDueDate = _dueDate;
                                                    _lastCustomerName =
                                                        _customerName;
                                                    _lastCustomerPhone =
                                                        _customerPhone;
                                                    _lastCustomerAddress =
                                                        _customerAddress;

                                                    // Save coupon info for invoice
                                                    _lastCouponDiscount =
                                                        _couponDiscount > 0
                                                            ? _couponDiscount
                                                            : null;
                                                    _lastSubtotal =
                                                        invoiceSubtotal;

                                                    // Don't clear cart or customer fields here - they will be cleared when dialog is closed
                                                  });

                                                  // Success message no longer needed as we show detailed dialog

                                                  // Show success dialog with invoice details in center of screen
                                                  showDialog(
                                                    context: context,
                                                    barrierDismissible: false,
                                                    builder:
                                                        (BuildContext context) {
                                                      return StatefulBuilder(
                                                        builder: (context,
                                                            setDialogState) {
                                                          final totalAmount =
                                                              _lastInvoiceItems
                                                                  .fold<num>(
                                                            0,
                                                            (sum, item) =>
                                                                sum +
                                                                ((item['price']
                                                                        as num) *
                                                                    (item['quantity']
                                                                        as num)),
                                                          );

                                                          return Dialog(
                                                            backgroundColor:
                                                                DarkModeUtils
                                                                    .getCardColor(
                                                                        context),
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          20),
                                                            ),
                                                            child: Container(
                                                              constraints:
                                                                  const BoxConstraints(
                                                                      maxWidth:
                                                                          500,
                                                                      maxHeight:
                                                                          600),
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  // Header
                                                                  Container(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            20),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: Theme.of(context).brightness ==
                                                                              Brightness.dark
                                                                          ? DarkModeUtils.getCardColor(context)
                                                                          : (_lastType == 'credit'
                                                                              ? DarkModeUtils.getWarningColor(context)
                                                                              : _lastType == 'installment'
                                                                                  ? DarkModeUtils.getInfoColor(context)
                                                                                  : DarkModeUtils.getSuccessColor(context)),
                                                                      borderRadius:
                                                                          const BorderRadius
                                                                              .only(
                                                                        topLeft:
                                                                            Radius.circular(20),
                                                                        topRight:
                                                                            Radius.circular(20),
                                                                      ),
                                                                    ),
                                                                    child: Row(
                                                                      children: [
                                                                        Icon(
                                                                          Icons
                                                                              .check_circle,
                                                                          color: Theme.of(context).brightness == Brightness.dark
                                                                              ? (_lastType == 'credit'
                                                                                  ? DarkModeUtils.getWarningColor(context)
                                                                                  : _lastType == 'installment'
                                                                                      ? DarkModeUtils.getInfoColor(context)
                                                                                      : DarkModeUtils.getSuccessColor(context))
                                                                              : Colors.white,
                                                                          size:
                                                                              32,
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                12),
                                                                        Expanded(
                                                                          child:
                                                                              Column(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.start,
                                                                            children: [
                                                                              Text(
                                                                                'تم إنجاز البيع بنجاح',
                                                                                style: TextStyle(
                                                                                  color: Theme.of(context).brightness == Brightness.dark ? DarkModeUtils.getTextColor(context) : Colors.white,
                                                                                  fontSize: 20,
                                                                                  fontWeight: FontWeight.bold,
                                                                                ),
                                                                              ),
                                                                              Text(
                                                                                _lastType == 'credit'
                                                                                    ? 'بيع آجل'
                                                                                    : _lastType == 'installment'
                                                                                        ? 'بيع بالتقسيط'
                                                                                        : 'بيع نقدي',
                                                                                style: TextStyle(
                                                                                  color: Theme.of(context).brightness == Brightness.dark ? DarkModeUtils.getSecondaryTextColor(context) : Colors.white.withOpacity(0.9),
                                                                                  fontSize: 14,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                        Container(
                                                                          padding: const EdgeInsets
                                                                              .symmetric(
                                                                              horizontal: 12,
                                                                              vertical: 6),
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color: Theme.of(context).brightness == Brightness.dark
                                                                                ? (_lastType == 'credit'
                                                                                    ? DarkModeUtils.getWarningColor(context).withOpacity(0.15)
                                                                                    : _lastType == 'installment'
                                                                                        ? DarkModeUtils.getInfoColor(context).withOpacity(0.15)
                                                                                        : DarkModeUtils.getSuccessColor(context).withOpacity(0.15))
                                                                                : Colors.white.withOpacity(0.2),
                                                                            borderRadius:
                                                                                BorderRadius.circular(12),
                                                                          ),
                                                                          child:
                                                                              Text(
                                                                            Formatters.currencyIQD(totalAmount),
                                                                            style:
                                                                                TextStyle(
                                                                              color: Theme.of(context).brightness == Brightness.dark ? DarkModeUtils.getTextColor(context) : Colors.white,
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 16,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),

                                                                  // Items List
                                                                  Flexible(
                                                                    child:
                                                                        Container(
                                                                      padding: const EdgeInsets
                                                                          .all(
                                                                          16),
                                                                      child:
                                                                          Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Row(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.spaceBetween,
                                                                            children: [
                                                                              Text(
                                                                                'المنتجات (${_lastInvoiceItems.length})',
                                                                                style: TextStyle(
                                                                                  fontWeight: FontWeight.bold,
                                                                                  fontSize: 16,
                                                                                  color: _lastType == 'credit'
                                                                                      ? DarkModeUtils.getWarningColor(context)
                                                                                      : _lastType == 'installment'
                                                                                          ? DarkModeUtils.getInfoColor(context)
                                                                                          : DarkModeUtils.getSuccessColor(context),
                                                                                ),
                                                                              ),
                                                                              if (_lastType == 'credit' && _lastDueDate != null)
                                                                                Container(
                                                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                                                  decoration: BoxDecoration(
                                                                                    color: DarkModeUtils.getWarningColor(context).withOpacity(0.15),
                                                                                    borderRadius: BorderRadius.circular(8),
                                                                                  ),
                                                                                  child: Text(
                                                                                    'تاريخ الاستحقاق: ${_lastDueDate!.day}/${_lastDueDate!.month}/${_lastDueDate!.year}',
                                                                                    style: TextStyle(
                                                                                      fontSize: 10,
                                                                                      color: Colors.orange.shade700,
                                                                                      fontWeight: FontWeight.w600,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                            ],
                                                                          ),
                                                                          const SizedBox(
                                                                              height: 12),
                                                                          Flexible(
                                                                            child:
                                                                                ListView.builder(
                                                                              shrinkWrap: true,
                                                                              itemCount: _lastInvoiceItems.length,
                                                                              itemBuilder: (context, index) {
                                                                                final item = _lastInvoiceItems[index];
                                                                                return Container(
                                                                                  margin: const EdgeInsets.only(bottom: 8),
                                                                                  padding: const EdgeInsets.all(12),
                                                                                  decoration: BoxDecoration(
                                                                                    color: DarkModeUtils.getBackgroundColor(context),
                                                                                    borderRadius: BorderRadius.circular(8),
                                                                                    border: Border.all(
                                                                                      color: (_lastType == 'credit'
                                                                                              ? DarkModeUtils.getWarningColor(context)
                                                                                              : _lastType == 'installment'
                                                                                                  ? DarkModeUtils.getInfoColor(context)
                                                                                                  : DarkModeUtils.getSuccessColor(context))
                                                                                          .withOpacity(0.35),
                                                                                    ),
                                                                                  ),
                                                                                  child: Row(
                                                                                    children: [
                                                                                      Expanded(
                                                                                        child: Text(
                                                                                          item['name']?.toString() ?? '',
                                                                                          style: const TextStyle(
                                                                                            fontWeight: FontWeight.w600,
                                                                                            fontSize: 14,
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                      Text(
                                                                                        '${item['quantity']} × ${Formatters.currencyIQD(item['price'] as num)}',
                                                                                        style: TextStyle(
                                                                                          fontWeight: FontWeight.w600,
                                                                                          fontSize: 12,
                                                                                          color: _lastType == 'credit'
                                                                                              ? Colors.orange.shade700
                                                                                              : _lastType == 'installment'
                                                                                                  ? Colors.blue.shade700
                                                                                                  : Colors.green.shade700,
                                                                                        ),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                );
                                                                              },
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),

                                                                  // Customer Information Section
                                                                  if (_lastCustomerName
                                                                      .isNotEmpty) ...[
                                                                    Container(
                                                                      margin: const EdgeInsets
                                                                          .symmetric(
                                                                          horizontal:
                                                                              16),
                                                                      padding:
                                                                          const EdgeInsets
                                                                              .all(
                                                                              6),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: _lastType ==
                                                                                'credit'
                                                                            ? Colors.orange.shade50
                                                                            : _lastType == 'installment'
                                                                                ? Colors.blue.shade50
                                                                                : Colors.green.shade50,
                                                                        borderRadius:
                                                                            BorderRadius.circular(6),
                                                                        border:
                                                                            Border.all(
                                                                          color: _lastType == 'credit'
                                                                              ? Colors.orange.shade200
                                                                              : _lastType == 'installment'
                                                                                  ? Colors.blue.shade200
                                                                                  : Colors.green.shade200,
                                                                          width:
                                                                              1,
                                                                        ),
                                                                      ),
                                                                      child:
                                                                          Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          Row(
                                                                            children: [
                                                                              Icon(
                                                                                Icons.person,
                                                                                color: _lastType == 'credit'
                                                                                    ? Colors.orange.shade700
                                                                                    : _lastType == 'installment'
                                                                                        ? Colors.blue.shade700
                                                                                        : Colors.green.shade700,
                                                                                size: 14,
                                                                              ),
                                                                              const SizedBox(width: 4),
                                                                              Text(
                                                                                'معلومات العميل',
                                                                                style: TextStyle(
                                                                                  fontWeight: FontWeight.bold,
                                                                                  fontSize: 10,
                                                                                  color: _lastType == 'credit'
                                                                                      ? Colors.orange.shade700
                                                                                      : _lastType == 'installment'
                                                                                          ? Colors.blue.shade700
                                                                                          : Colors.green.shade700,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          const SizedBox(
                                                                              height: 6),
                                                                          if (_lastCustomerName
                                                                              .isNotEmpty) ...[
                                                                            _buildCustomerInfoRow('الاسم',
                                                                                _lastCustomerName),
                                                                            const SizedBox(height: 4),
                                                                          ],
                                                                          if (_lastCustomerPhone
                                                                              .isNotEmpty) ...[
                                                                            _buildCustomerInfoRow('الهاتف',
                                                                                _lastCustomerPhone),
                                                                            const SizedBox(height: 4),
                                                                          ],
                                                                          if (_lastCustomerAddress
                                                                              .isNotEmpty) ...[
                                                                            _buildCustomerInfoRow('العنوان',
                                                                                _lastCustomerAddress),
                                                                            const SizedBox(height: 4),
                                                                          ],
                                                                          if (_lastType == 'credit' &&
                                                                              _lastDueDate != null) ...[
                                                                            _buildCustomerInfoRow('تاريخ الاستحقاق',
                                                                                '${_lastDueDate!.day}/${_lastDueDate!.month}/${_lastDueDate!.year}'),
                                                                          ],
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        height:
                                                                            6),
                                                                  ],

                                                                  // Actions - Simplified and organized buttons
                                                                  Container(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            20),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: DarkModeUtils
                                                                          .getSurfaceColor(
                                                                              context),
                                                                      borderRadius:
                                                                          const BorderRadius
                                                                              .only(
                                                                        bottomLeft:
                                                                            Radius.circular(20),
                                                                        bottomRight:
                                                                            Radius.circular(20),
                                                                      ),
                                                                    ),
                                                                    child:
                                                                        Column(
                                                                      children: [
                                                                        // Primary action buttons row
                                                                        Row(
                                                                          children: [
                                                                            // زر اختيار خيارات الطباعة
                                                                            Expanded(
                                                                              child: ElevatedButton.icon(
                                                                                onPressed: () async {
                                                                                  // عرض حوار خيارات الطباعة المتقدم
                                                                                  final result = await PrintService.showPrintOptionsDialog(context);
                                                                                  if (result != null) {
                                                                                    setDialogState(() {
                                                                                      _selectedPrintType = result['pageFormat'] as String;
                                                                                    });
                                                                                    if (context.mounted) {
                                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                                        SnackBar(
                                                                                          content: Text('تم تحديث إعدادات الطباعة'),
                                                                                          backgroundColor: Color(0xFF1976D2), // Professional Blue
                                                                                          duration: const Duration(seconds: 2),
                                                                                          width: 300,
                                                                                          behavior: SnackBarBehavior.floating,
                                                                                        ),
                                                                                      );
                                                                                    }
                                                                                  }
                                                                                },
                                                                                icon: const Icon(Icons.settings, size: 20),
                                                                                label: const Text(
                                                                                  'اختر نوع طباعة',
                                                                                  style: TextStyle(
                                                                                    fontSize: 12,
                                                                                    fontWeight: FontWeight.w600,
                                                                                  ),
                                                                                ),
                                                                                style: ElevatedButton.styleFrom(
                                                                                  backgroundColor: DarkModeUtils.getInfoColor(context),
                                                                                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                                                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                                                                  shape: RoundedRectangleBorder(
                                                                                    borderRadius: BorderRadius.circular(12),
                                                                                  ),
                                                                                  elevation: 2,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            const SizedBox(width: 8),
                                                                            // زر طباعة فقط
                                                                            Expanded(
                                                                              child: ElevatedButton.icon(
                                                                                onPressed: () async {
                                                                                  try {
                                                                                    // طباعة بالإعدادات المختارة
                                                                                    await _printInvoice(context);

                                                                                    if (context.mounted) {
                                                                                      // عرض رسالة النجاح
                                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                                        SnackBar(
                                                                                          content: Text('تم طباعة الفاتورة بنجاح'),
                                                                                          backgroundColor: Color(0xFF059669), // Professional Green
                                                                                          duration: Duration(seconds: 2),
                                                                                          width: 300,
                                                                                          behavior: SnackBarBehavior.floating,
                                                                                        ),
                                                                                      );
                                                                                    }
                                                                                  } catch (e) {
                                                                                    if (context.mounted) {
                                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                                        SnackBar(
                                                                                          content: Text('خطأ في الطباعة'),
                                                                                          backgroundColor: Color(0xFFDC2626), // Professional Red
                                                                                          duration: const Duration(seconds: 3),
                                                                                          width: 300,
                                                                                          behavior: SnackBarBehavior.floating,
                                                                                        ),
                                                                                      );
                                                                                    }
                                                                                  }
                                                                                },
                                                                                icon: const Icon(Icons.print, size: 20),
                                                                                label: const Text('طباعة'),
                                                                                style: ElevatedButton.styleFrom(
                                                                                  backgroundColor: _lastType == 'credit'
                                                                                      ? DarkModeUtils.getWarningColor(context)
                                                                                      : _lastType == 'installment'
                                                                                          ? DarkModeUtils.getInfoColor(context)
                                                                                          : DarkModeUtils.getSuccessColor(context),
                                                                                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                                                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                                                                  shape: RoundedRectangleBorder(
                                                                                    borderRadius: BorderRadius.circular(12),
                                                                                  ),
                                                                                  elevation: 2,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            const SizedBox(width: 8),
                                                                            // زر موافق
                                                                            Expanded(
                                                                              child: ElevatedButton.icon(
                                                                                onPressed: () async {
                                                                                  if (context.mounted) {
                                                                                    // Clear everything when closing dialog
                                                                                    setState(() {
                                                                                      // Clear cart
                                                                                      _cart.clear();
                                                                                      _addedToCartProducts.clear();
                                                                                      // Clear customer fields
                                                                                      _customerName = '';
                                                                                      _customerPhone = '';
                                                                                      _customerAddress = '';
                                                                                      _dueDate = null;
                                                                                      // Clear controllers
                                                                                      _customerNameController.clear();
                                                                                      _customerPhoneController.clear();
                                                                                      _customerAddressController.clear();
                                                                                    });

                                                                                    // إغلاق الحوار
                                                                                    Navigator.of(context).pop();

                                                                                    // عرض رسالة النجاح
                                                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                                                      SnackBar(
                                                                                        content: Text('تم البيع بنجاح'),
                                                                                        backgroundColor: Color(0xFF059669), // Professional Green
                                                                                        duration: Duration(seconds: 2),
                                                                                        width: 300,
                                                                                        behavior: SnackBarBehavior.floating,
                                                                                      ),
                                                                                    );
                                                                                  }
                                                                                },
                                                                                icon: const Icon(Icons.check, size: 20),
                                                                                label: const Text('تأكيد البيع'),
                                                                                style: ElevatedButton.styleFrom(
                                                                                  backgroundColor: Color(0xFF7C3AED), // Professional Purple
                                                                                  foregroundColor: Colors.white,
                                                                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                                                                  shape: RoundedRectangleBorder(
                                                                                    borderRadius: BorderRadius.circular(12),
                                                                                  ),
                                                                                  elevation: 2,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),

                                                                        const SizedBox(
                                                                            height:
                                                                                12),

                                                                        // Back to cart button (full width)
                                                                        SizedBox(
                                                                          width:
                                                                              double.infinity,
                                                                          child:
                                                                              ElevatedButton.icon(
                                                                            onPressed:
                                                                                () {
                                                                              // Return to cart for adding more products
                                                                              setDialogState(() {
                                                                                // Move last invoice items back to cart
                                                                                _cart.clear();
                                                                                _addedToCartProducts.clear();

                                                                                // Add last invoice items back to cart
                                                                                for (final item in _lastInvoiceItems) {
                                                                                  _cart.add(Map<String, Object?>.from(item));
                                                                                  _addedToCartProducts.add(item['product_id'] as int);
                                                                                }

                                                                                // Clear last invoice items
                                                                                _lastInvoiceItems.clear();
                                                                                _lastInvoiceId = null;
                                                                              });

                                                                              // Close the dialog
                                                                              Navigator.of(context).pop();

                                                                              // Show success message
                                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                                SnackBar(
                                                                                  content: Text('تم العودة إلى السلة'),
                                                                                  backgroundColor: Color(0xFF1976D2), // Professional Blue
                                                                                  duration: Duration(seconds: 3),
                                                                                  width: 300,
                                                                                  behavior: SnackBarBehavior.floating,
                                                                                ),
                                                                              );
                                                                            },
                                                                            icon:
                                                                                const Icon(Icons.shopping_cart, size: 20),
                                                                            label:
                                                                                const Text('العودة إلى السلة'),
                                                                            style:
                                                                                ElevatedButton.styleFrom(
                                                                              backgroundColor: Color(0xFFF59E0B), // Professional Orange
                                                                              foregroundColor: Colors.white,
                                                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                                                              shape: RoundedRectangleBorder(
                                                                                borderRadius: BorderRadius.circular(12),
                                                                              ),
                                                                              elevation: 2,
                                                                            ),
                                                                          ),
                                                                        ),

                                                                        const SizedBox(
                                                                            height:
                                                                                8),

                                                                        // Cancel order button (full width)
                                                                        SizedBox(
                                                                          width:
                                                                              double.infinity,
                                                                          child:
                                                                              OutlinedButton.icon(
                                                                            onPressed:
                                                                                () async {
                                                                              // Show confirmation dialog
                                                                              final shouldCancel = await showDialog<bool>(
                                                                                context: context,
                                                                                builder: (BuildContext context) {
                                                                                  return AlertDialog(
                                                                                    shape: RoundedRectangleBorder(
                                                                                      borderRadius: BorderRadius.circular(16),
                                                                                    ),
                                                                                    title: Row(
                                                                                      children: [
                                                                                        Icon(
                                                                                          Icons.warning_amber_rounded,
                                                                                          color: Colors.red.shade600,
                                                                                          size: 28,
                                                                                        ),
                                                                                        const SizedBox(width: 12),
                                                                                        const Text(
                                                                                          'إلغاء العملية بالكامل',
                                                                                          style: TextStyle(
                                                                                            fontSize: 18,
                                                                                            fontWeight: FontWeight.bold,
                                                                                          ),
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                    content: const Text(
                                                                                      'هل أنت متأكد من إلغاء العملية بالكامل؟\nسيتم:\n• إرجاع جميع المنتجات إلى المخزن\n• مسح السلة\n• إلغاء جميع البيانات',
                                                                                      style: TextStyle(fontSize: 16),
                                                                                      textAlign: TextAlign.center,
                                                                                    ),
                                                                                    actions: [
                                                                                      Row(
                                                                                        children: [
                                                                                          Expanded(
                                                                                            child: OutlinedButton(
                                                                                              onPressed: () {
                                                                                                Navigator.of(context).pop(false);
                                                                                              },
                                                                                              style: OutlinedButton.styleFrom(
                                                                                                foregroundColor: Colors.grey.shade600,
                                                                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                                                                side: BorderSide(color: Colors.grey.shade400),
                                                                                                shape: RoundedRectangleBorder(
                                                                                                  borderRadius: BorderRadius.circular(8),
                                                                                                ),
                                                                                              ),
                                                                                              child: const Text('لا'),
                                                                                            ),
                                                                                          ),
                                                                                          const SizedBox(width: 12),
                                                                                          Expanded(
                                                                                            child: ElevatedButton(
                                                                                              onPressed: () {
                                                                                                Navigator.of(context).pop(true);
                                                                                              },
                                                                                              style: ElevatedButton.styleFrom(
                                                                                                backgroundColor: Color(0xFFDC2626), // Professional Red
                                                                                                foregroundColor: Colors.white,
                                                                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                                                                shape: RoundedRectangleBorder(
                                                                                                  borderRadius: BorderRadius.circular(8),
                                                                                                ),
                                                                                              ),
                                                                                              child: const Text('نعم، ألغِ الكل'),
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                    ],
                                                                                  );
                                                                                },
                                                                              );

                                                                              if (shouldCancel == true) {
                                                                                // Cancel the entire sale process
                                                                                try {
                                                                                  // Return products to stock - only from last invoice if it exists
                                                                                  // If there's a last invoice, return those products
                                                                                  // If no last invoice, return products from current cart

                                                                                  if (_lastInvoiceItems.isNotEmpty) {
                                                                                    // Return products from last invoice to stock
                                                                                    for (final item in _lastInvoiceItems) {
                                                                                      final productId = item['product_id'] as int;
                                                                                      final quantity = item['quantity'] as int;
                                                                                      await context.read<DatabaseService>().adjustProductQuantity(productId, quantity);
                                                                                    }
                                                                                  } else if (_cart.isNotEmpty) {
                                                                                    // Return products from current cart to stock (if no last invoice)
                                                                                    for (final item in _cart) {
                                                                                      final productId = item['product_id'] as int;
                                                                                      final quantity = item['quantity'] as int;
                                                                                      await context.read<DatabaseService>().adjustProductQuantity(productId, quantity);
                                                                                    }
                                                                                  }

                                                                                  // Clear everything - complete reset
                                                                                  setState(() {
                                                                                    // Clear cart
                                                                                    _cart.clear();
                                                                                    _addedToCartProducts.clear();

                                                                                    // Clear last invoice items
                                                                                    _lastInvoiceItems.clear();
                                                                                    _lastInvoiceId = null;

                                                                                    // Reset payment type
                                                                                    _lastType = 'cash';
                                                                                    _type = 'cash';

                                                                                    // Clear due date
                                                                                    _lastDueDate = null;
                                                                                    _dueDate = null;

                                                                                    // Clear customer information
                                                                                    _lastCustomerName = '';
                                                                                    _lastCustomerPhone = '';
                                                                                    _lastCustomerAddress = '';
                                                                                    _customerName = '';
                                                                                    _customerPhone = '';
                                                                                    _customerAddress = '';

                                                                                    // Clear controllers
                                                                                    _customerNameController.clear();
                                                                                    _customerPhoneController.clear();
                                                                                    _customerAddressController.clear();

                                                                                    // Clear installment info
                                                                                    _installmentCount = null;
                                                                                    _downPayment = null;
                                                                                    _firstInstallmentDate = null;
                                                                                  });

                                                                                  Navigator.of(context).pop(); // Close the success dialog

                                                                                  // Show success message
                                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                                    SnackBar(
                                                                                      content: Text('تم إلغاء العملية وإرجاع المنتجات'),
                                                                                      backgroundColor: Color(0xFF059669), // Professional Green
                                                                                      duration: Duration(seconds: 3),
                                                                                      width: 300,
                                                                                      behavior: SnackBarBehavior.floating,
                                                                                    ),
                                                                                  );
                                                                                } catch (e) {
                                                                                  Navigator.of(context).pop(); // Close the success dialog
                                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                                    SnackBar(
                                                                                      content: Text('خطأ في إلغاء العملية'),
                                                                                      backgroundColor: Color(0xFFDC2626), // Professional Red
                                                                                      duration: Duration(seconds: 3),
                                                                                      width: 300,
                                                                                      behavior: SnackBarBehavior.floating,
                                                                                    ),
                                                                                  );
                                                                                }
                                                                              }
                                                                            },
                                                                            icon:
                                                                                const Icon(Icons.cancel_outlined, size: 20),
                                                                            label:
                                                                                const Text('إلغاء الطلب'),
                                                                            style:
                                                                                OutlinedButton.styleFrom(
                                                                              foregroundColor: Colors.red.shade600,
                                                                              padding: const EdgeInsets.symmetric(vertical: 12),
                                                                              side: BorderSide(color: Colors.red.shade300),
                                                                              shape: RoundedRectangleBorder(
                                                                                borderRadius: BorderRadius.circular(12),
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    },
                                                  );
                                                },
                                          icon: const Icon(Icons.check_circle),
                                          label: const Text('إتمام البيع'),
                                          style: FilledButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                            backgroundColor:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .primaryContainer
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                            foregroundColor:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .onPrimaryContainer
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .onPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Last Invoice Display - Removed to show in center dialog instead
                            if (false && _lastInvoiceItems.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: _lastType == 'credit'
                                        ? [
                                            Colors.orange.shade50,
                                            Colors.orange.shade100
                                                .withOpacity(0.3)
                                          ]
                                        : _lastType == 'installment'
                                            ? [
                                                Colors.blue.shade50,
                                                Colors.blue.shade100
                                                    .withOpacity(0.3)
                                              ]
                                            : [
                                                Colors.green.shade50,
                                                Colors.green.shade100
                                                    .withOpacity(0.3)
                                              ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _lastType == 'credit'
                                        ? Colors.orange.shade200
                                        : _lastType == 'installment'
                                            ? Colors.blue.shade200
                                            : Colors.green.shade200,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_lastType == 'credit'
                                              ? Colors.orange
                                              : _lastType == 'installment'
                                                  ? Colors.blue
                                                  : Colors.green)
                                          .withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Header
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: _lastType == 'credit'
                                              ? [
                                                  Colors.orange.shade600,
                                                  Colors.orange.shade700
                                                ]
                                              : _lastType == 'installment'
                                                  ? [
                                                      Colors.blue.shade600,
                                                      Colors.blue.shade700
                                                    ]
                                                  : [
                                                      Colors.green.shade600,
                                                      Colors.green.shade700
                                                    ],
                                        ),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(18),
                                          topRight: Radius.circular(18),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Icon(
                                              _lastType == 'credit'
                                                  ? Icons.schedule
                                                  : _lastType == 'installment'
                                                      ? Icons.credit_card
                                                      : Icons.money,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'آخر فاتورة',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  _lastType == 'credit'
                                                      ? 'بيع بالأجل'
                                                      : _lastType ==
                                                              'installment'
                                                          ? 'بيع بالأقساط'
                                                          : 'بيع نقدي',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.9),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              Formatters.currencyIQD(
                                                _lastInvoiceItems.fold<num>(
                                                  0,
                                                  (sum, item) =>
                                                      sum +
                                                      ((item['price'] as num) *
                                                          (item['quantity']
                                                              as num)),
                                                ),
                                              ),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Content
                                    Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Credit information display
                                          if (_lastType == 'credit' &&
                                              _lastCustomerName.isNotEmpty) ...[
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                    color:
                                                        Colors.orange.shade200),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.person,
                                                        color: Colors
                                                            .orange.shade600,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'معلومات العميل',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors
                                                              .orange.shade700,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Wrap(
                                                    spacing: 12,
                                                    runSpacing: 8,
                                                    children: [
                                                      _buildInfoChip(
                                                          'الاسم',
                                                          _lastCustomerName,
                                                          Icons.person),
                                                      _buildInfoChip(
                                                          'الهاتف',
                                                          _lastCustomerPhone,
                                                          Icons.phone),
                                                      _buildInfoChip(
                                                          'العنوان',
                                                          _lastCustomerAddress,
                                                          Icons.location_on),
                                                      _buildInfoChip(
                                                          'تاريخ الاستحقاق',
                                                          '${_lastDueDate?.day}/${_lastDueDate?.month}/${_lastDueDate?.year}',
                                                          Icons.calendar_today),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.security,
                                                        color: Colors
                                                            .orange.shade600,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        'معلومات الضامن',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors
                                                              .orange.shade700,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Wrap(
                                                    spacing: 12,
                                                    runSpacing: 8,
                                                    children: [
                                                      _buildInfoChip(
                                                          'تاريخ الاستحقاق',
                                                          _lastDueDate != null
                                                              ? '${_lastDueDate!.day}/${_lastDueDate!.month}/${_lastDueDate!.year}'
                                                              : '—',
                                                          Icons.event),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                          ],

                                          // Invoice items summary
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.inventory,
                                                color: _lastType == 'credit'
                                                    ? Colors.orange.shade600
                                                    : _lastType == 'installment'
                                                        ? Colors.blue.shade600
                                                        : Colors.green.shade600,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'المنتجات:',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: _lastType == 'credit'
                                                      ? Colors.orange.shade700
                                                      : _lastType ==
                                                              'installment'
                                                          ? Colors.blue.shade700
                                                          : Colors
                                                              .green.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          ..._lastInvoiceItems.map((item) =>
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                margin: const EdgeInsets.only(
                                                    bottom: 8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: _lastType == 'credit'
                                                        ? Colors.orange.shade100
                                                        : _lastType ==
                                                                'installment'
                                                            ? Colors
                                                                .blue.shade100
                                                            : Colors
                                                                .green.shade100,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        item['name']
                                                                ?.toString() ??
                                                            '',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: _lastType ==
                                                                'credit'
                                                            ? Colors
                                                                .orange.shade100
                                                            : _lastType ==
                                                                    'installment'
                                                                ? Colors.blue
                                                                    .shade100
                                                                : Colors.green
                                                                    .shade100,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .end,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            '${item['quantity']} × ${Formatters.currencyIQD(item['price'] as num)}',
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontSize: 12,
                                                              color: _lastType ==
                                                                      'credit'
                                                                  ? Colors
                                                                      .orange
                                                                      .shade700
                                                                  : _lastType ==
                                                                          'installment'
                                                                      ? Colors
                                                                          .blue
                                                                          .shade700
                                                                      : Colors
                                                                          .green
                                                                          .shade700,
                                                            ),
                                                          ),
                                                          // Code/Barcode in Invoice
                                                          if (item['barcode']
                                                                  ?.toString()
                                                                  .isNotEmpty ==
                                                              true)
                                                            Text(
                                                              'باركود: ${item['barcode']}',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                color: Colors
                                                                    .purple
                                                                    .shade600,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  String _shortBarcode(String input,
      {int head = 6, int tail = 4, int min = 14}) {
    if (input.isEmpty) return input;
    if (input.length <= min) return input;
    if (head + tail + 1 >= input.length) return input;
    return '${input.substring(0, head)}…${input.substring(input.length - tail)}';
  }

  Future<void> _addToCart(Map<String, Object?> p) async {
    // Check if product is already in cart
    final existing = _cart.indexWhere((e) => e['product_id'] == p['id']);
    if (existing >= 0) {
      // Product already in cart, don't add again
      // User can adjust quantity using +/- buttons in cart
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('المنتج موجود في السلة'),
          width: 300,
          behavior: SnackBarBehavior.floating));
      return;
    }

    final currentStock = (p['quantity'] as int? ?? 0);
    if (currentStock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('المنتج غير متوفر'),
          width: 300,
          behavior: SnackBarBehavior.floating));
      return;
    }

    // الحصول على خصم المنتج التلقائي
    double productDiscount = 0.0;
    try {
      final db = context.read<DatabaseService>();
      final discount = await db.getActiveProductDiscount(p['id'] as int);
      if (discount != null) {
        // التحقق من الخصم بالمبلغ أولاً (لأن discount_percent قد يكون 0 عند استخدام مبلغ)
        if (discount['discount_amount'] != null &&
            (discount['discount_amount'] as num).toDouble() > 0) {
          final price = (p['price'] as num).toDouble();
          final discountAmount =
              (discount['discount_amount'] as num).toDouble();
          productDiscount = (discountAmount / price) * 100;
        } else if (discount['discount_percent'] != null &&
            (discount['discount_percent'] as num).toDouble() > 0) {
          productDiscount = (discount['discount_percent'] as num).toDouble();
        }
      }
    } catch (e) {
      // تجاهل خطأ جلب خصم المنتج والاستمرار بدون خصم
    }

    // Reserve one immediately
    context.read<DatabaseService>().adjustProductQuantity(p['id'] as int, -1);
    setState(() {
      _cart.insert(0, {
        'product_id': p['id'],
        'name': p['name'],
        'price': p['price'],
        'cost': p['cost'],
        'quantity': 1,
        'available': currentStock - 1,
        'barcode': p['barcode'],
        'discount_percent': productDiscount,
      });
      _addedToCartProducts.add(p['id'] as int);
    });
  }

  void _incrementQty(int index) {
    final available = (_cart[index]['available'] as int?);
    final current = (_cart[index]['quantity'] as int);
    if (available != null && available <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('لا توجد كمية متاحة')));
      return;
    }
    setState(() {
      _cart[index]['quantity'] = current + 1;
      if (_cart[index]['available'] != null) {
        _cart[index]['available'] = (_cart[index]['available'] as int) - 1;
      }
    });
    // Reserve from stock
    final productId = _cart[index]['product_id'] as int;
    context.read<DatabaseService>().adjustProductQuantity(productId, -1);
  }

  void _decrementQty(int index) {
    final current = (_cart[index]['quantity'] as int);
    if (current <= 1) return;
    setState(() {
      _cart[index]['quantity'] = current - 1;
      if (_cart[index]['available'] != null) {
        _cart[index]['available'] = (_cart[index]['available'] as int) + 1;
      }
    });
    // Return to stock
    final productId = _cart[index]['product_id'] as int;
    context.read<DatabaseService>().adjustProductQuantity(productId, 1);
  }

  Future<void> _showCouponDialog(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.local_offer,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text('إضافة كوبون خصم'),
            ],
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'أدخل كود الكوبون',
              prefixIcon: const Icon(Icons.tag),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  _applyCoupon(controller.text.trim());
                }
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('تطبيق'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyCoupon(String code) async {
    if (code.trim().isEmpty) return;

    try {
      final db = context.read<DatabaseService>();

      // حساب الإجمالي الحالي
      double subtotal = 0.0;
      for (final item in _cart) {
        final price = (item['price'] as num).toDouble();
        final quantity = (item['quantity'] as num).toInt();
        final discountPercent =
            ((item['discount_percent'] ?? 0) as num).toDouble();
        final itemTotal =
            price * (1 - (discountPercent.clamp(0, 100) / 100)) * quantity;
        subtotal += itemTotal;
      }

      // التحقق من صحة الكوبون وتطبيقه
      final result = await db.validateAndApplyCoupon(code.trim(), subtotal);

      setState(() {
        _couponCode = code.trim().toUpperCase();
        _couponId = result['coupon_id'] as int;
        _couponDiscount = (result['discount_amount'] as num).toDouble();
        _appliedCoupon = result['coupon'] as Map<String, Object?>;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'تم تطبيق الكوبون بنجاح! خصم: ${Formatters.currencyIQD(_couponDiscount)}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _printInvoice(BuildContext context) async {
    final store = context.read<StoreConfig>();
    final shopName = store.shopName;
    final phone = store.phone;
    final address = store.address;

    // الحصول على الإعدادات المحفوظة من PrintService
    final savedSettings = PrintService.getSavedSettings();

    // استخدام خدمة الطباعة مع الإعدادات المحفوظة
    final success = await PrintService.printInvoice(
      shopName: shopName,
      phone: phone,
      address: address,
      items: _lastInvoiceItems,
      paymentType: _lastType,
      customerName: _lastCustomerName.isNotEmpty ? _lastCustomerName : null,
      customerPhone: _lastCustomerPhone.isNotEmpty ? _lastCustomerPhone : null,
      customerAddress:
          _lastCustomerAddress.isNotEmpty ? _lastCustomerAddress : null,
      dueDate: _lastDueDate,
      pageFormat:
          savedSettings['pageFormat'] as String, // استخدام الإعدادات المحفوظة
      showLogo: savedSettings['showLogo'] as bool, // إظهار الشعار حسب الإعدادات
      showBarcode:
          savedSettings['showBarcode'] as bool, // إظهار الباركود حسب الإعدادات
      invoiceNumber: _lastInvoiceId?.toString(), // تمرير رقم الفاتورة
      installments: _lastInstallments, // معلومات الأقساط
      totalDebt: _lastTotalDebt, // إجمالي الدين
      downPayment: _lastDownPayment, // المبلغ المقدم
      couponDiscount: _lastCouponDiscount, // خصم الكوبون
      subtotal: _lastSubtotal, // الإجمالي قبل الكوبون
      context: context,
    );

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم طباعة الفاتورة بنجاح'),
          backgroundColor: Color(0xFF059669), // Professional Green
          duration: Duration(seconds: 2),
          width: 300,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {}
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade100,
            Colors.orange.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 8,
              color: _lastType == 'credit'
                  ? Colors.orange.shade700
                  : Colors.blue.shade700,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

// Helper methods for dynamic colors based on payment type (dark/light aware)
  Color _getCustomerInfoBackgroundColor() {
    final scheme = Theme.of(context).colorScheme;
    switch (_type) {
      case 'cash':
        return scheme.tertiaryContainer.withOpacity(0.25);
      case 'installment':
        return scheme.secondaryContainer.withOpacity(0.25);
      case 'credit':
        return scheme.primaryContainer.withOpacity(0.25);
      default:
        return scheme.surface;
    }
  }

  Color _getCustomerInfoBorderColor() {
    final scheme = Theme.of(context).colorScheme;
    switch (_type) {
      case 'cash':
        return scheme.tertiary.withOpacity(0.35);
      case 'installment':
        return scheme.secondary.withOpacity(0.35);
      case 'credit':
        return scheme.primary.withOpacity(0.35);
      default:
        return Theme.of(context).dividerColor.withOpacity(0.4);
    }
  }

  Color _getCustomerInfoShadowColor() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Subtle shadow in light mode; slightly stronger in dark mode
    return Colors.black.withOpacity(isDark ? 0.2 : 0.06);
  }
}
