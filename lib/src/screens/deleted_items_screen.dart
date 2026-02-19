// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../services/db/database_service.dart';
import '../utils/format.dart';

class DeletedItemsScreen extends StatefulWidget {
  const DeletedItemsScreen({super.key});

  @override
  State<DeletedItemsScreen> createState() => _DeletedItemsScreenState();
}

class _DeletedItemsScreenState extends State<DeletedItemsScreen> {
  String _selectedFilter = 'all';
  List<Map<String, dynamic>> _deletedItems = [];
  Map<String, int> _itemsCount = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeletedItems();
  }

  Future<void> _loadDeletedItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = DatabaseService();
      await db.initialize();

      final items = await db.getDeletedItems(
        entityType: _selectedFilter == 'all' ? null : _selectedFilter,
      );
      final counts = await db.getDeletedItemsCount();

      setState(() {
        _deletedItems = items;
        _itemsCount = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل المحذوفات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _refreshData() {
    _loadDeletedItems();
  }

  String? _getRoleDisplayName(String? role) {
    switch (role) {
      case 'manager':
        return 'مدير';
      case 'supervisor':
        return 'مشرف';
      case 'employee':
        return 'موظف';
      default:
        return null;
    }
  }

  String _getEntityTypeName(String type) {
    switch (type) {
      case 'customer':
        return 'عميل';
      case 'sale':
        return 'بيع';
      case 'installment':
        return 'قسط';
      case 'payment':
        return 'دفعة';
      case 'product':
        return 'منتج';
      case 'expense':
        return 'مصروف';
      case 'supplier':
        return 'مورد';
      case 'supplier_payment':
        return 'دفعة مورد';
      default:
        return type;
    }
  }

  IconData _getEntityTypeIcon(String type) {
    switch (type) {
      case 'customer':
        return Icons.person;
      case 'sale':
        return Icons.shopping_cart;
      case 'installment':
        return Icons.schedule;
      case 'payment':
        return Icons.payment;
      case 'product':
        return Icons.inventory;
      case 'expense':
        return Icons.receipt;
      case 'supplier':
        return Icons.business;
      case 'supplier_payment':
        return Icons.payment;
      default:
        return Icons.delete;
    }
  }

  Color _getEntityTypeColor(String type) {
    switch (type) {
      case 'customer':
        return Colors.blue;
      case 'sale':
        return Colors.green;
      case 'installment':
        return Colors.orange;
      case 'payment':
        return Colors.teal;
      case 'product':
        return Colors.purple;
      case 'expense':
        return Colors.red;
      case 'supplier':
        return Colors.indigo;
      case 'supplier_payment':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سلة المحذوفات'),
          actions: [
            if (_deletedItems.isNotEmpty)
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete_all') {
                    _showDeleteAllDialog();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete_all',
                    child: Row(
                      children: [
                        Icon(Icons.delete_forever, color: Colors.red),
                        SizedBox(width: 8),
                        Text('حذف الكل نهائياً'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: Column(
          children: [
            // فلتر الأنواع
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    _buildFilterChip('all', 'الكل',
                        _itemsCount.values.fold(0, (a, b) => a + b)),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        'customer', 'عملاء', _itemsCount['customer'] ?? 0),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        'sale', 'مبيعات', _itemsCount['sale'] ?? 0),
                    const SizedBox(width: 8),
                    _buildFilterChip('installment', 'أقساط',
                        _itemsCount['installment'] ?? 0),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        'payment', 'مدفوعات', _itemsCount['payment'] ?? 0),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        'product', 'منتجات', _itemsCount['product'] ?? 0),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        'expense', 'مصروفات', _itemsCount['expense'] ?? 0),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                        'supplier', 'موردون', _itemsCount['supplier'] ?? 0),
                    const SizedBox(width: 8),
                    _buildFilterChip('supplier_payment', 'دفعات موردين',
                        _itemsCount['supplier_payment'] ?? 0),
                  ],
                ),
              ),
            ),
            const Divider(),
            // قائمة المحذوفات
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _deletedItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'لا توجد عناصر محذوفة',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadDeletedItems,
                          child: ListView.builder(
                            itemCount: _deletedItems.length,
                            itemBuilder: (context, index) {
                              final item = _deletedItems[index];
                              return _buildDeletedItemCard(item);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, int count) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
        _loadDeletedItems();
      },
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildDeletedItemCard(Map<String, dynamic> item) {
    final entityType = item['entity_type'] as String;
    final originalData = item['original_data'] as Map<String, dynamic>;
    final deletedAt = DateTime.tryParse(item['deleted_at'] as String);

    // الحصول على معلومات المستخدم
    // التحقق من القيم الفارغة أو null
    final userName = (item['user_name'] as String?)?.trim();
    final userUsername = (item['user_username'] as String?)?.trim();
    final userRole = (item['user_role'] as String?)?.trim();
    final deletedByName = (item['deleted_by_name'] as String?)?.trim();
    final deletedByUsername = (item['deleted_by_username'] as String?)?.trim();

    // استخدام معلومات المستخدم من جدول users أولاً، ثم المعلومات المحفوظة
    String displayName = 'غير معروف';
    if (userName != null && userName.isNotEmpty) {
      displayName = userName;
    } else if (deletedByName != null && deletedByName.isNotEmpty) {
      displayName = deletedByName;
    } else if (userUsername != null && userUsername.isNotEmpty) {
      displayName = userUsername;
    } else if (deletedByUsername != null && deletedByUsername.isNotEmpty) {
      displayName = deletedByUsername;
    }

    final roleDisplayName = _getRoleDisplayName(userRole);

    // التحقق من أن الاسم لا يحتوي بالفعل على نوع المستخدم
    bool nameContainsRole = false;
    if (roleDisplayName != null && roleDisplayName.isNotEmpty) {
      // التحقق من أن الاسم يحتوي على نوع المستخدم بين قوسين
      nameContainsRole = displayName.contains('($roleDisplayName)') ||
          displayName.contains('($roleDisplayName)') ||
          displayName == roleDisplayName;
    }

    final deletedBy = (roleDisplayName != null &&
            roleDisplayName.isNotEmpty &&
            !nameContainsRole)
        ? '$displayName ($roleDisplayName)'
        : displayName;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getEntityTypeColor(entityType).withOpacity(0.2),
          child: Icon(
            _getEntityTypeIcon(entityType),
            color: _getEntityTypeColor(entityType),
          ),
        ),
        title: Text(
          _getEntityTypeName(entityType),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(_buildItemDescription(entityType, originalData)),
            const SizedBox(height: 4),
            Text(
              'حذف بواسطة: $deletedBy',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            if (deletedAt != null)
              Text(
                'تاريخ الحذف: ${DateFormat('yyyy/MM/dd HH:mm').format(deletedAt)}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.restore, color: Colors.green),
              onPressed: () => _showRestoreDialog(item),
              tooltip: 'استرجاع',
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: () => _showPermanentDeleteDialog(item),
              tooltip: 'حذف نهائي',
            ),
          ],
        ),
      ),
    );
  }

  String _buildItemDescription(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'customer':
        return 'الاسم: ${data['name'] ?? 'غير محدد'}';
      case 'sale':
        return 'المبلغ: ${Formatters.currencyIQD((data['total'] as num?)?.toDouble() ?? 0.0)}';
      case 'installment':
        return 'المبلغ: ${Formatters.currencyIQD((data['amount'] as num?)?.toDouble() ?? 0.0)}';
      case 'payment':
        return 'المبلغ: ${Formatters.currencyIQD((data['amount'] as num?)?.toDouble() ?? 0.0)}';
      case 'product':
        return 'الاسم: ${data['name'] ?? 'غير محدد'}';
      case 'expense':
        return 'المبلغ: ${Formatters.currencyIQD((data['amount'] as num?)?.toDouble() ?? 0.0)}';
      case 'supplier':
        return 'الاسم: ${data['name'] ?? 'غير محدد'}';
      case 'supplier_payment':
        return 'المبلغ: ${Formatters.currencyIQD((data['amount'] as num?)?.toDouble() ?? 0.0)}';
      default:
        return 'معرف: ${data['id'] ?? 'غير محدد'}';
    }
  }

  void _showRestoreDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('استرجاع العنصر'),
          content: Text(
            'هل أنت متأكد من استرجاع ${_getEntityTypeName(item['entity_type'] as String)}؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _restoreItem(item['id'] as int);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('استرجاع'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPermanentDeleteDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف نهائي'),
          content: Text(
            'هل أنت متأكد من الحذف النهائي ل${_getEntityTypeName(item['entity_type'] as String)}؟\n\n'
            'لا يمكن التراجع عن هذه العملية.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _permanentlyDeleteItem(item['id'] as int);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('حذف نهائي'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف الكل نهائياً'),
          content: Text(
            'هل أنت متأكد من حذف جميع العناصر المحذوفة نهائياً؟\n\n'
            'سيتم حذف ${_deletedItems.length} عنصر.\n'
            'لا يمكن التراجع عن هذه العملية.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _permanentlyDeleteAll();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('حذف الكل'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _restoreItem(int deletedItemId) async {
    try {
      final db = DatabaseService();
      await db.initialize();
      await db.restoreDeletedItem(deletedItemId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم استرجاع العنصر بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        _refreshData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الاسترجاع: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _permanentlyDeleteItem(int deletedItemId) async {
    try {
      final db = DatabaseService();
      await db.initialize();
      await db.permanentlyDeleteItem(deletedItemId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم الحذف النهائي بنجاح'),
            backgroundColor: Colors.orange,
          ),
        );
        _refreshData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحذف: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _permanentlyDeleteAll() async {
    try {
      final db = DatabaseService();
      await db.initialize();
      final count = await db.permanentlyDeleteAllItems(
        entityType: _selectedFilter == 'all' ? null : _selectedFilter,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف $count عنصر نهائياً'),
            backgroundColor: Colors.orange,
          ),
        );
        _refreshData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحذف: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
