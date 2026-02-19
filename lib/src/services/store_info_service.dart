import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/store_info.dart';

/// خدمة إدارة معلومات المتجر
class StoreInfoService {
  static const String _storeInfoKey = 'store_info';
  static StoreInfo? _cachedStoreInfo;

  /// الحصول على معلومات المتجر
  static Future<StoreInfo?> getStoreInfo() async {
    if (_cachedStoreInfo != null) {
      return _cachedStoreInfo;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final storeInfoJson = prefs.getString(_storeInfoKey);

      if (storeInfoJson != null) {
        final Map<String, dynamic> storeInfoMap = json.decode(storeInfoJson);
        _cachedStoreInfo = StoreInfo.fromMap(storeInfoMap);
        return _cachedStoreInfo;
      }
    } catch (e) {
      // تجاهل خطأ قراءة معلومات المتجر
    }

    return null;
  }

  /// حفظ معلومات المتجر
  static Future<bool> saveStoreInfo(StoreInfo storeInfo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storeInfoJson = json.encode(storeInfo.toMap());
      final success = await prefs.setString(_storeInfoKey, storeInfoJson);

      if (success) {
        _cachedStoreInfo = storeInfo;
      }

      return success;
    } catch (e) {
      // تجاهل خطأ حفظ معلومات المتجر
      return false;
    }
  }

  /// تحديث معلومات المتجر
  static Future<bool> updateStoreInfo(StoreInfo storeInfo) async {
    final updatedInfo = storeInfo.copyWith(
      updatedAt: DateTime.now(),
    );
    return await saveStoreInfo(updatedInfo);
  }

  /// حذف معلومات المتجر
  static Future<bool> deleteStoreInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.remove(_storeInfoKey);

      if (success) {
        _cachedStoreInfo = null;
      }

      return success;
    } catch (e) {
      // تجاهل خطأ حذف معلومات المتجر
      return false;
    }
  }

  /// التحقق من وجود معلومات المتجر
  static Future<bool> hasStoreInfo() async {
    final storeInfo = await getStoreInfo();
    return storeInfo != null && storeInfo.isValid;
  }

  /// الحصول على معلومات المتجر للطباعة
  static Future<Map<String, String>> getPrintInfo() async {
    final storeInfo = await getStoreInfo();
    if (storeInfo != null) {
      return storeInfo.getPrintInfo();
    }

    // إرجاع معلومات افتراضية إذا لم تكن موجودة
    return {
      'store_name': 'اسم المحل',
      'address': 'العنوان',
      'phone': 'رقم الهاتف',
      'description': 'وصف المحل',
    };
  }

  /// الحصول على معلومات المتجر للعرض
  static Future<Map<String, String>> getDisplayInfo() async {
    final storeInfo = await getStoreInfo();
    if (storeInfo != null) {
      return storeInfo.getDisplayInfo();
    }

    return {
      'اسم المحل': 'غير محدد',
      'العنوان': 'غير محدد',
      'الهاتف': 'غير محدد',
      'الوصف': 'غير محدد',
    };
  }

  /// إنشاء معلومات متجر افتراضية
  static Future<bool> createDefaultStoreInfo() async {
    final defaultInfo = StoreInfo.empty();
    return await saveStoreInfo(defaultInfo);
  }

  /// إعادة تعيين معلومات المتجر
  static Future<bool> resetStoreInfo() async {
    return await deleteStoreInfo();
  }

  /// تصدير معلومات المتجر
  static Future<Map<String, dynamic>?> exportStoreInfo() async {
    final storeInfo = await getStoreInfo();
    if (storeInfo != null) {
      return storeInfo.toMap();
    }
    return null;
  }

  /// استيراد معلومات المتجر
  static Future<bool> importStoreInfo(Map<String, dynamic> storeInfoMap) async {
    try {
      final storeInfo = StoreInfo.fromMap(storeInfoMap);
      return await saveStoreInfo(storeInfo);
    } catch (e) {
      // تجاهل خطأ استيراد معلومات المتجر
      return false;
    }
  }

  /// التحقق من صحة معلومات المتجر
  static Future<bool> validateStoreInfo(StoreInfo storeInfo) async {
    return storeInfo.isValid;
  }

  /// الحصول على إحصائيات معلومات المتجر
  static Future<Map<String, dynamic>> getStoreInfoStats() async {
    final storeInfo = await getStoreInfo();
    if (storeInfo == null) {
      return {
        'has_info': false,
        'completeness': 0.0,
        'missing_fields': [],
      };
    }

    final requiredFields = [
      'storeName',
      'address',
      'phone',
      'description',
    ];

    final optionalFields = [];

    final missingRequired = <String>[];
    final missingOptional = <String>[];

    for (final field in requiredFields) {
      final value = _getFieldValue(storeInfo, field);
      if (value == null || value.toString().isEmpty) {
        missingRequired.add(field);
      }
    }

    for (final field in optionalFields) {
      final value = _getFieldValue(storeInfo, field);
      if (value == null || value.toString().isEmpty) {
        missingOptional.add(field);
      }
    }

    final totalFields = requiredFields.length + optionalFields.length;
    final filledFields =
        totalFields - missingRequired.length - missingOptional.length;
    final completeness = (filledFields / totalFields) * 100;

    return {
      'has_info': true,
      'completeness': completeness,
      'missing_required': missingRequired,
      'missing_optional': missingOptional,
      'total_fields': totalFields,
      'filled_fields': filledFields,
    };
  }

  /// مساعدة للحصول على قيمة حقل
  static dynamic _getFieldValue(StoreInfo storeInfo, String fieldName) {
    switch (fieldName) {
      case 'storeName':
        return storeInfo.storeName;
      case 'address':
        return storeInfo.address;
      case 'phone':
        return storeInfo.phone;
      case 'description':
        return storeInfo.description;
      default:
        return null;
    }
  }

  /// مسح التخزين المؤقت
  static void clearCache() {
    _cachedStoreInfo = null;
  }
}
