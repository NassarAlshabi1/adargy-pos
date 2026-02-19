import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../services/db/database_service.dart';
import '../../utils/format.dart';
import '../debts_widgets/installment_card.dart';
import '../debts_widgets/debts_helpers.dart';

/// تبويب الأقساط
class InstallmentsTab extends StatefulWidget {
  final DatabaseService db;
  final String searchQuery;
  final int refreshKey;
  final VoidCallback onRefresh;

  const InstallmentsTab({
    super.key,
    required this.db,
    required this.searchQuery,
    required this.refreshKey,
    required this.onRefresh,
  });

  @override
  State<InstallmentsTab> createState() => _InstallmentsTabState();
}

class _InstallmentsTabState extends State<InstallmentsTab> {
  String _installmentFilter = 'all'; // all, paid, unpaid, overdue
  DateTime? _fromDate;
  DateTime? _toDate;

  void _showDateRangeDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('فلترة بالتاريخ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('من تاريخ'),
                subtitle: Text(_fromDate != null
                    ? '${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}'
                    : 'لم يتم تحديد تاريخ'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _fromDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    useRootNavigator: true,
                    builder: (ctx, child) => Directionality(
                      textDirection: ui.TextDirection.rtl,
                      child: child ?? const SizedBox.shrink(),
                    ),
                  );
                  if (date != null) {
                    setState(() {
                      _fromDate = date;
                    });
                  }
                },
              ),
              ListTile(
                title: const Text('إلى تاريخ'),
                subtitle: Text(_toDate != null
                    ? '${_toDate!.day}/${_toDate!.month}/${_toDate!.year}'
                    : 'لم يتم تحديد تاريخ'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _toDate ?? DateTime.now(),
                    firstDate: _fromDate ?? DateTime(2020),
                    lastDate: DateTime.now(),
                    useRootNavigator: true,
                    builder: (ctx, child) => Directionality(
                      textDirection: ui.TextDirection.rtl,
                      child: child ?? const SizedBox.shrink(),
                    ),
                  );
                  if (date != null) {
                    setState(() {
                      _toDate = date;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _fromDate = null;
                  _toDate = null;
                });
                Navigator.pop(context);
              },
              child: const Text('مسح الفلترة'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('تطبيق'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // شريط الفلترة
        Container(
          padding: const EdgeInsets.all(8),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _installmentFilter,
                      decoration: InputDecoration(
                        labelText: 'فلترة الأقساط',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color:
                                Theme.of(context).dividerColor.withOpacity(0.4),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color:
                                Theme.of(context).dividerColor.withOpacity(0.4),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('جميع الأقساط')),
                        DropdownMenuItem(
                            value: 'paid', child: Text('المدفوعة')),
                        DropdownMenuItem(
                            value: 'unpaid', child: Text('غير المدفوعة')),
                        DropdownMenuItem(
                            value: 'overdue', child: Text('المتأخرة')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _installmentFilter = value ?? 'all';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _showDateRangeDialog,
                    icon: Icon(
                      Icons.date_range,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.8),
                    ),
                    tooltip: 'فلترة بالتاريخ',
                  ),
                ],
              ),
              if (_fromDate != null || _toDate != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (_fromDate != null)
                      Chip(
                        label: Text(
                            'من: ${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}'),
                        onDeleted: () {
                          setState(() {
                            _fromDate = null;
                          });
                        },
                      ),
                    if (_toDate != null)
                      Chip(
                        label: Text(
                            'إلى: ${_toDate!.day}/${_toDate!.month}/${_toDate!.year}'),
                        onDeleted: () {
                          setState(() {
                            _toDate = null;
                          });
                        },
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // ملخص إجمالي الأقساط
        Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: FutureBuilder<Map<String, double>>(
            future: DebtsHelpers.getInstallmentsSummary(widget.db),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final summary = snapshot.data!;
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'إجمالي الأقساط الأصلية',
                            style: TextStyle(
                              fontSize: 9,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                          Text(
                            Formatters.currencyIQD(summary['installment'] ?? 0),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: Theme.of(context).dividerColor,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'إجمالي البيع الآجل',
                            style: TextStyle(
                              fontSize: 9,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                          Text(
                            Formatters.currencyIQD(summary['credit'] ?? 0),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: Theme.of(context).dividerColor,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'المجموع الكلي',
                            style: TextStyle(
                              fontSize: 9,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                          Text(
                            Formatters.currencyIQD(
                                (summary['installment'] ?? 0) +
                                    (summary['credit'] ?? 0)),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),

        // قائمة الأقساط
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            key: ValueKey('installments_${widget.refreshKey}'),
            future: widget.db.getInstallments(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final installments = snapshot.data!;
              final filteredInstallments = installments.where((installment) {
                // فلترة بالبحث
                final customerName =
                    installment['customer_name']?.toString().toLowerCase() ??
                        '';
                final phone =
                    installment['customer_phone']?.toString().toLowerCase() ??
                        '';
                final query = widget.searchQuery.toLowerCase();
                final matchesSearch =
                    customerName.contains(query) || phone.contains(query);

                if (!matchesSearch) {
                  return false;
                }

                // فلترة بالحالة
                final isPaid = (installment['paid'] as int) == 1;
                final dueDate = DateTime.parse(installment['due_date']);
                final isOverdue = dueDate.isBefore(DateTime.now()) && !isPaid;

                switch (_installmentFilter) {
                  case 'paid':
                    return isPaid;
                  case 'unpaid':
                    return !isPaid;
                  case 'overdue':
                    return isOverdue;
                  default:
                    return true;
                }
              }).where((installment) {
                // فلترة بالتاريخ
                if (_fromDate == null && _toDate == null) {
                  return true;
                }

                final dueDate = DateTime.parse(installment['due_date']);

                if (_fromDate != null && dueDate.isBefore(_fromDate!))
                  return false;
                if (_toDate != null && dueDate.isAfter(_toDate!)) return false;

                return true;
              }).toList();

              if (filteredInstallments.isEmpty) {
                return const Center(
                  child: Text('لا يوجد أقساط تطابق الفلترة المحددة'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: filteredInstallments.length,
                itemBuilder: (context, index) {
                  final installment = filteredInstallments[index];
                  return InstallmentCard(
                    context: context,
                    installment: installment,
                    db: widget.db,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
