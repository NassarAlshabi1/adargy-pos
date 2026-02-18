import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:daily/database/customer_database_helper.dart';
import 'package:daily/models/customer.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'details_screen/customer_detail_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  _CustomersScreenState createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final CustomerDatabaseHelper _dbHelper = CustomerDatabaseHelper();
  List<Customer> _customers = [];
  List<Customer> _filteredCustomers = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _currentSort = 'name'; // الفرز الافتراضي
  String _selectedCurrencyFilter = 'الكل';

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchController.addListener(_filterCustomers);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCustomers);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    final customers = await _dbHelper.getCustomers();
    for (var customer in customers) {
      customer.transactions = await _dbHelper.getTransactions(customer.id);
    }
    setState(() {
      _customers = customers;
      _filterCustomers(); // تطبيق الفرز والفلترة
    });
  }

  void _filterCustomers() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      List<Customer> tempCustomers = List.from(_customers);

      // فلترة حسب النص
      if (query.isNotEmpty) {
        tempCustomers = tempCustomers
            .where((customer) =>
                customer.name.toLowerCase().contains(query) ||
                customer.transactions
                    .any((tx) => tx.item.toLowerCase().contains(query)))
            .toList();
      }

      // فلترة حسب العملة
      if (_selectedCurrencyFilter != 'الكل') {
        tempCustomers = tempCustomers.where((customer) {
          return customer.transactions
              .any((tx) => tx.currency == _selectedCurrencyFilter);
        }).toList();
      }

      _filteredCustomers = tempCustomers;
      _applySorting(); // تطبيق الفرز بعد الفلترة
    });
  }

  void _applySorting() {
    switch (_currentSort) {
      case 'name':
        _filteredCustomers.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'newest':
        _filteredCustomers.sort((a, b) {
          final aLatest = a.transactions.isNotEmpty
              ? a.transactions
                  .map((t) => t.date)
                  .reduce((c, d) => c.isAfter(d) ? c : d)
              : DateTime(2000);
          final bLatest = b.transactions.isNotEmpty
              ? b.transactions
                  .map((t) => t.date)
                  .reduce((c, d) => c.isAfter(d) ? c : d)
              : DateTime(2000);
          return bLatest.compareTo(aLatest);
        });
        break;
      case 'currency':
        _filteredCustomers.sort((a, b) {
          final aCurrency = _getMostUsedCurrency(a);
          final bCurrency = _getMostUsedCurrency(b);
          return aCurrency.compareTo(bCurrency);
        });
        break;
      case 'transactions':
        _filteredCustomers.sort(
            (a, b) => b.transactions.length.compareTo(a.transactions.length));
        break;
    }
  }

  void _changeSorting(String sortType) {
    setState(() {
      _currentSort = sortType;
      _applySorting();
    });
  }

  void _changeCurrencyFilter(String currency) {
    setState(() {
      _selectedCurrencyFilter = currency;
      _filterCustomers();
    });
  }

  String _getMostUsedCurrency(Customer customer) {
    if (customer.transactions.isEmpty) return 'غير محدد';
    Map<String, int> currencyCount = {};
    for (var tx in customer.transactions) {
      currencyCount[tx.currency] = (currencyCount[tx.currency] ?? 0) + 1;
    }
    if (currencyCount.isEmpty) return 'غير محدد';
    return currencyCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  List<String> _getAllUsedCurrencies() {
    Set<String> currencies = {};
    for (var customer in _customers) {
      for (var transaction in customer.transactions) {
        currencies.add(transaction.currency);
      }
    }
    List<String> currencyList = currencies.toList();
    currencyList.sort();
    if (currencyList.isEmpty) {
      currencyList = ['الكل'];
    } else {
      currencyList.insert(0, 'الكل');
    }
    return currencyList;
  }

  String _getSortDescription() {
    switch (_currentSort) {
      case 'name':
        return 'مرتب أبجدياً';
      case 'newest':
        return 'مرتب حسب آخر نشاط';
      case 'currency':
        return 'مرتب حسب العملة';
      case 'transactions':
        return 'مرتب حسب الأكثر نشاطاً';
      default:
        return '';
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
      _filterCustomers();
    });
  }

  void _showAddCustomerDialog() {
    final accountNameController = TextEditingController();

    String selectedCurrency = 'YER'; // العملة الافتراضية

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Directionality(
              textDirection: ui.TextDirection.rtl,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Center(
                  child: Text(
                    'إضافة عميل جديد',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: accountNameController,
                        decoration: InputDecoration(
                          labelText: 'اسم الحساب',
                          prefixIcon: Icon(Icons.account_circle,
                              color: Colors.blue.shade800),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // TextField(
                      //   controller: amountController,
                      //   keyboardType: const TextInputType.numberWithOptions(
                      //       decimal: true),
                      //   decoration: InputDecoration(
                      //     labelText: 'المبلغ',
                      //     prefixIcon: const Icon(Icons.attach_money,
                      //         color: Colors.green),
                      //     border: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(12),
                      //     ),
                      //   ),
                      // ),
                      const SizedBox(height: 10),
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'العملة',
                          prefixIcon: Icon(Icons.monetization_on,
                              color: Colors.blue.shade800),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedCurrency,
                            isExpanded: true,
                            items: <String>['YER', 'SAR', 'USD', 'AED']
                                .map((value) => DropdownMenuItem<String>(
                                    value: value, child: Text(value)))
                                .toList(),
                            onChanged: (newValue) {
                              setStateDialog(() {
                                selectedCurrency = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('إلغاء',
                        style: TextStyle(color: Colors.red)),
                  ),
                  TextButton(
                    onPressed: () async {
                      final accountName = accountNameController.text.trim();
                      if (accountName.isEmpty) return;

                      final customer = Customer(
                        id: DateTime.now().millisecondsSinceEpoch,
                        name: accountName,
                        transactions: [],
                        currency: selectedCurrency, // تمرير العملة المختارة
                      );
                      await _dbHelper.insertCustomer(customer);

                      // final amount =
                      //     double.tryParse(amountController.text) ?? 0.0;
                      // if (amount > 0) {
                      //   final initialTransaction = TransactionEntry(
                      //     customerId: customer.id,
                      //     date: DateTime.now(),
                      //     item: 'رصيد افتتاحي',
                      //     amount: amount,
                      //     currency: selectedCurrency,
                      //     isCredit: true, // افتراضياً رصيد دائن
                      //   );
                      //   await _dbHelper.insertTransaction(initialTransaction);
                      // }

                      _loadCustomers();
                      Navigator.pop(context);
                    },
                    child:
                        const Text('حفظ', style: TextStyle(color: Colors.blue)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToCustomerDetail(Customer customer) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CustomerDetailScreen(customer: customer, dbHelper: _dbHelper),
      ),
    );
    _loadCustomers();
  }

  Widget _buildSortButton({
    required String label,
    required IconData icon,
    required String sortType,
    required bool isActive,
    required bool isDark,
    required Color accentColor,
  }) {
    return InkWell(
      onTap: () => _changeSorting(sortType),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? accentColor
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? accentColor
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? Colors.white
                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: isActive
                    ? Colors.white
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyFilter(bool isDark, Color accentColor) {
    final availableCurrencies = _getAllUsedCurrencies();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.monetization_on,
            size: 14,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
          ),
          const SizedBox(width: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCurrencyFilter,
              icon: Icon(
                Icons.arrow_drop_down,
                size: 16,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
              dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
              items: availableCurrencies.map((String currency) {
                return DropdownMenuItem<String>(
                  value: currency,
                  child: Text(
                    currency,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  _changeCurrencyFilter(newValue);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final accentColor = isDark ? Colors.blue.shade300 : Colors.blue.shade600;

    final screenWidth = MediaQuery.of(context).size.width;
    final nameFontSize = screenWidth * 0.045;
    final detailFontSize = screenWidth * 0.035;
    final iconSize = screenWidth * 0.05;
    final spacing = screenWidth * 0.03;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Directionality(
        textDirection: ui.TextDirection.rtl,
        child: SafeArea(
          child: _customers.isEmpty && !_isSearching
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_off_outlined,
                        size: 80,
                        color: isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'لا يوجد عملاء حتى الآن',
                        style: const TextStyle(
                          fontSize: nameFontSize,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showAddCustomerDialog,
                        icon: const Icon(Icons.add),
                        label: Text(
                          'إضافة عميل جديد',
                          style: const TextStyle(),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(spacing),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade900.withOpacity(0.5)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: Colors.grey.shade300,
                              blurRadius: 2,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      margin: EdgeInsets.all(spacing),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isSearching
                                          ? 'نتائج البحث: ${_filteredCustomers.length}'
                                          : 'عدد العملاء: ${_customers.length}',
                                      style: const TextStyle(
                                        fontSize: detailFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                    ),
                                    if (!_isSearching)
                                      Text(
                                        _getSortDescription(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? Colors.grey.shade500
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (!_isSearching)
                                InkWell(
                                  onTap: _showAddCustomerDialog,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: accentColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.person_add,
                                            color: Colors.white, size: 18),
                                        const SizedBox(width: 6),
                                        Text(
                                          'إضافة عميل',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 12),
                              InkWell(
                                onTap: _toggleSearch,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _isSearching
                                        ? accentColor
                                        : (isDark
                                            ? Colors.grey.shade800
                                            : Colors.grey.shade200),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    _isSearching ? Icons.close : Icons.search,
                                    color: _isSearching
                                        ? Colors.white
                                        : accentColor,
                                    size: iconSize,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_isSearching) ...[
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey.shade800
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(
                                    color:
                                        isDark ? Colors.white : Colors.black),
                                decoration: InputDecoration(
                                  hintText: 'ابحث...',
                                  hintStyle: const TextStyle(
                                      color: isDark
                                          ? Colors.grey.shade500
                                          : Colors.grey.shade400),
                                  border: InputBorder.none,
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon:
                                              const Icon(Icons.clear, size: 18),
                                          onPressed: () =>
                                              _searchController.clear(),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(
                          horizontal: spacing, vertical: 8),
                      child: Row(
                        children: [
                          Text(
                            'فرز :',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildSortButton(
                                      label: 'أبجدي',
                                      icon: Icons.sort_by_alpha,
                                      sortType: 'name',
                                      isActive: _currentSort == 'name',
                                      isDark: isDark,
                                      accentColor: accentColor),
                                  const SizedBox(width: 8),
                                  _buildSortButton(
                                      label: 'الأحدث',
                                      icon: Icons.access_time,
                                      sortType: 'newest',
                                      isActive: _currentSort == 'newest',
                                      isDark: isDark,
                                      accentColor: accentColor),
                                  const SizedBox(width: 8),
                                  _buildSortButton(
                                      label: 'الأكثر نشاطاً',
                                      icon: Icons.bar_chart,
                                      sortType: 'transactions',
                                      isActive: _currentSort == 'transactions',
                                      isDark: isDark,
                                      accentColor: accentColor),
                                  const SizedBox(width: 8),
                                  _buildCurrencyFilter(isDark, accentColor),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _filteredCustomers.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 48,
                                    color: isDark
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'لا توجد نتائج مطابقة',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                  spacing, 0, spacing, spacing),
                              itemCount: _filteredCustomers.length,
                              itemBuilder: (context, index) {
                                final customer = _filteredCustomers[index];
                                double runningBalance = customer.transactions
                                    .fold(
                                        0.0,
                                        (sum, t) =>
                                            sum +
                                            (t.isCredit
                                                ? t.amount
                                                : -t.amount));
                                String mostUsedCurrency =
                                    _getMostUsedCurrency(customer);

                                return Card(
                                  elevation: isDark ? 1 : 2,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  color: isDark
                                      ? Colors.grey.shade800
                                      : Colors.white,
                                  child: InkWell(
                                    onTap: () =>
                                        _navigateToCustomerDetail(customer),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  customer.name,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                        Icons
                                                            .receipt_long_outlined,
                                                        size: 14,
                                                        color: Colors
                                                            .grey.shade600),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                        '${customer.transactions.length} عملية',
                                                        style: const TextStyle(fontFamily: 'Arial')),
                                                    const SizedBox(width: 10),
                                                    Icon(
                                                        Icons
                                                            .monetization_on_outlined,
                                                        size: 14,
                                                        color: Colors
                                                            .grey.shade600),
                                                    const SizedBox(width: 4),
                                                    Text(mostUsedCurrency,
                                                        style: const TextStyle(fontFamily: 'Arial')),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  RichText(
                                                    textDirection:
                                                        ui.TextDirection.rtl,
                                                    text: TextSpan(
                                                      children: [
                                                        if (runningBalance < 0)
                                                          TextSpan(
                                                            text: '- ',
                                                            style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                              color: Colors.red,
                                                              fontFamily: 'Arial',
                                                            ),
                                                          ),
                                                        TextSpan(
                                                          text:
                                                              '${runningBalance.abs().toStringAsFixed(0)} ',
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16,
                                                            color:
                                                                runningBalance >= 0
                                                                    ? Colors
                                                                        .green
                                                                    : Colors
                                                                        .red,
                                                          ),
                                                        ),
                                                        TextSpan(
                                                          text:
                                                              '${customer.transactions.isNotEmpty ? customer.transactions.first.currency : ''}',
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16,
                                                            color:
                                                                runningBalance >= 0
                                                                    ? Colors
                                                                        .green
                                                                    : Colors
                                                                        .red,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Text(
                                                    runningBalance >= 0
                                                        ? 'له'
                                                        : 'عليه',
                                                    style: const TextStyle(
                                                        color: Colors
                                                            .grey.shade600),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(width: 10),
                                              IconButton(
                                                icon: const Icon(Icons.check,
                                                    color: Colors.green),
                                                onPressed: () async {
                                                  // التحقق من وجود رصيد للعميل
                                                  if (runningBalance == 0) {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'رصيد العميل صفر - لا يوجد مبلغ للسداد',
                                                          style: const TextStyle(fontFamily: 'Arial'),
                                                        ),
                                                        backgroundColor:
                                                            Colors.orange,
                                                      ),
                                                    );
                                                    return;
                                                  }

                                                  String settlementType =
                                                      runningBalance > 0
                                                          ? 'سداد مبلغ مستحق'
                                                          : 'تسوية رصيد مدين';
                                                  String balanceDescription =
                                                      runningBalance > 0
                                                          ? 'مبلغ ${runningBalance.abs().toStringAsFixed(0)} ${customer.transactions.isNotEmpty ? customer.transactions.first.currency : ''} مستحق للعميل'
                                                          : 'مبلغ ${runningBalance.abs().toStringAsFixed(0)} ${customer.transactions.isNotEmpty ? customer.transactions.first.currency : ''} مستحق على العميل';

                                                  bool confirm =
                                                      await showDialog(
                                                    context: context,
                                                    builder: (context) =>
                                                        AlertDialog(
                                                      title: Text(
                                                        settlementType,
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                      content: Text(
                                                          textDirection: ui
                                                              .TextDirection
                                                              .rtl,
                                                          'هل أنت متأكد من تسوية حساب العميل ${customer.name}؟\n\n$balanceDescription'),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context,
                                                                  false),
                                                          child: const Text(
                                                              'إلغاء'),
                                                        ),
                                                        TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context,
                                                                  true),
                                                          child: Text(
                                                              runningBalance > 0
                                                                  ? 'تأكيد السداد'
                                                                  : 'تأكيد التسوية'),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  if (confirm == true) {
                                                    await _settleCustomerBalance(
                                                        customer,
                                                        runningBalance);
                                                    _loadCustomers();
                                                  }
                                                },
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ).animate().fadeIn(
                                    delay: (index * 50).ms, duration: 300.ms);
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // دالة تسوية رصيد العميل كاملاً
  Future<void> _settleCustomerBalance(Customer customer, double balance) async {
    try {
      String currency = customer.transactions.isNotEmpty
          ? customer.transactions.first.currency
          : 'ر.ي';

      String settlementDescription;
      bool isSettlementCredit;

      if (balance > 0) {
        // العميل له مبلغ مستحق - سداد من المؤسسة للعميل
        settlementDescription = 'سداد كامل للمبلغ المستحق';
        isSettlementCredit = false; // مدين على المؤسسة
      } else {
        // العميل عليه مبلغ - سداد من العميل للمؤسسة
        settlementDescription = 'تسوية كاملة للرصيد المدين';
        isSettlementCredit = true; // دائن للمؤسسة
      }

      // إضافة معاملة تسوية
      final settlementTransaction = TransactionEntry(
        customerId: customer.id,
        date: DateTime.now(),
        item: settlementDescription,
        amount: balance.abs(),
        currency: currency,
        isCredit: isSettlementCredit,
      );

      await _dbHelper.insertTransaction(settlementTransaction);

      // حفظ معلومات السداد في جدول السدادات
      final settlementData = {
        'customerId': customer.id,
        'customerName': customer.name,
        'settledAmount': balance.abs(),
        'currency': currency,
        'settlementDate': DateTime.now().toIso8601String(),
      };

      await _dbHelper.insertSettlement(settlementData);

      // تحديد العميل كمسدد (نقله من العملاء إلى السدادات)
      await _dbHelper.markCustomerAsSettled(customer.id);

      // عرض رسالة تأكيد مناسبة
      String confirmationMessage;
      if (balance > 0) {
        confirmationMessage =
            'تم سداد مبلغ ${balance.abs().toStringAsFixed(0)} $currency للعميل ${customer.name} ونقله إلى السدادات';
      } else {
        confirmationMessage =
            'تمت تسوية مبلغ ${balance.abs().toStringAsFixed(0)} $currency من العميل ${customer.name} ونقله إلى السدادات';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            confirmationMessage,
            style: const TextStyle(),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حدث خطأ أثناء التسوية: $e',
            style: const TextStyle(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
