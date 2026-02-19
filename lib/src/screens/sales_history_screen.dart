import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/db/database_service.dart';
import '../services/auth/auth_provider.dart';
import '../services/sales_history_view_model.dart';
import '../services/print_service.dart';
import '../services/store_config.dart';
import '../utils/format.dart';
import '../utils/dark_mode_utils.dart';
import '../utils/click_guard.dart';
import 'package:intl/intl.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_display_widgets.dart' as errw;

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  // متغيرات التحديد الجماعي
  bool _isSelectionMode = false;
  Set<int> _selectedSales = <int>{};

  // متغيرات الترتيب
  final bool _sortDescending =
      true; // true = من الأحدث للأقدم، false = من الأقدم للأحدث

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SalesHistoryViewModel>().load();
      }
    });
  }

  Future<void> _loadSales() async {}

  Future<void> _selectDateRange() async {
    final vm = context.read<SalesHistoryViewModel>();
    DateTime? tempFrom = vm.fromDate;
    DateTime? tempTo = vm.toDate;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Directionality(
          textDirection: Directionality.of(context),
          child: Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: StatefulBuilder(builder: (context, setModalState) {
              String formatDate(DateTime? d) =>
                  d == null ? '-' : DateFormat('yyyy/MM/dd').format(d);

              void applyQuickRange(String key) {
                final now = DateTime.now();
                DateTime start;
                DateTime end;
                if (key == 'today') {
                  start = DateTime(now.year, now.month, now.day);
                  end = start;
                } else if (key == '7') {
                  end = DateTime(now.year, now.month, now.day);
                  start = end.subtract(const Duration(days: 6));
                } else if (key == '30') {
                  end = DateTime(now.year, now.month, now.day);
                  start = end.subtract(const Duration(days: 29));
                } else if (key == 'month') {
                  start = DateTime(now.year, now.month, 1);
                  end = DateTime(now.year, now.month + 1, 0);
                } else {
                  start = DateTime(now.year, now.month, now.day);
                  end = start;
                }
                setModalState(() {
                  tempFrom = start;
                  tempTo = end;
                });
              }

              Future<void> pickFrom() async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDate: tempFrom ?? DateTime.now(),
                );
                if (picked != null) {
                  setModalState(() => tempFrom = picked);
                }
              }

              Future<void> pickTo() async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDate: tempTo ?? tempFrom ?? DateTime.now(),
                );
                if (picked != null) {
                  setModalState(() => tempTo = picked);
                }
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'اختيار الفترة',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('اليوم'),
                            selected: false,
                            onSelected: (_) => applyQuickRange('today'),
                          ),
                          ChoiceChip(
                            label: const Text('آخر 7 أيام'),
                            selected: false,
                            onSelected: (_) => applyQuickRange('7'),
                          ),
                          ChoiceChip(
                            label: const Text('آخر 30 يوم'),
                            selected: false,
                            onSelected: (_) => applyQuickRange('30'),
                          ),
                          ChoiceChip(
                            label: const Text('هذا الشهر'),
                            selected: false,
                            onSelected: (_) => applyQuickRange('month'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: pickFrom,
                              icon: Icon(Icons.calendar_today,
                                  size: 16,
                                  color: DarkModeUtils.getSecondaryTextColor(
                                      context)),
                              label: Text('من: ${formatDate(tempFrom)}'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: pickTo,
                              icon: Icon(Icons.calendar_today,
                                  size: 16,
                                  color: DarkModeUtils.getSecondaryTextColor(
                                      context)),
                              label: Text('إلى: ${formatDate(tempTo)}'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempFrom = null;
                                tempTo = null;
                              });
                            },
                            child: const Text('مسح'),
                          ),
                          const Spacer(),
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('إلغاء'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () {
                              if (tempFrom != null &&
                                  tempTo != null &&
                                  tempFrom!.isAfter(tempTo!)) {
                                final tmp = tempFrom;
                                tempFrom = tempTo;
                                tempTo = tmp;
                              }
                              vm.updateDateRange(from: tempFrom, to: tempTo);
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.check,
                                color: DarkModeUtils.getSuccessColor(context)),
                            label: const Text('تطبيق'),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedSales.clear();
      }
    });
  }

  void _selectAll() {
    setState(() {
      final vm = context.read<SalesHistoryViewModel>();
      _selectedSales = vm.sales.map((sale) => sale['id'] as int).toSet();
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedSales.clear();
    });
  }

  void _toggleSaleSelection(int saleId) {
    setState(() {
      if (_selectedSales.contains(saleId)) {
        _selectedSales.remove(saleId);
      } else {
        _selectedSales.add(saleId);
      }
    });
  }

  void _toggleSortOrder() {
    context.read<SalesHistoryViewModel>().toggleSort();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SalesHistoryViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSelectionMode
              ? 'تم تحديد ${_selectedSales.length} من ${vm.sales.length}'
              : 'تاريخ المبيعات',
          style: TextStyle(
            color: _isSelectionMode
                ? Colors.white
                : DarkModeUtils.getTextColor(context),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: _isSelectionMode
            ? DarkModeUtils.getErrorColor(context)
            : DarkModeUtils.getCardColor(context),
        foregroundColor: DarkModeUtils.getTextColor(context),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: _isSelectionMode
                ? LinearGradient(
                    colors: [
                      DarkModeUtils.getErrorColor(context),
                      DarkModeUtils.getErrorColor(context).withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      DarkModeUtils.getCardColor(context),
                      DarkModeUtils.getCardColor(context).withOpacity(0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            boxShadow: [
              BoxShadow(
                color: DarkModeUtils.getShadowColor(context),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        actions: _isSelectionMode
            ? [
                // أزرار وضع التحديد
                Builder(
                  builder: (context) {
                    final vm = context.watch<SalesHistoryViewModel>();
                    return Row(children: [
                      if (_selectedSales.length < vm.sales.length)
                        IconButton(
                          icon: Icon(Icons.select_all,
                              color: _isSelectionMode
                                  ? Colors.white
                                  : DarkModeUtils.getTextColor(context)),
                          onPressed: _selectAll,
                          tooltip: 'تحديد الكل',
                        ),
                      if (_selectedSales.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.clear,
                              color: _isSelectionMode
                                  ? Colors.white
                                  : DarkModeUtils.getTextColor(context)),
                          onPressed: _deselectAll,
                          tooltip: 'إلغاء التحديد',
                        ),
                      if (_selectedSales.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.white),
                          onPressed: () => ClickGuard.runExclusive(
                            'sales_history_bulk_delete',
                            _confirmBulkDelete,
                          ),
                          tooltip: 'حذف المحدد',
                        ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: _toggleSelectionMode,
                        tooltip: 'إلغاء وضع التحديد',
                      ),
                    ]);
                  },
                ),
              ]
            : [
                // أزرار الوضع العادي
                IconButton(
                  icon: Icon(
                      _sortDescending
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: DarkModeUtils.getTextColor(context)),
                  onPressed: () => ClickGuard.runExclusive(
                    'sales_history_toggle_sort',
                    _toggleSortOrder,
                    cooldown: const Duration(milliseconds: 250),
                  ),
                  tooltip: _sortDescending ? 'ترتيب تصاعدي' : 'ترتيب تنازلي',
                ),
                IconButton(
                  icon: Icon(Icons.checklist,
                      color: DarkModeUtils.getTextColor(context)),
                  onPressed: _toggleSelectionMode,
                  tooltip: 'وضع التحديد',
                ),
                Builder(
                  builder: (context) {
                    final vm = context.watch<SalesHistoryViewModel>();
                    return IconButton(
                      icon: Icon(Icons.refresh,
                          color: DarkModeUtils.getTextColor(context)),
                      onPressed: vm.load,
                      tooltip: 'تحديث',
                    );
                  },
                ),
              ],
      ),
      body: Container(
        color: DarkModeUtils.getBackgroundColor(context),
        child: Column(
          children: [
            // Filters Section - محسن
            Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: DarkModeUtils.getCardColor(context),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: DarkModeUtils.getBorderColor(context)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    // Search Field
                    Expanded(
                      flex: 3,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText:
                              'البحث في المبيعات والعملاء وأرقام الفواتير...',
                          prefixIcon: Icon(Icons.search,
                              size: 20,
                              color:
                                  DarkModeUtils.getSecondaryTextColor(context)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          context
                              .read<SalesHistoryViewModel>()
                              .updateQuery(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Payment Type Filter (ChoiceChips for consistency)
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _typeChip('الكل', ''),
                            _typeChip('نقدي', 'cash'),
                            _typeChip('أجل', 'credit'),
                            _typeChip('أقساط', 'installment'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Date Range Filter
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: _selectDateRange,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: DarkModeUtils.getBorderColor(context)),
                            borderRadius: BorderRadius.circular(10),
                            color: DarkModeUtils.getCardColor(context),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.date_range,
                                  size: 16,
                                  color: DarkModeUtils.getSecondaryTextColor(
                                      context)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  vm.fromDate != null && vm.toDate != null
                                      ? '${DateFormat('MM/dd').format(vm.fromDate!)} - ${DateFormat('MM/dd').format(vm.toDate!)}'
                                      : 'الفترة',
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              if (vm.fromDate != null || vm.toDate != null) ...[
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: () {
                                    vm.updateDateRange(from: null, to: null);
                                  },
                                  child: Icon(Icons.close,
                                      size: 14,
                                      color:
                                          DarkModeUtils.getSecondaryTextColor(
                                              context)),
                                ),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Sales List
            Expanded(
              child: vm.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : vm.error != null
                      ? errw.ErrorWidget(
                          error: vm.error,
                          onRetry: vm.load,
                        )
                      : vm.sales.isEmpty
                          ? Center(
                              child: EmptyState(
                                icon: Icons.receipt_long,
                                title: 'لا توجد مبيعات',
                                message:
                                    'لم يتم العثور على أي مبيعات تطابق المعايير المحددة',
                                actionLabel: 'تحديث',
                                onAction: vm.load,
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              itemCount: vm.sales.length,
                              itemBuilder: (context, index) {
                                final sale = vm.sales[index];
                                return _buildCompactSaleCard(sale);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String label, String value) {
    final vm = context.watch<SalesHistoryViewModel>();
    final bool selected =
        vm.type == value || (vm.type.isEmpty && value.isEmpty);

    // تحديد اللون حسب نوع الدفع
    Color typeColor;
    switch (value) {
      case 'cash':
        typeColor = Colors.blue;
        break;
      case 'credit':
        typeColor = Colors.red;
        break;
      case 'installment':
        typeColor = Colors.green;
        break;
      default: // 'الكل' أو ''
        typeColor = DarkModeUtils.getSecondaryTextColor(context);
        break;
    }

    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      selectedColor: typeColor.withOpacity(0.15),
      labelStyle: TextStyle(
        color: selected
            ? typeColor
            : typeColor.withOpacity(0.7), // ملون حتى عند عدم التحديد
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(
        color: selected
            ? typeColor
            : typeColor.withOpacity(0.5), // ملون حتى عند عدم التحديد
        width: selected ? 1.5 : 1.0,
      ),
      onSelected: (_) =>
          context.read<SalesHistoryViewModel>().updateType(value),
    );
  }

  Widget _buildCompactSaleCard(Map<String, Object?> sale) {
    final saleId = sale['id'] as int;
    final total = (sale['total'] as num).toDouble();
    final profit = (sale['profit'] as num).toDouble();
    final type = sale['type'] as String;
    final createdAt = DateTime.parse(sale['created_at'] as String);
    final customerName = sale['customer_name'] as String?;
    final isSelected = _selectedSales.contains(saleId);

    Color typeColor;
    IconData typeIcon;
    String typeText;

    switch (type) {
      case 'cash':
        typeColor = Colors.blue;
        typeIcon = Icons.payments_outlined;
        typeText = 'نقدي';
        break;
      case 'credit':
        typeColor = Colors.red;
        typeIcon = Icons.schedule;
        typeText = 'أجل';
        break;
      case 'installment':
        typeColor = Colors.green;
        typeIcon = Icons.view_timeline_outlined;
        typeText = 'أقساط';
        break;
      default:
        typeColor = DarkModeUtils.getSecondaryTextColor(context);
        typeIcon = Icons.receipt_long;
        typeText = 'غير محدد';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: DarkModeUtils.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                isSelected ? typeColor : DarkModeUtils.getBorderColor(context),
            width: isSelected ? 1.2 : 0.8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isSelectionMode ? () => _toggleSaleSelection(saleId) : null,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              // Accent bar on the left
              Container(
                width: 4,
                height: 82,
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (_isSelectionMode) ...[
                            Checkbox(
                              value: isSelected,
                              onChanged: (value) =>
                                  _toggleSaleSelection(saleId),
                              activeColor: typeColor,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text('#$saleId',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: typeColor)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(typeIcon, size: 12, color: typeColor),
                                const SizedBox(width: 4),
                                Text(
                                  typeText,
                                  style: TextStyle(
                                    color: typeColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: typeColor),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('MM/dd HH:mm').format(createdAt),
                            style: TextStyle(
                                fontSize: 11,
                                color: DarkModeUtils.getSecondaryTextColor(
                                    context)),
                          ),
                          const Spacer(),
                          Text(
                            Formatters.currencyIQD(total),
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: DarkModeUtils.getSuccessColor(context)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 16, color: typeColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              customerName ?? 'عميل عام',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: typeColor),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ربح: ${Formatters.currencyIQD(profit)}',
                            style: TextStyle(
                                fontSize: 10,
                                color: profit > 0
                                    ? DarkModeUtils.getInfoColor(context)
                                    : DarkModeUtils.getErrorColor(context),
                                fontWeight: FontWeight.w600),
                          ),
                          if (!_isSelectionMode) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _showSaleDetails(saleId),
                              child: Icon(
                                Icons.visibility_outlined,
                                size: 20,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => _printInvoice(saleId),
                              child: const Icon(
                                Icons.print_outlined,
                                size: 20,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => _confirmDeleteSale(saleId),
                              child: const Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Right side spacer to balance layout
              const SizedBox(width: 0),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSaleDetails(int saleId) async {
    try {
      final db = context.read<DatabaseService>();
      final saleDetails = await db.getSaleDetails(saleId);
      final saleItems = await db.getSaleItems(saleId);

      if (saleDetails == null) return;

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
              decoration: BoxDecoration(
                color: DarkModeUtils.getCardColor(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      textDirection: ui.TextDirection.rtl,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close,
                            color: DarkModeUtils.getCardColor(context),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'تفاصيل الفاتورة #$saleId',
                                style: TextStyle(
                                  color: DarkModeUtils.getCardColor(context),
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.right,
                              ),
                              if (saleDetails['customer_name'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  saleDetails['customer_name'] as String,
                                  style: TextStyle(
                                    color: DarkModeUtils.getSecondaryTextColor(
                                        context),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          Icons.receipt_long,
                          color: DarkModeUtils.getCardColor(context),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Sale Info
                          _buildDetailRow(
                              'التاريخ',
                              DateFormat('yyyy/MM/dd - HH:mm').format(
                                DateTime.parse(
                                    saleDetails['created_at'] as String),
                              )),
                          const SizedBox(height: 18),
                          _buildDetailRow('نوع الدفع',
                              _getTypeText(saleDetails['type'] as String)),
                          if (saleDetails['customer_name'] != null) ...[
                            const SizedBox(height: 18),
                            _buildDetailRow('العميل',
                                saleDetails['customer_name'] as String),
                          ],
                          if (saleDetails['customer_phone'] != null) ...[
                            const SizedBox(height: 18),
                            _buildDetailRow('الهاتف',
                                saleDetails['customer_phone'] as String),
                          ],
                          const SizedBox(height: 18),
                          _buildDetailRow(
                              'الإجمالي',
                              Formatters.currencyIQD(
                                  saleDetails['total'] as num)),
                          // إضافة المبلغ المقدم والمتبقي للمبيعات بالأقساط
                          if (saleDetails['type'] == 'installment' &&
                              saleDetails['down_payment'] != null &&
                              (saleDetails['down_payment'] as num) > 0) ...[
                            const SizedBox(height: 18),
                            _buildDetailRow(
                                'المبلغ المقدم',
                                Formatters.currencyIQD(
                                    saleDetails['down_payment'] as num),
                                valueColor:
                                    DarkModeUtils.getSuccessColor(context)),
                            const SizedBox(height: 18),
                            _buildDetailRow(
                                'الباقي',
                                Formatters.currencyIQD(
                                    (saleDetails['total'] as num) -
                                        (saleDetails['down_payment'] as num)),
                                valueColor:
                                    DarkModeUtils.getWarningColor(context)),
                          ],
                          const SizedBox(height: 18),
                          _buildDetailRow(
                              'الربح',
                              Formatters.currencyIQD(
                                  saleDetails['profit'] as num)),
                          const SizedBox(height: 24),
                          // Items
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'المنتجات:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...saleItems.map((item) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(item['product_name'] as String),
                                  subtitle:
                                      Text('الكمية : ${item['quantity']}'),
                                  trailing: Text(
                                    Formatters.currencyIQD(
                                        (item['price'] as num) *
                                            (item['quantity'] as num)),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل تفاصيل الفاتورة: $e'),
          backgroundColor: DarkModeUtils.getErrorColor(context),
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        textDirection: ui.TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: RichText(
              textDirection: ui.TextDirection.rtl,
              textAlign: TextAlign.right,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      color: valueColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'cash':
        return 'نقدي';
      case 'credit':
        return 'أجل';
      case 'installment':
        return 'أقساط';
      default:
        return 'غير محدد';
    }
  }

  Future<void> _confirmDeleteSale(int saleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
            'هل أنت متأكد من حذف الفاتورة #$saleId؟\n\nسيتم إرجاع المنتجات إلى المخزون.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: DarkModeUtils.getErrorColor(context),
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteSale(saleId);
    }
  }

  Future<void> _deleteSale(int saleId) async {
    try {
      final db = context.read<DatabaseService>();
      final auth = context.read<AuthProvider>();
      final currentUser = auth.currentUser;
      final success = await db.deleteSale(
        saleId,
        userId: currentUser?.id,
        username: currentUser?.username,
        name: currentUser?.name,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف الفاتورة #$saleId بنجاح'),
            backgroundColor: DarkModeUtils.getSuccessColor(context),
          ),
        );
        // Refresh the sales list
        _loadSales();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('فشل في حذف الفاتورة'),
            backgroundColor: DarkModeUtils.getErrorColor(context),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في حذف الفاتورة: $e'),
          backgroundColor: DarkModeUtils.getErrorColor(context),
        ),
      );
    }
  }

  Future<void> _printInvoice(int saleId) async {
    try {
      final db = context.read<DatabaseService>();
      final saleDetails = await db.getSaleDetails(saleId);
      final saleItems = await db.getSaleItems(saleId);

      if (saleDetails == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('لم يتم العثور على تفاصيل الفاتورة'),
            backgroundColor: DarkModeUtils.getErrorColor(context),
          ),
        );
        return;
      }

      // عرض خيارات الطباعة
      final printOptions = await PrintService.showPrintOptionsDialog(context);
      if (printOptions == null) {
        // المستخدم ألغى العملية
        return;
      }

      // تحويل عناصر المبيعات إلى تنسيق مناسب للطباعة مع جميع التفاصيل
      final items = saleItems
          .map((item) => {
                'name': item['product_name'] ?? 'منتج غير محدد',
                'price': item['price'] ?? 0,
                'quantity': item['quantity'] ?? 1,
                'cost': item['cost'] ?? 0,
                'barcode': item['barcode'] ?? '',
              })
          .toList();

      // الحصول على معلومات العميل الكاملة
      final customerName = saleDetails['customer_name'] as String?;
      final customerPhone = saleDetails['customer_phone'] as String?;
      final customerAddress = saleDetails['customer_address'] as String?;

      // الحصول على تاريخ الاستحقاق
      DateTime? dueDate;
      if (saleDetails['due_date'] != null) {
        try {
          dueDate = DateTime.parse(saleDetails['due_date'] as String);
        } catch (e) {
          // تجاهل خطأ تحليل التاريخ والاستمرار بدون تاريخ استحقاق
        }
      }

      // الحصول على معلومات الأقساط إذا كانت متوفرة
      List<Map<String, Object?>>? installments;
      double? totalDebt;
      double? downPayment;

      if (saleDetails['type'] == 'installment') {
        try {
          installments = await db.getInstallments(saleId: saleId);
          totalDebt = saleDetails['total'] as double?;
          downPayment = saleDetails['down_payment'] as double?;
        } catch (e) {
          // تجاهل خطأ جلب الأقساط والاستمرار بدون معلومات الأقساط
        }
      }

      // طباعة الفاتورة مع جميع التفاصيل والخيارات المختارة
      final store = context.read<StoreConfig>();
      final success = await PrintService.printInvoice(
        shopName: store.shopName,
        phone: store.phone,
        address: store.address,
        items: items,
        paymentType: saleDetails['type'] as String,
        customerName: customerName,
        customerPhone: customerPhone,
        customerAddress: customerAddress,
        dueDate: dueDate,
        invoiceNumber: saleId.toString(),
        installments: installments,
        totalDebt: totalDebt,
        downPayment: downPayment,
        pageFormat: printOptions['pageFormat'] as String,
        showLogo: printOptions['showLogo'] as bool,
        showBarcode: printOptions['showBarcode'] as bool,
        context: context,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم طباعة الفاتورة #$saleId بنجاح مع جميع التفاصيل'),
            backgroundColor: DarkModeUtils.getSuccessColor(context),
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('فشل في طباعة الفاتورة'),
            backgroundColor: DarkModeUtils.getErrorColor(context),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في طباعة الفاتورة: $e'),
          backgroundColor: DarkModeUtils.getErrorColor(context),
        ),
      );
    }
  }

  Future<void> _confirmBulkDelete() async {
    if (_selectedSales.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف الجماعي'),
        content: Text(
            'هل أنت متأكد من حذف ${_selectedSales.length} فاتورة؟\n\nسيتم إرجاع المنتجات إلى المخزون.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: DarkModeUtils.getErrorColor(context),
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _bulkDeleteSales();
    }
  }

  Future<void> _bulkDeleteSales() async {
    if (_selectedSales.isEmpty) return;

    try {
      final db = context.read<DatabaseService>();
      int successCount = 0;
      int failCount = 0;

      // إظهار مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('جاري حذف الفواتير...'),
            ],
          ),
        ),
      );

      // حذف كل فاتورة على حدة
      final auth = context.read<AuthProvider>();
      final currentUser = auth.currentUser;
      for (final saleId in _selectedSales) {
        try {
          final success = await db.deleteSale(
            saleId,
            userId: currentUser?.id,
            username: currentUser?.username,
            name: currentUser?.name,
          );
          if (success) {
            successCount++;
          } else {
            failCount++;
          }
        } catch (e) {
          failCount++;
        }
      }

      // إغلاق مؤشر التحميل
      if (mounted) Navigator.pop(context);

      if (!mounted) return;

      // إظهار النتيجة
      String message;
      if (failCount == 0) {
        message = 'تم حذف $successCount فاتورة بنجاح';
      } else if (successCount == 0) {
        message = 'فشل في حذف جميع الفواتير';
      } else {
        message = 'تم حذف $successCount فاتورة، فشل في حذف $failCount فاتورة';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: failCount == 0
              ? DarkModeUtils.getSuccessColor(context)
              : DarkModeUtils.getWarningColor(context),
          duration: const Duration(seconds: 3),
        ),
      );

      // إعادة تحميل القائمة وإلغاء وضع التحديد
      setState(() {
        _selectedSales.clear();
        _isSelectionMode = false;
      });
      _loadSales();
    } catch (e) {
      // إغلاق مؤشر التحميل إذا كان مفتوحاً
      if (mounted) Navigator.pop(context);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في الحذف الجماعي: $e'),
          backgroundColor: DarkModeUtils.getErrorColor(context),
        ),
      );
    }
  }
}
