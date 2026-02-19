import 'package:flutter/foundation.dart';
import 'db/database_service.dart';

/// مزود حالة سجل المبيعات
/// يوفّر ترشيحًا حسب التاريخ والنوع والنص والفرز تصاعديًا/تنازليًا
class SalesHistoryViewModel extends ChangeNotifier {
  SalesHistoryViewModel(this._databaseService);

  final DatabaseService _databaseService;

  /// نص البحث
  String _query = '';
  String get query => _query;

  /// نوع العملية (إن وجد)
  String _type = '';
  String get type => _type;

  /// نطاق التاريخ (من/إلى)
  DateTime? _fromDate;
  DateTime? get fromDate => _fromDate;

  DateTime? _toDate;
  DateTime? get toDate => _toDate;

  /// حالة التحميل وأي خطأ حدث
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Object? _error;
  Object? get error => _error;

  /// النتائج المحمّلة من قاعدة البيانات
  List<Map<String, Object?>> _sales = const [];
  List<Map<String, Object?>> get sales => _sales;

  /// اتجاه الفرز (افتراضيًا تنازلي)
  bool _sortDescending = true;
  bool get sortDescending => _sortDescending;

  /// تحميل سجل المبيعات اعتمادًا على معايير الترشيح الحالية
  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final sales = await _databaseService.getSalesHistory(
        from: _fromDate,
        to: _toDate,
        type: _type.isEmpty ? null : _type,
        query: _query.isEmpty ? null : _query,
        sortDescending: _sortDescending,
      );
      _sales = sales;
    } catch (e) {
      // حفظ الخطأ لاستخدامه في الواجهة
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// تحديث نص البحث وإعادة التحميل
  void updateQuery(String value) {
    _query = value;
    load();
  }

  /// تحديث النوع وإعادة التحميل
  void updateType(String value) {
    _type = value;
    load();
  }

  /// تحديث نطاق التاريخ وإعادة التحميل
  void updateDateRange({DateTime? from, DateTime? to}) {
    _fromDate = from;
    _toDate = to;
    load();
  }

  /// تغيير اتجاه الفرز وإعادة التحميل
  void toggleSort() {
    _sortDescending = !_sortDescending;
    load();
  }
}
