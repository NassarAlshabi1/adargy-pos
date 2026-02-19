// ignore_for_file: use_build_context_synchronously

import 'dart:ui' as ui show TextDirection;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/db/database_service.dart';
import '../services/auth/auth_provider.dart';
import '../models/user_model.dart';
import '../utils/format.dart';

/// صفحة المرتجعات - تصميم بسيط وسهل
class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  String _searchQuery = '';
  String _selectedStatus = 'all'; // all, pending, completed, cancelled

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.hasPermission(UserPermission.manageSales)) {
      return Scaffold(
        appBar: AppBar(title: const Text('المرتجعات')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('ليس لديك صلاحية للوصول إلى هذه الصفحة'),
            ],
          ),
        ),
      );
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: const Text('المرتجعات'),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('إضافة مرتجع'),
              onPressed: () => _showAddReturnDialog(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              color: Colors.blue,
              onPressed: _refresh,
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: Column(
            children: [
              _buildFilterSection(),
              Expanded(child: _buildReturnsList()),
            ],
          ),
        ),
      ),
    );
  }

  /// قسم الفلترة والبحث
  Widget _buildFilterSection() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // البحث
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'بحث...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          // فلاتر الحالة
          Row(
            children: [
              Expanded(
                child: _buildStatusChip('all', 'الكل', Colors.grey),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusChip('pending', 'في الانتظار', Colors.blue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusChip('completed', 'مكتملة', Colors.green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusChip('cancelled', 'ملغاة', Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, String label, Color color) {
    final isSelected = _selectedStatus == status;
    return InkWell(
      onTap: () => setState(() => _selectedStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? color
                : Theme.of(context).colorScheme.outline.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? color
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  /// قائمة المرتجعات
  Widget _buildReturnsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: context.read<DatabaseService>().getReturns(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('خطأ: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          );
        }

        final returns = snapshot.data ?? [];
        final filteredReturns = _filterReturns(returns);

        if (filteredReturns.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_return,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4)),
                const SizedBox(height: 16),
                Text(
                  'لا توجد مرتجعات',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () => _showAddReturnDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة مرتجع'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filteredReturns.length,
          itemBuilder: (context, index) {
            return _ReturnItemCard(
              returnItem: filteredReturns[index],
              onTap: () => _showReturnDetails(filteredReturns[index]),
              onDelete: () => _deleteReturn(filteredReturns[index]),
              onStatusChange: (newStatus) =>
                  _updateReturnStatus(filteredReturns[index], newStatus),
            );
          },
        );
      },
    );
  }

  /// فلترة المرتجعات
  List<Map<String, dynamic>> _filterReturns(
      List<Map<String, dynamic>> returns) {
    var filtered = returns;

    // فلترة حسب الحالة
    if (_selectedStatus != 'all') {
      filtered = filtered.where((r) {
        final status = r['status']?.toString() ?? 'pending';
        return status == _selectedStatus;
      }).toList();
    }

    // فلترة حسب البحث
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((r) {
        final saleId = r['sale_id']?.toString().toLowerCase() ?? '';
        final customerName = r['customer_name']?.toString().toLowerCase() ?? '';
        return saleId.contains(query) || customerName.contains(query);
      }).toList();
    }

    return filtered;
  }

  /// حوار إضافة مرتجع
  Future<void> _showAddReturnDialog() async {
    await showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
            child: _AddReturnDialog(
              onReturnCreated: () {
                Navigator.pop(context);
                _refresh();
              },
            ),
          ),
        ),
      ),
    );
  }

  /// عرض تفاصيل المرتجع
  Future<void> _showReturnDetails(Map<String, dynamic> returnItem) async {
    final saleId = returnItem['sale_id'] as int?;
    if (saleId == null) {
      return;
    }

    try {
      final db = context.read<DatabaseService>();
      final saleItems = await db.getSaleItems(saleId);

      if (!mounted) {
        return;
      }

      showDialog(
        context: context,
        builder: (context) => Directionality(
          textDirection: ui.TextDirection.rtl,
          child: AlertDialog(
            title: Text('تفاصيل المرتجع #${returnItem['id']}'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDetailRow('الفاتورة', '#$saleId'),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'العميل',
                      returnItem['customer_name']?.toString() ?? 'عميل عام',
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'المبلغ',
                      Formatters.currencyIQD(
                        (returnItem['total_amount'] as num?)?.toDouble() ?? 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'الحالة',
                      _getStatusLabel(
                          returnItem['status']?.toString() ?? 'pending'),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'التاريخ',
                      returnItem['return_date']?.toString().substring(0, 10) ??
                          '',
                    ),
                    if (returnItem['notes'] != null &&
                        returnItem['notes'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'ملاحظات',
                        returnItem['notes'].toString(),
                      ),
                    ],
                    const Divider(height: 24),
                    Text(
                      'المنتجات',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...saleItems.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item['product_name']?.toString() ?? 'منتج',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              Text(
                                '${item['quantity']} × ${Formatters.currencyIQD((item['price'] as num?)?.toDouble() ?? 0)}',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6)),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(child: Text(value)),
      ],
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'في الانتظار';
      case 'completed':
        return 'مكتملة';
      case 'cancelled':
        return 'ملغاة';
      default:
        return 'غير معروف';
    }
  }

  /// تحديث حالة المرتجع
  Future<void> _updateReturnStatus(
      Map<String, dynamic> returnItem, String newStatus) async {
    final id = returnItem['id'] as int?;
    if (id == null) {
      return;
    }

    try {
      final auth = context.read<AuthProvider>();
      await context.read<DatabaseService>().updateReturnStatus(
            id: id,
            status: newStatus,
            userId: auth.currentUser?.id,
            username: auth.currentUser?.name,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تحديث الحالة إلى: ${_getStatusLabel(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// حذف مرتجع
  Future<void> _deleteReturn(Map<String, dynamic> returnItem) async {
    final id = returnItem['id'] as int?;
    if (id == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المرتجع'),
        content: const Text('هل أنت متأكد من حذف هذا المرتجع؟'),
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

    if (confirmed != true) {
      return;
    }

    try {
      await context.read<DatabaseService>().deleteReturn(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم الحذف بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// بطاقة عنصر المرتجع - تصميم بسيط
class _ReturnItemCard extends StatelessWidget {
  final Map<String, dynamic> returnItem;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(String) onStatusChange;

  const _ReturnItemCard({
    required this.returnItem,
    required this.onTap,
    required this.onDelete,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final saleId = returnItem['sale_id'] as int?;
    final amount = (returnItem['total_amount'] as num?)?.toDouble() ?? 0;
    final dateStr = returnItem['return_date']?.toString() ?? '';
    final customerName = returnItem['customer_name']?.toString() ?? 'عميل عام';
    final status = returnItem['status']?.toString() ?? 'pending';
    final date = dateStr.isNotEmpty && dateStr.length > 10
        ? dateStr.substring(0, 10)
        : dateStr;

    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الصف الأول: المعلومات الأساسية
            Row(
              children: [
                // أيقونة الحالة
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(status),
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // معلومات المرتجع
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'فاتورة #$saleId',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // المبلغ
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.currencyIQD(amount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 16),
            // الأزرار
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status != 'completed')
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    onSelected: (value) => onStatusChange(value),
                    itemBuilder: (context) => [
                      if (status != 'completed')
                        const PopupMenuItem(
                          value: 'completed',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green, size: 18),
                              SizedBox(width: 8),
                              Text('مكتملة'),
                            ],
                          ),
                        ),
                      if (status != 'cancelled')
                        const PopupMenuItem(
                          value: 'cancelled',
                          child: Row(
                            children: [
                              Icon(Icons.cancel, color: Colors.red, size: 18),
                              SizedBox(width: 8),
                              Text('إلغاء'),
                            ],
                          ),
                        ),
                      if (status != 'pending')
                        const PopupMenuItem(
                          value: 'pending',
                          child: Row(
                            children: [
                              Icon(Icons.hourglass_empty,
                                  color: Colors.blue, size: 18),
                              SizedBox(width: 8),
                              Text('في الانتظار'),
                            ],
                          ),
                        ),
                    ],
                  ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('التفاصيل'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('حذف'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'في الانتظار';
      case 'completed':
        return 'مكتملة';
      case 'cancelled':
        return 'ملغاة';
      default:
        return 'غير معروف';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
}

/// حوار إضافة مرتجع جديد
class _AddReturnDialog extends StatefulWidget {
  final VoidCallback onReturnCreated;

  const _AddReturnDialog({required this.onReturnCreated});

  @override
  State<_AddReturnDialog> createState() => _AddReturnDialogState();
}

class _AddReturnDialogState extends State<_AddReturnDialog> {
  int? _selectedSaleId;
  List<Map<String, dynamic>> _saleItems = [];
  final Map<int, int> _returnQuantities = {};
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.assignment_return, color: Colors.white),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'إرجاع منتجات',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSaleSelector(),
                if (_saleItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildProductsList(),
                  const SizedBox(height: 16),
                  _buildTotalCard(),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                    prefixIcon: const Icon(Icons.note),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        // Footer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _canCreateReturn() ? _createReturn : null,
                icon: const Icon(Icons.check),
                label: const Text('إنشاء'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaleSelector() {
    return FutureBuilder<List<Map<String, Object?>>>(
      future:
          context.read<DatabaseService>().getSalesHistory(sortDescending: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const Text('خطأ في تحميل الفواتير');
        }

        final sales = snapshot.data!;
        if (sales.isEmpty) {
          return const Text('لا توجد فواتير متاحة');
        }

        return DropdownButtonFormField<int>(
          decoration: InputDecoration(
            labelText: 'اختر الفاتورة',
            prefixIcon: const Icon(Icons.receipt),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: sales.map((sale) {
            final id = sale['id'] as int;
            final customerName =
                sale['customer_name']?.toString() ?? 'عميل عام';
            final total = (sale['total'] as num?)?.toDouble() ?? 0;
            return DropdownMenuItem(
              value: id,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'فاتورة #$id - $customerName',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    Formatters.currencyIQD(total),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (saleId) async {
            if (saleId != null) {
              await _loadSaleItems(saleId);
            }
          },
        );
      },
    );
  }

  Future<void> _loadSaleItems(int saleId) async {
    setState(() {
      _isLoading = true;
      _selectedSaleId = saleId;
      _returnQuantities.clear();
    });

    try {
      final items = await context.read<DatabaseService>().getSaleItems(saleId);
      setState(() {
        _saleItems = items;
        for (final item in items) {
          _returnQuantities[item['product_id'] as int] = 0;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildProductsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'المنتجات',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ..._saleItems.map((item) {
          final productId = item['product_id'] as int;
          final productName = item['product_name']?.toString() ?? 'منتج';
          final quantity = item['quantity'] as int;
          final price = (item['price'] as num?)?.toDouble() ?? 0;
          final returnQty = _returnQuantities[productId] ?? 0;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'المباع: $quantity | السعر: ${Formatters.currencyIQD(price)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('الكمية المرجعة: ',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            color: returnQty > 0 ? Colors.red : Colors.grey,
                            onPressed: returnQty > 0
                                ? () {
                                    setState(() {
                                      _returnQuantities[productId] =
                                          returnQty - 1;
                                    });
                                  }
                                : null,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '$returnQty / $quantity',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    returnQty > 0 ? Colors.orange : Colors.grey,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            color: returnQty < quantity
                                ? Colors.green
                                : Colors.grey,
                            onPressed: returnQty < quantity
                                ? () {
                                    setState(() {
                                      _returnQuantities[productId] =
                                          returnQty + 1;
                                    });
                                  }
                                : null,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (returnQty > 0) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('مبلغ الإرجاع:',
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(
                            Formatters.currencyIQD(returnQty * price),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTotalCard() {
    final total = _calculateTotal();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: total > 0
            ? Colors.orange.withOpacity(0.1)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: total > 0
              ? Colors.orange
              : Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_money,
              color: total > 0 ? Colors.orange : Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'المبلغ الإجمالي',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  Formatters.currencyIQD(total),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: total > 0 ? Colors.orange : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotal() {
    double total = 0;
    for (final item in _saleItems) {
      final productId = item['product_id'] as int;
      final returnQty = _returnQuantities[productId] ?? 0;
      if (returnQty > 0) {
        final price = (item['price'] as num?)?.toDouble() ?? 0;
        total += returnQty * price;
      }
    }
    return total;
  }

  bool _canCreateReturn() {
    if (_selectedSaleId == null || _saleItems.isEmpty) {
      return false;
    }
    return _returnQuantities.values.any((qty) => qty > 0);
  }

  Future<void> _createReturn() async {
    if (!_canCreateReturn()) {
      return;
    }

    final total = _calculateTotal();
    if (total <= 0) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد المرتجع'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المبلغ الإجمالي: ${Formatters.currencyIQD(total)}'),
            const SizedBox(height: 8),
            Text(
                'عدد المنتجات: ${_returnQuantities.values.where((q) => q > 0).length}'),
            const SizedBox(height: 16),
            const Text('سيتم:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('• إرجاع المنتجات للمخزون'),
            const Text('• تحديث ديون العميل (إن وجدت)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final db = context.read<DatabaseService>();
      final auth = context.read<AuthProvider>();

      final returnItems = <Map<String, dynamic>>[];
      for (final item in _saleItems) {
        final productId = item['product_id'] as int;
        final returnQty = _returnQuantities[productId] ?? 0;
        if (returnQty > 0) {
          returnItems.add({
            'product_id': productId,
            'quantity': returnQty,
            'price': (item['price'] as num?)?.toDouble() ?? 0,
          });
        }
      }

      await db.createReturn(
        saleId: _selectedSaleId!,
        totalAmount: total,
        returnItems: returnItems,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        status: 'pending',
        userId: auth.currentUser?.id,
        username: auth.currentUser?.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء المرتجع بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onReturnCreated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
