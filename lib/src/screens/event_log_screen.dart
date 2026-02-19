import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/db/database_service.dart';
import '../utils/dark_mode_utils.dart';
import 'package:intl/intl.dart';
import '../widgets/empty_state.dart';

class EventLogScreen extends StatefulWidget {
  const EventLogScreen({super.key});

  @override
  State<EventLogScreen> createState() => _EventLogScreenState();
}

class _EventLogScreenState extends State<EventLogScreen> {
  List<Map<String, Object?>> _events = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  static const int _pageSize = 50;
  bool _hasMore = true;

  final Map<String, IconData> _eventTypeIcons = {
    'login': Icons.login,
    'logout': Icons.logout,
    'create': Icons.add_circle,
    'update': Icons.edit,
    'delete': Icons.delete,
    'quantity_change': Icons.inventory_2,
    'sale': Icons.point_of_sale,
    'payment': Icons.payment,
    'expense': Icons.receipt_long,
  };

  final Map<String, Color> _eventTypeColors = {
    'login': Colors.green,
    'logout': Colors.orange,
    'create': Colors.blue,
    'update': Colors.amber,
    'delete': Colors.red,
    'quantity_change': Colors.purple,
    'sale': Colors.teal,
    'payment': Colors.indigo,
    'expense': Colors.pink,
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // تأخير تحميل الأحداث حتى يكون context جاهزاً
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadEvents();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.9 &&
        !_isLoading &&
        _hasMore) {
      _loadMoreEvents();
    }
  }

  Future<void> _loadEvents({bool reset = false}) async {
    if (reset) {
      _currentPage = 0;
      _events.clear();
      _hasMore = true;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final db = context.read<DatabaseService>();

      final events = await db.getEventLogs(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );

      if (mounted) {
        setState(() {
          if (reset) {
            _events = events;
          } else {
            _events.addAll(events);
          }
          _hasMore = events.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الأحداث: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _loadMoreEvents() async {
    if (_isLoading || !_hasMore) return;
    _currentPage++;
    await _loadEvents();
  }

  Future<void> _deleteEvent(int eventId) async {
    try {
      final db = context.read<DatabaseService>();
      final success = await db.deleteEventLog(eventId);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف الحدث بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          // إعادة تحميل الأحداث
          _loadEvents(reset: true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل حذف الحدث'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حذف الحدث: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteAllDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: Directionality.of(context),
        child: AlertDialog(
          title: const Text('حذف جميع الأحداث'),
          content: const Text(
            'هل أنت متأكد من حذف جميع الأحداث؟\nهذه العملية لا يمكن التراجع عنها.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('حذف الكل'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteAllEvents();
    }
  }

  Future<void> _deleteAllEvents() async {
    try {
      final db = context.read<DatabaseService>();
      final success = await db.clearEventLogs();

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حذف جميع الأحداث بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          // إعادة تحميل الأحداث
          _loadEvents(reset: true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل حذف الأحداث'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حذف الأحداث: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getEventTypeLabel(String type) {
    const labels = {
      'login': 'تسجيل دخول',
      'logout': 'تسجيل خروج',
      'create': 'إضافة',
      'update': 'تعديل',
      'delete': 'حذف',
      'quantity_change': 'تغيير كمية',
      'sale': 'بيع',
      'payment': 'دفع',
      'expense': 'مصروف',
    };
    return labels[type] ?? type;
  }

  String _getEntityTypeLabel(String type) {
    const labels = {
      'product': 'منتج',
      'sale': 'بيع',
      'customer': 'عميل',
      'category': 'قسم',
      'user': 'مستخدم',
      'expense': 'مصروف',
    };
    return labels[type] ?? type;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الأحداث'),
        actions: [
          if (_events.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'حذف جميع الأحداث',
              onPressed: _showDeleteAllDialog,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: () => _loadEvents(reset: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(
                  color: DarkModeUtils.getBorderColor(context),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'إجمالي الأحداث',
                    '${_events.length}',
                    Icons.event_note,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    'اليوم',
                    '${_events.where((e) {
                      final date =
                          DateTime.tryParse(e['created_at'] as String? ?? '');
                      if (date == null) return false;
                      final now = DateTime.now();
                      return date.year == now.year &&
                          date.month == now.month &&
                          date.day == now.day;
                    }).length}',
                    Icons.today,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    'هذا الأسبوع',
                    '${_events.where((e) {
                      final date =
                          DateTime.tryParse(e['created_at'] as String? ?? '');
                      if (date == null) return false;
                      final weekAgo =
                          DateTime.now().subtract(const Duration(days: 7));
                      return date.isAfter(weekAgo);
                    }).length}',
                    Icons.date_range,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          // Events List
          Expanded(
            child: _events.isEmpty && !_isLoading
                ? EmptyState(
                    title: 'لا توجد أحداث',
                    icon: Icons.event_note,
                    message: 'لا توجد أحداث مسجلة',
                    actionLabel: 'تحديث',
                    onAction: () => _loadEvents(reset: true),
                  )
                : RefreshIndicator(
                    onRefresh: () => _loadEvents(reset: true),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(10),
                      itemCount: _events.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _events.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final event = _events[index];
                        return _buildEventCard(event, scheme, isDark);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: DarkModeUtils.getBorderColor(context),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 16),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(
      Map<String, Object?> event, ColorScheme scheme, bool isDark) {
    final eventType = event['event_type'] as String? ?? '';
    final entityType = event['entity_type'] as String? ?? '';
    final description = event['description'] as String? ?? '';
    final userRole = event['user_role'] as String?;
    final userId = event['user_id'] as int?;

    // الحصول على اسم المستخدم من user_name (من JOIN) أو username (من event_log)
    String userName =
        event['user_name'] as String? ?? event['username'] as String? ?? '';

    // إذا لم يكن هناك اسم مستخدم، استخدم user_role لعرض الدور
    if (userName.isEmpty || userName.trim().isEmpty || userName == 'null') {
      if (userRole != null && userRole.isNotEmpty && userRole != 'null') {
        switch (userRole.toLowerCase()) {
          case 'manager':
            userName = 'مدير';
            break;
          case 'supervisor':
            userName = 'مشرف';
            break;
          case 'employee':
            userName = 'موظف';
            break;
          default:
            userName = userRole; // عرض الدور كما هو إذا لم يكن معروفاً
        }
      } else if (userId != null) {
        // إذا كان هناك user_id لكن لا يوجد اسم، حاول الحصول على الاسم من قاعدة البيانات
        userName = 'مستخدم #$userId';
      } else {
        userName = 'غير معروف';
      }
    }

    final createdAt = event['created_at'] as String? ?? '';
    final details = event['details'] as String?;

    DateTime? date;
    try {
      date = DateTime.tryParse(createdAt);
    } catch (e) {
      // تجاهل خطأ تحليل التاريخ والاستمرار بالقيمة الافتراضية
    }

    final icon = _eventTypeIcons[eventType] ?? Icons.info;
    final color = _eventTypeColors[eventType] ?? scheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: details != null
              ? () =>
                  _showEventDetails(event, description, details, date, userName)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              description,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              _getEventTypeLabel(eventType),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.person,
                              size: 12,
                              color: scheme.onSurface.withOpacity(0.6)),
                          const SizedBox(width: 3),
                          Text(
                            userName,
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.category,
                              size: 12,
                              color: scheme.onSurface.withOpacity(0.6)),
                          const SizedBox(width: 3),
                          Text(
                            _getEntityTypeLabel(entityType),
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 12,
                              color: scheme.onSurface.withOpacity(0.6)),
                          const SizedBox(width: 3),
                          Text(
                            date != null
                                ? DateFormat('yyyy/MM/dd HH:mm').format(date)
                                : createdAt,
                            style: TextStyle(
                              fontSize: 10,
                              color: scheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (details != null)
                  Icon(
                    Icons.chevron_left,
                    size: 18,
                    color: scheme.onSurface.withOpacity(0.4),
                  ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  color: Colors.red.withOpacity(0.7),
                  tooltip: 'حذف الحدث',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showDeleteEventDialog(event['id'] as int),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteEventDialog(int eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: Directionality.of(context),
        child: AlertDialog(
          title: const Text('حذف الحدث'),
          content: const Text('هل أنت متأكد من حذف هذا الحدث؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await _deleteEvent(eventId);
    }
  }

  void _showEventDetails(Map<String, Object?> event, String description,
      String details, DateTime? date, String userName) {
    final eventType = event['event_type'] as String? ?? '';
    final color =
        _eventTypeColors[eventType] ?? Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: ui.TextDirection.rtl,
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.5,
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    textDirection: ui.TextDirection.rtl,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 22),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'إغلاق',
                      ),
                      const Text(
                        'تفاصيل الحدث',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.right,
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
                        _buildSimpleDetailRow('الوصف', description),
                        const SizedBox(height: 16),
                        _buildSimpleDetailRow('المستخدم', userName),
                        if (date != null) ...[
                          const SizedBox(height: 16),
                          _buildSimpleDetailRow('التاريخ والوقت',
                              DateFormat('yyyy/MM/dd HH:mm:ss').format(date)),
                        ],
                        const SizedBox(height: 16),
                        _buildSimpleDetailRow(
                            'نوع الحدث', _getEventTypeLabel(eventType)),
                        const SizedBox(height: 16),
                        _buildSimpleDetailRow(
                            'نوع الكيان',
                            _getEntityTypeLabel(
                                event['entity_type'] as String? ?? '')),
                        if (event['entity_id'] != null) ...[
                          const SizedBox(height: 16),
                          _buildSimpleDetailRow(
                              'معرف الكيان', '${event['entity_id']}'),
                        ],
                        if (details.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'التفاصيل الإضافية:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              details,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.6,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Footer
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    textDirection: ui.TextDirection.rtl,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('إغلاق'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleDetailRow(String label, String value) {
    return Row(
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
                  style: const TextStyle(
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
