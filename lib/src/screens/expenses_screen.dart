// ignore_for_file: use_build_context_synchronously

import 'dart:ui' as ui show TextDirection;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/db/database_service.dart';
import '../services/auth/auth_provider.dart';
import '../models/user_model.dart';
import '../utils/format.dart';
import '../utils/dark_mode_utils.dart';
import '../utils/export.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String _query = '';
  String? _selectedCategory;
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedPeriodName;
  int _refreshKey = 0; // مفتاح لإعادة تحميل البيانات
  List<String> _categories = [
    'إيجار',
    'رواتب',
    'كهرباء',
    'ماء',
    'إنترنت',
    'صيانة',
    'تسويق',
    'أخرى',
    'عام'
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final db = context.read<DatabaseService>();
    try {
      final categories = await db.getExpenseCategories();
      if (categories.isNotEmpty) {
        setState(() {
          _categories = [..._categories, ...categories];
          _categories = _categories.toSet().toList();
        });
      }
    } catch (e) {
      // تجاهل الخطأ
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // فحص صلاحية إدارة المصروفات
    if (!auth.hasPermission(UserPermission.viewReports)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المصروفات'),
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
            ],
          ),
        ),
      );
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl, // RTL for Arabic
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.98),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // شريط البحث والفلترة
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // زر إضافة مصروف - في البداية
                        FilledButton.icon(
                          onPressed: () => _openExpenseEditor(),
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: const Text(
                            'إضافة مصروف',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                            elevation: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // حقل البحث
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .shadow
                                      .withOpacity(0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(8),
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.search,
                                    size: 18,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                                ),
                                hintText: 'بحث...',
                                hintStyle: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.4),
                                  fontSize: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.transparent,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                isDense: true,
                              ),
                              onChanged: (v) => setState(() => _query = v),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // أنواع المصروفات
                        Container(
                          width: 130,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .shadow
                                    .withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
                            decoration: InputDecoration(
                              labelText: 'النوع',
                              labelStyle: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              isDense: true,
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('الكل',
                                    style: TextStyle(fontSize: 11)),
                              ),
                              ..._categories.map((cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat,
                                        style: const TextStyle(fontSize: 11)),
                                  )),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedCategory = value);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // زر إدارة الأنواع
                        _FilterButton(
                          icon: Icons.category,
                          label: 'الأنواع',
                          onPressed: () => _showManageCategoriesDialog(),
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        // زر عرض الكل
                        _FilterButton(
                          icon: Icons.all_inclusive,
                          label: 'عرض الكل',
                          onPressed: () {
                            setState(() {
                              _fromDate = null;
                              _toDate = null;
                              _selectedPeriodName = null;
                            });
                          },
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                        const SizedBox(width: 8),
                        // زر الفترات
                        _FilterButton(
                          icon: Icons.date_range,
                          label: _getDateRangeLabel().length > 18
                              ? '${_getDateRangeLabel().substring(0, 18)}...'
                              : _getDateRangeLabel(),
                          onPressed: () => _showDateRangePicker(),
                          color: Theme.of(context).colorScheme.primary,
                          isPrimary: true,
                        ),
                        const SizedBox(width: 8),
                        // زر تصدير PDF
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .error
                                    .withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: () async {
                              await _exportFinancialSummary(context);
                            },
                            tooltip: 'تصدير ملخص PDF',
                            icon: Icon(Icons.picture_as_pdf, size: 20),
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // بطاقات التحليل المالي - تصميم عصري وجذاب
              FutureBuilder<Map<String, double>>(
                key: ValueKey(
                    'profit_loss_${_fromDate?.toIso8601String()}_${_toDate?.toIso8601String()}_$_refreshKey'),
                future: context.read<DatabaseService>().profitAndLoss(
                      from: _fromDate,
                      to: _toDate,
                    ),
                builder: (context, snap) {
                  final data = snap.data ??
                      {'sales': 0, 'profit': 0, 'expenses': 0, 'net': 0};
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.end,
                    children: [
                      _StatCard(
                        title: 'المبيعات',
                        value: Formatters.currencyIQD(data['sales'] ?? 0),
                        color: Colors.blue,
                        icon: Icons.shopping_cart_rounded,
                      ),
                      _StatCard(
                        title: 'الربح الإجمالي',
                        value: Formatters.currencyIQD(data['profit'] ?? 0),
                        color: Colors.green,
                        icon: Icons.trending_up_rounded,
                      ),
                      _StatCard(
                        title: 'المصاريف',
                        value: Formatters.currencyIQD(data['expenses'] ?? 0),
                        color: Colors.orange,
                        icon: Icons.receipt_long_rounded,
                      ),
                      _StatCard(
                        title: 'الربح الصافي',
                        value: Formatters.currencyIQD(data['net'] ?? 0),
                        color:
                            (data['net'] ?? 0) >= 0 ? Colors.teal : Colors.red,
                        icon: (data['net'] ?? 0) >= 0
                            ? Icons.account_balance_wallet_rounded
                            : Icons.warning_rounded,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              // قائمة المصروفات
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  key: ValueKey(
                      'expenses_${_fromDate?.toIso8601String()}_${_toDate?.toIso8601String()}_$_selectedCategory$_refreshKey'),
                  future: context.read<DatabaseService>().getExpenses(
                        from: _fromDate,
                        to: _toDate,
                        category: _selectedCategory,
                      ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('خطأ في تحميل المصروفات: ${snapshot.error}'),
                          ],
                        ),
                      );
                    }

                    final expenses = snapshot.data ?? [];
                    final filteredExpenses = expenses.where((expense) {
                      if (_query.isEmpty) {
                        return true;
                      }
                      final title =
                          expense['title']?.toString().toLowerCase() ?? '';
                      final description =
                          expense['description']?.toString().toLowerCase() ??
                              '';
                      return title.contains(_query.toLowerCase()) ||
                          description.contains(_query.toLowerCase());
                    }).toList();

                    if (filteredExpenses.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long,
                                size: 64,
                                color: DarkModeUtils.getTextColor(context)
                                    .withOpacity(0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'لا توجد مصروفات',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      );
                    }

                    // حساب الإجمالي
                    final total = filteredExpenses.fold<double>(
                      0.0,
                      (sum, expense) =>
                          sum +
                          ((expense['amount'] as num?)?.toDouble() ?? 0.0),
                    );

                    return Column(
                      children: [
                        // بطاقة الإجمالي - تصميم عصري وجذاب
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.receipt_long,
                                      size: 20,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'إجمالي المصروفات',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        Formatters.currencyIQD(total),
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: () async {
                                  await _exportExpensesList(
                                      context, filteredExpenses);
                                },
                                tooltip: 'تصدير PDF',
                                icon: Icon(Icons.picture_as_pdf, size: 20),
                                color: Theme.of(context).colorScheme.primary,
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // قائمة المصروفات
                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredExpenses.length,
                            itemBuilder: (context, index) {
                              final expense = filteredExpenses[index];
                              return _ExpenseCard(
                                expense: expense,
                                onEdit: () =>
                                    _openExpenseEditor(expense: expense),
                                onDelete: () =>
                                    _deleteExpense(expense['id'] as int),
                                canEdit: auth.hasPermission(
                                    UserPermission.manageProducts),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDateRangeLabel() {
    if (_fromDate == null && _toDate == null) {
      return 'الفترة: آخر 30 يوم';
    }

    if (_fromDate != null && _toDate != null) {
      final dateRange =
          '${DateFormat('yyyy-MM-dd').format(_fromDate!)} - ${DateFormat('yyyy-MM-dd').format(_toDate!)}';
      if (_selectedPeriodName != null) {
        return 'الفترة: $dateRange ($_selectedPeriodName)';
      }
      return 'الفترة: $dateRange';
    } else if (_fromDate != null) {
      return 'من ${DateFormat('yyyy-MM-dd').format(_fromDate!)}';
    } else if (_toDate != null) {
      return 'إلى ${DateFormat('yyyy-MM-dd').format(_toDate!)}';
    }
    return 'اختر الفترة';
  }

  String? _determinePeriodName(DateTime start, DateTime end) {
    final now = DateTime.now();

    // التحقق من اليوم
    final todayStart = DateTime(now.year, now.month, now.day);
    if (_isSameDay(start, todayStart) && _isSameDay(end, todayStart)) {
      return 'اليوم';
    }

    // التحقق من الأسبوع (من 7 أيام مضت إلى اليوم)
    final weekStart = now.subtract(const Duration(days: 7));
    if (_isSameDay(start, weekStart) && _isSameDay(end, now)) {
      return 'أسبوع';
    }

    // التحقق من الشهر (من 30 يوم مضى إلى اليوم)
    final monthStart = now.subtract(const Duration(days: 30));
    if (_isSameDay(start, monthStart) && _isSameDay(end, now)) {
      return 'شهر';
    }

    // التحقق من 3 أشهر (من 90 يوم مضى إلى اليوم)
    final threeMonthsStart = now.subtract(const Duration(days: 90));
    if (_isSameDay(start, threeMonthsStart) && _isSameDay(end, now)) {
      return '3 أشهر';
    }

    // التحقق من 6 أشهر (من 180 يوم مضى إلى اليوم)
    final sixMonthsStart = now.subtract(const Duration(days: 180));
    if (_isSameDay(start, sixMonthsStart) && _isSameDay(end, now)) {
      return '6 أشهر';
    }

    // التحقق من السنة (من 365 يوم مضى إلى اليوم)
    final yearStart = now.subtract(const Duration(days: 365));
    if (_isSameDay(start, yearStart) && _isSameDay(end, now)) {
      return 'سنة';
    }

    return null; // فترة مخصصة
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    final initialStart = _fromDate ?? now.subtract(const Duration(days: 30));
    final initialEnd = _toDate ?? now;

    DateTime? startDate = initialStart;
    DateTime? endDate = initialEnd;
    String? selectedQuickButton = _selectedPeriodName;

    final result = await showDialog<DateTimeRange?>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            title: const Text(
              'اختيار الفترة',
              textAlign: TextAlign.right,
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Start Date
                  ListTile(
                    leading:
                        Icon(Icons.calendar_today, color: Colors.blue.shade600),
                    title: const Text('تاريخ البداية'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          startDate.toString().substring(0, 10),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (selectedQuickButton != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'فترة: $selectedQuickButton',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(now.year - 5),
                        lastDate: endDate ?? DateTime(now.year + 1),
                        builder: (context, child) {
                          return Directionality(
                            textDirection: ui.TextDirection.rtl,
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setDialogState(() {
                          startDate = picked;
                          selectedQuickButton =
                              null; // إلغاء الاختيار السريع عند التعديل اليدوي
                        });
                      }
                    },
                  ),
                  const Divider(),
                  // End Date
                  ListTile(
                    leading: Icon(Icons.calendar_today,
                        color: Colors.green.shade600),
                    title: const Text('تاريخ النهاية'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          endDate.toString().substring(0, 10),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (selectedQuickButton != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              'فترة: $selectedQuickButton',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: endDate,
                        firstDate: startDate ?? DateTime(now.year - 5),
                        lastDate: DateTime(now.year + 1),
                        builder: (context, child) {
                          return Directionality(
                            textDirection: ui.TextDirection.rtl,
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setDialogState(() {
                          endDate = picked;
                          selectedQuickButton =
                              null; // إلغاء الاختيار السريع عند التعديل اليدوي
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Quick selection buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _QuickDateButton(
                        label: 'اليوم',
                        isSelected: selectedQuickButton == 'اليوم',
                        onTap: () {
                          setDialogState(() {
                            selectedQuickButton = 'اليوم';
                          });
                        },
                      ),
                      _QuickDateButton(
                        label: 'أسبوع',
                        isSelected: selectedQuickButton == 'أسبوع',
                        onTap: () {
                          setDialogState(() {
                            selectedQuickButton = 'أسبوع';
                          });
                        },
                      ),
                      _QuickDateButton(
                        label: 'شهر',
                        isSelected: selectedQuickButton == 'شهر',
                        onTap: () {
                          setDialogState(() {
                            selectedQuickButton = 'شهر';
                          });
                        },
                      ),
                      _QuickDateButton(
                        label: '3 أشهر',
                        isSelected: selectedQuickButton == '3 أشهر',
                        onTap: () {
                          setDialogState(() {
                            selectedQuickButton = '3 أشهر';
                          });
                        },
                      ),
                      _QuickDateButton(
                        label: '6 أشهر',
                        isSelected: selectedQuickButton == '6 أشهر',
                        onTap: () {
                          setDialogState(() {
                            selectedQuickButton = '6 أشهر';
                          });
                        },
                      ),
                      _QuickDateButton(
                        label: 'سنة',
                        isSelected: selectedQuickButton == 'سنة',
                        onTap: () {
                          setDialogState(() {
                            selectedQuickButton = 'سنة';
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  DateTime finalStart = startDate!;
                  DateTime finalEnd = endDate!;

                  // تطبيق الفترة السريعة المختارة
                  if (selectedQuickButton != null) {
                    final now = DateTime.now();
                    switch (selectedQuickButton) {
                      case 'اليوم':
                        finalStart = DateTime(now.year, now.month, now.day);
                        finalEnd =
                            DateTime(now.year, now.month, now.day, 23, 59, 59);
                        break;
                      case 'أسبوع':
                        finalStart = now.subtract(const Duration(days: 7));
                        finalEnd = now;
                        break;
                      case 'شهر':
                        finalStart = now.subtract(const Duration(days: 30));
                        finalEnd = now;
                        break;
                      case '3 أشهر':
                        finalStart = now.subtract(const Duration(days: 90));
                        finalEnd = now;
                        break;
                      case '6 أشهر':
                        finalStart = now.subtract(const Duration(days: 180));
                        finalEnd = now;
                        break;
                      case 'سنة':
                        finalStart = now.subtract(const Duration(days: 365));
                        finalEnd = now;
                        break;
                    }
                  }

                  Navigator.pop(
                      context, DateTimeRange(start: finalStart, end: finalEnd));
                },
                child: const Text('تطبيق'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _fromDate = result.start;
        _toDate = result.end;
        // تحديد اسم الفترة بناءً على النطاق المحدد
        _selectedPeriodName = _determinePeriodName(result.start, result.end);
      });
    }
  }

  Future<void> _openExpenseEditor({Map<String, dynamic>? expense}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ExpenseEditorDialog(
        expense: expense,
        categories: _categories,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _refreshKey++; // إعادة تحميل البيانات بعد إضافة/تعديل مصروف
      });
    }
  }

  Future<void> _deleteExpense(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا المصروف؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final auth = context.read<AuthProvider>();
        final currentUser = auth.currentUser;
        await context.read<DatabaseService>().deleteExpense(
              id,
              userId: currentUser?.id,
              username: currentUser?.username,
              name: currentUser?.name,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف المصروف بنجاح')),
          );
          setState(() {
            _refreshKey++; // إعادة تحميل البيانات بعد حذف مصروف
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في حذف المصروف: $e')),
          );
        }
      }
    }
  }

  Future<void> _exportFinancialSummary(BuildContext context) async {
    try {
      final db = context.read<DatabaseService>();
      final data = await db.profitAndLoss(from: _fromDate, to: _toDate);
      final periodLabel = _getDateRangeLabel();
      final rows = <List<String>>[
        ['البند', 'القيمة'],
        ['المبيعات', Formatters.currencyIQD(data['sales'] ?? 0)],
        ['الربح الإجمالي', Formatters.currencyIQD(data['profit'] ?? 0)],
        ['المصاريف', Formatters.currencyIQD(data['expenses'] ?? 0)],
        ['الربح الصافي', Formatters.currencyIQD(data['net'] ?? 0)],
      ];
      final saved = await PdfExporter.exportSimpleTable(
        filename: 'expenses_financial_summary.pdf',
        title:
            'ملخص التحليل المالي - المصروفات${periodLabel != 'اختر الفترة' ? ' ($periodLabel)' : ''}',
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
        SnackBar(content: Text('فشل تصدير ملخص التحليل المالي: $e')),
      );
    }
  }

  Future<void> _exportExpensesList(
      BuildContext context, List<Map<String, dynamic>> items) async {
    try {
      final periodLabel = _getDateRangeLabel();
      final headers = ['العنوان', 'النوع', 'المبلغ', 'التاريخ', 'الوصف'];
      final rows = items.map((e) {
        final expenseDate = e['expense_date']?.toString() ?? '';
        String dateStr = '';
        if (expenseDate.isNotEmpty) {
          try {
            final date = DateTime.parse(expenseDate);
            dateStr = DateFormat('yyyy-MM-dd').format(date);
          } catch (_) {
            dateStr = expenseDate.length >= 10
                ? expenseDate.substring(0, 10)
                : expenseDate;
          }
        }
        return [
          (e['title'] ?? '').toString(),
          (e['category'] ?? 'عام').toString(),
          Formatters.currencyIQD((e['amount'] as num?)?.toDouble() ?? 0),
          dateStr,
          (e['description'] ?? '').toString(),
        ];
      }).toList();
      final saved = await PdfExporter.exportDataTable(
        filename: 'expenses_list.pdf',
        title:
            'قائمة المصروفات${periodLabel != 'اختر الفترة' ? ' ($periodLabel)' : ''}',
        headers: headers,
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
        SnackBar(content: Text('فشل تصدير قائمة المصروفات: $e')),
      );
    }
  }

  Future<void> _showManageCategoriesDialog() async {
    final db = context.read<DatabaseService>();

    if (!mounted) return;

    showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
              builder: (context, setDialogState) {
                // استخدام جميع الأنواع من القائمة المحلية
                final categoriesSet = _categories.toSet();
                final allCategories = <String>[];

                // إضافة "عام" في البداية إن وجد
                if (categoriesSet.contains('عام')) {
                  allCategories.add('عام');
                }

                // إضافة باقي الأنواع مرتبة أبجدياً (عدا "عام" و "أخرى")
                final otherCategories = categoriesSet
                    .where((cat) => cat != 'عام' && cat != 'أخرى')
                    .toList()
                  ..sort();
                allCategories.addAll(otherCategories);

                // إضافة "أخرى" في النهاية إن وجد
                if (categoriesSet.contains('أخرى')) {
                  allCategories.add('أخرى');
                }

                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;

                return Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.38,
                      constraints: const BoxConstraints(maxWidth: 450),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  theme.colorScheme.surface,
                                  theme.colorScheme.surface.withOpacity(0.95),
                                ]
                              : [
                                  Colors.white,
                                  Colors.grey.shade50,
                                ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        Colors.orange.shade400,
                                        Colors.deepOrange.shade500,
                                      ]
                                    : [
                                        Colors.orange.shade300,
                                        Colors.deepOrange.shade400,
                                      ],
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.category,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'إدارة أنواع المصروفات',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close,
                                      color: Colors.white),
                                  tooltip: 'إغلاق',
                                ),
                              ],
                            ),
                          ),
                          // Content
                          Flexible(
                            child: allCategories.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.category_outlined,
                                          size: 56,
                                          color: Colors.grey.withOpacity(0.5),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'لا توجد أنواع مصروفات',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : FutureBuilder<Map<String, int>>(
                                    future: () async {
                                      final counts = <String, int>{};
                                      for (final cat in allCategories) {
                                        counts[cat] = await db
                                            .getExpenseCountByCategory(cat);
                                      }
                                      return counts;
                                    }(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Padding(
                                          padding: EdgeInsets.all(32),
                                          child: Center(
                                              child:
                                                  CircularProgressIndicator()),
                                        );
                                      }

                                      final categoryCounts =
                                          snapshot.data ?? <String, int>{};

                                      // دالة لإضافة نوع جديد مع التحديث المباشر
                                      void showAddCategoryDialogLocal() {
                                        final controller =
                                            TextEditingController();
                                        showDialog(
                                          context: context,
                                          builder: (context) => Directionality(
                                            textDirection: ui.TextDirection.rtl,
                                            child: AlertDialog(
                                              title: const Text(
                                                  'إضافة نوع مصروف جديد'),
                                              content: TextField(
                                                controller: controller,
                                                decoration:
                                                    const InputDecoration(
                                                  labelText: 'اسم النوع',
                                                  border: OutlineInputBorder(),
                                                ),
                                                autofocus: true,
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    controller.clear();
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text('إلغاء'),
                                                ),
                                                FilledButton(
                                                  onPressed: () {
                                                    final newCategory =
                                                        controller.text.trim();
                                                    if (newCategory
                                                        .isNotEmpty) {
                                                      // تحديث القائمة المحلية
                                                      setState(() {
                                                        if (!_categories
                                                            .contains(
                                                                newCategory)) {
                                                          _categories
                                                              .add(newCategory);
                                                        }
                                                      });
                                                      // تحديث النافذة مباشرة
                                                      setDialogState(() {});
                                                      controller.clear();
                                                      Navigator.pop(context);
                                                    }
                                                  },
                                                  child: const Text('إضافة'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }

                                      return Column(
                                        children: [
                                          // Add Category Button
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: FilledButton.icon(
                                              onPressed:
                                                  showAddCategoryDialogLocal,
                                              icon: const Icon(Icons.add,
                                                  size: 20),
                                              label: const Text(
                                                  'إضافة نوع جديد',
                                                  style:
                                                      TextStyle(fontSize: 14)),
                                              style: FilledButton.styleFrom(
                                                backgroundColor: isDark
                                                    ? Colors.deepOrange.shade500
                                                    : Colors
                                                        .deepOrange.shade400,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 20,
                                                  vertical: 12,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const Divider(height: 1),
                                          // Categories List
                                          Flexible(
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              padding: const EdgeInsets.all(12),
                                              itemCount: allCategories.length,
                                              itemBuilder: (context, index) {
                                                final category =
                                                    allCategories[index];
                                                final count =
                                                    categoryCounts[category] ??
                                                        0;
                                                final isDefault =
                                                    category == 'عام';

                                                return Container(
                                                  margin: const EdgeInsets.only(
                                                      bottom: 10),
                                                  decoration: BoxDecoration(
                                                    color: isDark
                                                        ? theme
                                                            .colorScheme.surface
                                                        : Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    border: Border.all(
                                                      color: isDefault
                                                          ? Colors.orange
                                                              .withOpacity(0.3)
                                                          : Colors.grey
                                                              .withOpacity(0.2),
                                                      width: isDefault ? 2 : 1,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: isDark
                                                            ? Colors.black
                                                                .withOpacity(
                                                                    0.3)
                                                            : Colors.black
                                                                .withOpacity(
                                                                    0.05),
                                                        blurRadius: 8,
                                                        offset:
                                                            const Offset(0, 2),
                                                      ),
                                                    ],
                                                  ),
                                                  child: ListTile(
                                                    contentPadding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                    leading: Container(
                                                      width: 44,
                                                      height: 44,
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                          colors: isDefault
                                                              ? [
                                                                  Colors.orange
                                                                      .shade300,
                                                                  Colors
                                                                      .deepOrange
                                                                      .shade400,
                                                                ]
                                                              : [
                                                                  Colors.orange
                                                                      .withOpacity(
                                                                          0.2),
                                                                  Colors.orange
                                                                      .withOpacity(
                                                                          0.1),
                                                                ],
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      child: Icon(
                                                        Icons.category,
                                                        color: isDefault
                                                            ? Colors.white
                                                            : Colors.orange,
                                                        size: 20,
                                                      ),
                                                    ),
                                                    title: Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            category,
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 15,
                                                              color: isDefault
                                                                  ? Colors
                                                                      .orange
                                                                      .shade700
                                                                  : theme
                                                                      .colorScheme
                                                                      .onSurface,
                                                            ),
                                                          ),
                                                        ),
                                                        if (isDefault)
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                              horizontal: 8,
                                                              vertical: 3,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .orange
                                                                  .withOpacity(
                                                                      0.2),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          6),
                                                            ),
                                                            child: Text(
                                                              'افتراضي',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .orange
                                                                    .shade700,
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    subtitle: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              top: 4),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons.receipt_long,
                                                            size: 12,
                                                            color: theme
                                                                .colorScheme
                                                                .onSurface
                                                                .withOpacity(
                                                                    0.6),
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            '$count مصروف',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: theme
                                                                  .colorScheme
                                                                  .onSurface
                                                                  .withOpacity(
                                                                      0.7),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    trailing: isDefault
                                                        ? const SizedBox
                                                            .shrink()
                                                        : Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors.red
                                                                  .withOpacity(
                                                                      0.1),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          6),
                                                            ),
                                                            child: IconButton(
                                                              icon: const Icon(
                                                                Icons
                                                                    .delete_outline,
                                                                color:
                                                                    Colors.red,
                                                                size: 20,
                                                              ),
                                                              onPressed:
                                                                  () async {
                                                                // تأكيد الحذف
                                                                final confirm =
                                                                    await showDialog<
                                                                        bool>(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (context) =>
                                                                          Directionality(
                                                                    textDirection: ui
                                                                        .TextDirection
                                                                        .rtl,
                                                                    child:
                                                                        AlertDialog(
                                                                      shape:
                                                                          RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(16),
                                                                      ),
                                                                      title:
                                                                          Row(
                                                                        children: [
                                                                          Icon(
                                                                            Icons.warning_amber_rounded,
                                                                            color:
                                                                                Colors.red,
                                                                          ),
                                                                          const SizedBox(
                                                                              width: 8),
                                                                          const Text(
                                                                              'تأكيد الحذف'),
                                                                        ],
                                                                      ),
                                                                      content:
                                                                          Text(
                                                                        count > 0
                                                                            ? 'سيتم تحديث $count مصروف من نوع "$category" إلى "عام". هل تريد المتابعة؟'
                                                                            : 'هل تريد حذف نوع "$category"؟',
                                                                      ),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed: () => Navigator.pop(
                                                                              context,
                                                                              false),
                                                                          child:
                                                                              const Text('إلغاء'),
                                                                        ),
                                                                        FilledButton(
                                                                          onPressed: () => Navigator.pop(
                                                                              context,
                                                                              true),
                                                                          style:
                                                                              FilledButton.styleFrom(
                                                                            backgroundColor:
                                                                                Colors.red,
                                                                          ),
                                                                          child:
                                                                              const Text('حذف'),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                );

                                                                if (confirm ==
                                                                        true &&
                                                                    mounted) {
                                                                  try {
                                                                    await db.deleteExpenseCategory(
                                                                        category);
                                                                    if (mounted) {
                                                                      // حذف النوع من القائمة المحلية
                                                                      setState(
                                                                          () {
                                                                        _categories
                                                                            .remove(category);
                                                                        // التأكد من وجود "عام" في القائمة
                                                                        if (!_categories
                                                                            .contains('عام')) {
                                                                          _categories.insert(
                                                                              0,
                                                                              'عام');
                                                                        }
                                                                        if (_selectedCategory ==
                                                                            category) {
                                                                          _selectedCategory =
                                                                              null;
                                                                        }
                                                                      });

                                                                      ScaffoldMessenger.of(
                                                                              context)
                                                                          .showSnackBar(
                                                                        SnackBar(
                                                                          content:
                                                                              Text(
                                                                            count > 0
                                                                                ? 'تم تحديث $count مصروف إلى "عام"'
                                                                                : 'تم حذف النوع بنجاح',
                                                                          ),
                                                                          backgroundColor:
                                                                              Colors.green,
                                                                        ),
                                                                      );

                                                                      // تحديث النافذة مباشرة
                                                                      setDialogState(
                                                                          () {});
                                                                    }
                                                                  } catch (e) {
                                                                    if (mounted) {
                                                                      ScaffoldMessenger.of(
                                                                              context)
                                                                          .showSnackBar(
                                                                        SnackBar(
                                                                          content:
                                                                              Text('خطأ: $e'),
                                                                          backgroundColor:
                                                                              Colors.red,
                                                                        ),
                                                                      );
                                                                    }
                                                                  }
                                                                }
                                                              },
                                                              tooltip:
                                                                  'حذف النوع',
                                                            ),
                                                          ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ));
  }
}

class _ExpenseCard extends StatelessWidget {
  final Map<String, dynamic> expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool canEdit;

  const _ExpenseCard({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context) {
    final amount = (expense['amount'] as num?)?.toDouble() ?? 0.0;
    final title = expense['title']?.toString() ?? '';
    final category = expense['category']?.toString() ?? 'عام';
    final description = expense['description']?.toString();
    final expenseDate = expense['expense_date']?.toString();

    DateTime? date;
    if (expenseDate != null) {
      try {
        date = DateTime.parse(expenseDate);
      } catch (e) {
        // تجاهل خطأ التحليل
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // أيقونة - تصميم جذاب
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.receipt_long,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // المحتوى
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (date != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            DateFormat('yyyy-MM-dd').format(date),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.secondaryContainer,
                              Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer
                                  .withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondaryContainer,
                          ),
                        ),
                      ),
                      if (description != null && description.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.65),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // المبلغ والأزرار
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    Formatters.currencyIQD(amount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                if (canEdit) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: onEdit,
                          tooltip: 'تعديل',
                          padding: const EdgeInsets.all(8),
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          onPressed: onDelete,
                          tooltip: 'حذف',
                          padding: const EdgeInsets.all(8),
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseEditorDialog extends StatefulWidget {
  final Map<String, dynamic>? expense;
  final List<String> categories;

  const _ExpenseEditorDialog({
    this.expense,
    required this.categories,
  });

  @override
  State<_ExpenseEditorDialog> createState() => _ExpenseEditorDialogState();
}

class _ExpenseEditorDialogState extends State<_ExpenseEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'عام';
  DateTime _selectedDate = DateTime.now();
  final _newCategoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _titleController.text = widget.expense!['title']?.toString() ?? '';
      _amountController.text =
          (widget.expense!['amount'] as num?)?.toString() ?? '';
      _descriptionController.text =
          widget.expense!['description']?.toString() ?? '';
      _selectedCategory = widget.expense!['category']?.toString() ?? 'عام';

      final expenseDate = widget.expense!['expense_date']?.toString();
      if (expenseDate != null) {
        try {
          _selectedDate = DateTime.parse(expenseDate);
        } catch (e) {
          // تجاهل خطأ التحليل
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.5,
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      theme.colorScheme.surface,
                      theme.colorScheme.surface.withOpacity(0.95),
                    ]
                  : [
                      Colors.white,
                      Colors.grey.shade50,
                    ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            Colors.orange.shade400,
                            Colors.deepOrange.shade500,
                          ]
                        : [
                            Colors.orange.shade300,
                            Colors.deepOrange.shade400,
                          ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.expense == null
                            ? 'إضافة مصروف جديد'
                            : 'تعديل المصروف',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      tooltip: 'إغلاق',
                    ),
                  ],
                ),
              ),
              // Form Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title Field
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _titleController,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              labelText: 'عنوان المصروف',
                              hintText: 'مثال: إيجار المحل',
                              prefixIcon:
                                  const Icon(Icons.title, color: Colors.orange),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? theme.colorScheme.surface
                                  : Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال عنوان المصروف';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Category and Amount Row
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? theme.colorScheme.surface
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.black.withOpacity(0.3)
                                          : Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedCategory,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  dropdownColor: isDark
                                      ? theme.colorScheme.surface
                                      : Colors.white,
                                  iconEnabledColor: Colors.orange,
                                  iconDisabledColor: theme.colorScheme.onSurface
                                      .withOpacity(0.38),
                                  decoration: InputDecoration(
                                    labelText: 'نوع المصروف',
                                    labelStyle: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                    prefixIcon: const Icon(Icons.category,
                                        color: Colors.orange),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? theme.colorScheme.surface
                                        : Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 18,
                                    ),
                                  ),
                                  items: [
                                    ...widget.categories
                                        .map((cat) => DropdownMenuItem(
                                              value: cat,
                                              child: Text(
                                                cat,
                                                style: TextStyle(
                                                  color: theme
                                                      .colorScheme.onSurface,
                                                ),
                                              ),
                                            )),
                                    DropdownMenuItem(
                                      value: 'new',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.add,
                                            size: 18,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'إضافة نوع جديد',
                                            style: TextStyle(
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value == 'new') {
                                      _showAddCategoryDialog();
                                    } else {
                                      setState(() =>
                                          _selectedCategory = value ?? 'عام');
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? theme.colorScheme.surface
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.black.withOpacity(0.3)
                                          : Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _amountController,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  decoration: InputDecoration(
                                    labelText: 'المبلغ (د.ع)',
                                    hintText: '0.00',
                                    prefixIcon: const Icon(Icons.attach_money,
                                        color: Colors.orange),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? theme.colorScheme.surface
                                        : Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 18,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'يرجى إدخال المبلغ';
                                    }
                                    final amount = double.tryParse(value);
                                    if (amount == null || amount <= 0) {
                                      return 'يرجى إدخال مبلغ صحيح';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Date Picker
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? theme.colorScheme.surface
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: _selectDate,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.calendar_today,
                                      color: Colors.orange,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'تاريخ المصروف',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.colorScheme.onSurface
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('yyyy-MM-dd', 'en_US')
                                              .format(_selectedDate),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Description Field
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? theme.colorScheme.surface
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withOpacity(0.3)
                                    : Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _descriptionController,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              labelText: 'الوصف (اختياري)',
                              hintText: 'أضف وصفاً تفصيلياً للمصروف...',
                              prefixIcon: const Icon(Icons.description,
                                  color: Colors.orange),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? theme.colorScheme.surface
                                  : Colors.white,
                              contentPadding: const EdgeInsets.all(20),
                            ),
                            maxLines: 4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(
                                    color: theme.colorScheme.outline,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Text(
                                  'إلغاء',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: FilledButton(
                                onPressed: _saveExpense,
                                style: FilledButton.styleFrom(
                                  backgroundColor: isDark
                                      ? Colors.deepOrange.shade500
                                      : Colors.deepOrange.shade400,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.save, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'حفظ المصروف',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Directionality(
          textDirection: ui.TextDirection.rtl,
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة نوع مصروف جديد'),
          content: TextField(
            controller: _newCategoryController,
            decoration: const InputDecoration(
              labelText: 'اسم النوع',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                _newCategoryController.clear();
                Navigator.pop(context);
              },
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final newCategory = _newCategoryController.text.trim();
                if (newCategory.isNotEmpty) {
                  setState(() {
                    _selectedCategory = newCategory;
                    if (!widget.categories.contains(newCategory)) {
                      widget.categories.add(newCategory);
                    }
                  });
                  _newCategoryController.clear();
                  Navigator.pop(context);
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final title = _titleController.text.trim();
    final amount = double.parse(_amountController.text);
    final category = _selectedCategory;
    final description = _descriptionController.text.trim();
    final expenseDate = _selectedDate;

    try {
      final db = context.read<DatabaseService>();

      if (widget.expense == null) {
        await db.createExpense(
          title: title,
          amount: amount,
          category: category,
          description: description.isEmpty ? null : description,
          expenseDate: expenseDate,
        );
      } else {
        await db.updateExpense(
          id: widget.expense!['id'] as int,
          title: title,
          amount: amount,
          category: category,
          description: description.isEmpty ? null : description,
          expenseDate: expenseDate,
        );
      }

      if (mounted) {
        Navigator.pop(context, {'success': true});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في حفظ المصروف: $e')),
        );
      }
    }
  }
}

class _QuickDateButton extends StatelessWidget {
  const _QuickDateButton({
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: isSelected
            ? Theme.of(context).primaryColor
            : Theme.of(context).colorScheme.surface,
        foregroundColor: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface,
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Theme.of(context).colorScheme.outline,
          width: 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 100,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.06),
            Theme.of(context).colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // العنوان والأيقونة
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.75),
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.3),
                        color.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
              ],
            ),
            // الرقم
            Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: -0.4,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final bool isPrimary;

  const _FilterButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          elevation: 2,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: color),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
    );
  }
}
