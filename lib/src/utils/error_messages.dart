import 'package:flutter/material.dart';

/// نظام رسائل الخطأ المحسن للمستخدم
/// يوفر رسائل واضحة ومفيدة للمستخدم مع إرشادات للحل
class ErrorMessages {
  /// رسائل خطأ قاعدة البيانات
  static const Map<String, ErrorInfo> databaseErrors = {
    'database_locked': ErrorInfo(
      title: 'قاعدة البيانات قيد الاستخدام',
      message:
          'يبدو أن قاعدة البيانات قيد الاستخدام من قبل عملية أخرى. يرجى المحاولة مرة أخرى بعد بضع ثوانٍ.',
      solution: 'انتظر قليلاً ثم أعد المحاولة',
      type: ErrorType.warning,
    ),
    'no_such_table': ErrorInfo(
      title: 'خطأ في هيكل قاعدة البيانات',
      message:
          'حدث خطأ في هيكل قاعدة البيانات. سيتم إعادة إنشاء الجداول المطلوبة.',
      solution: 'سيتم إصلاح المشكلة تلقائياً',
      type: ErrorType.error,
    ),
    'disk_io_error': ErrorInfo(
      title: 'خطأ في القرص',
      message: 'حدث خطأ في القرص أو مساحة التخزين. تحقق من المساحة المتاحة.',
      solution: 'حرر مساحة في القرص أو تحقق من حالة القرص الصلب',
      type: ErrorType.critical,
    ),
    'constraint_failed': ErrorInfo(
      title: 'خطأ في البيانات المدخلة',
      message: 'البيانات المدخلة تتعارض مع القيود المحددة في قاعدة البيانات.',
      solution: 'تحقق من صحة البيانات المدخلة وأعد المحاولة',
      type: ErrorType.error,
    ),
  };

  /// رسائل خطأ الشبكة
  static const Map<String, ErrorInfo> networkErrors = {
    'connection_timeout': ErrorInfo(
      title: 'انتهت مهلة الاتصال',
      message: 'فشل الاتصال بالخادم. تحقق من اتصال الإنترنت.',
      solution: 'تحقق من اتصال الإنترنت وأعد المحاولة',
      type: ErrorType.warning,
    ),
    'server_error': ErrorInfo(
      title: 'خطأ في الخادم',
      message: 'حدث خطأ في الخادم. يرجى المحاولة لاحقاً.',
      solution: 'انتظر قليلاً ثم أعد المحاولة',
      type: ErrorType.error,
    ),
  };

  /// رسائل خطأ الملفات
  static const Map<String, ErrorInfo> fileErrors = {
    'file_not_found': ErrorInfo(
      title: 'الملف غير موجود',
      message: 'الملف المطلوب غير موجود أو تم نقله.',
      solution: 'تحقق من مسار الملف أو أعد إنشاءه',
      type: ErrorType.error,
    ),
    'permission_denied': ErrorInfo(
      title: 'رفض الوصول',
      message: 'ليس لديك صلاحية للوصول إلى هذا الملف.',
      solution: 'تحقق من صلاحيات الملف أو قم بتشغيل التطبيق كمدير',
      type: ErrorType.error,
    ),
    'disk_full': ErrorInfo(
      title: 'القرص ممتلئ',
      message: 'لا توجد مساحة كافية في القرص لحفظ الملف.',
      solution: 'حرر مساحة في القرص الصلب',
      type: ErrorType.critical,
    ),
  };

  /// رسائل خطأ التحقق من صحة البيانات
  static const Map<String, ErrorInfo> validationErrors = {
    'required_field': ErrorInfo(
      title: 'حقل مطلوب',
      message: 'يرجى ملء جميع الحقول المطلوبة.',
      solution: 'املأ الحقول المميزة بعلامة (*)',
      type: ErrorType.warning,
    ),
    'invalid_format': ErrorInfo(
      title: 'تنسيق غير صحيح',
      message: 'تنسيق البيانات المدخلة غير صحيح.',
      solution: 'تحقق من تنسيق البيانات المدخلة',
      type: ErrorType.warning,
    ),
    'duplicate_entry': ErrorInfo(
      title: 'بيانات مكررة',
      message: 'البيانات المدخلة موجودة مسبقاً في النظام.',
      solution: 'غير البيانات أو استخدم بيانات مختلفة',
      type: ErrorType.warning,
    ),
    'invalid_amount': ErrorInfo(
      title: 'مبلغ غير صحيح',
      message: 'المبلغ المدخل غير صحيح أو أقل من المسموح.',
      solution: 'أدخل مبلغاً صحيحاً أكبر من صفر',
      type: ErrorType.warning,
    ),
  };

  /// رسائل خطأ النظام
  static const Map<String, ErrorInfo> systemErrors = {
    'memory_insufficient': ErrorInfo(
      title: 'ذاكرة غير كافية',
      message: 'الذاكرة المتاحة غير كافية لتنفيذ العملية.',
      solution: 'أغلق التطبيقات الأخرى أو أعد تشغيل الجهاز',
      type: ErrorType.critical,
    ),
    'license_expired': ErrorInfo(
      title: 'انتهت صلاحية الترخيص',
      message: 'انتهت صلاحية ترخيص التطبيق. يرجى تجديد الترخيص.',
      solution: 'اتصل بالدعم الفني لتجديد الترخيص',
      type: ErrorType.critical,
    ),
    'device_mismatch': ErrorInfo(
      title: 'عدم تطابق الجهاز',
      message: 'الترخيص غير متوافق مع هذا الجهاز.',
      solution: 'اتصل بالدعم الفني لحل المشكلة',
      type: ErrorType.critical,
    ),
  };

  /// الحصول على معلومات الخطأ حسب النوع
  static ErrorInfo getErrorInfo(String errorType, String errorCode) {
    switch (errorType) {
      case 'database':
        return databaseErrors[errorCode] ?? _getDefaultError(errorCode);
      case 'network':
        return networkErrors[errorCode] ?? _getDefaultError(errorCode);
      case 'file':
        return fileErrors[errorCode] ?? _getDefaultError(errorCode);
      case 'validation':
        return validationErrors[errorCode] ?? _getDefaultError(errorCode);
      case 'system':
        return systemErrors[errorCode] ?? _getDefaultError(errorCode);
      default:
        return _getDefaultError(errorCode);
    }
  }

  /// تحليل الخطأ وإرجاع معلومات مناسبة
  static ErrorInfo analyzeError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // تحليل أخطاء قاعدة البيانات
    if (errorString.contains('database is locked')) {
      return databaseErrors['database_locked']!;
    } else if (errorString.contains('no such table')) {
      return databaseErrors['no_such_table']!;
    } else if (errorString.contains('disk i/o error')) {
      return databaseErrors['disk_io_error']!;
    } else if (errorString.contains('constraint failed')) {
      return databaseErrors['constraint_failed']!;
    }

    // تحليل أخطاء الشبكة
    else if (errorString.contains('connection timeout')) {
      return networkErrors['connection_timeout']!;
    } else if (errorString.contains('server error')) {
      return networkErrors['server_error']!;
    }

    // تحليل أخطاء الملفات
    else if (errorString.contains('file not found')) {
      return fileErrors['file_not_found']!;
    } else if (errorString.contains('permission denied')) {
      return fileErrors['permission_denied']!;
    } else if (errorString.contains('disk full')) {
      return fileErrors['disk_full']!;
    }

    // تحليل أخطاء النظام
    else if (errorString.contains('memory')) {
      return systemErrors['memory_insufficient']!;
    } else if (errorString.contains('license')) {
      return systemErrors['license_expired']!;
    }

    // خطأ افتراضي
    return _getDefaultError(errorString);
  }

  /// رسالة خطأ افتراضية
  static ErrorInfo _getDefaultError(String errorCode) {
    return ErrorInfo(
      title: 'حدث خطأ غير متوقع',
      message: 'حدث خطأ أثناء تنفيذ العملية. يرجى المحاولة مرة أخرى.',
      solution: 'إذا استمر الخطأ، اتصل بالدعم الفني',
      type: ErrorType.error,
    );
  }
}

/// معلومات الخطأ
class ErrorInfo {
  final String title;
  final String message;
  final String solution;
  final ErrorType type;

  const ErrorInfo({
    required this.title,
    required this.message,
    required this.solution,
    required this.type,
  });
}

/// أنواع الأخطاء
enum ErrorType {
  warning, // تحذير - يمكن للمستخدم الاستمرار
  error, // خطأ - يتطلب إجراء من المستخدم
  critical, // خطأ حرج - يمنع استخدام التطبيق
}

/// ألوان الأخطاء
extension ErrorTypeColors on ErrorType {
  Color get color {
    switch (this) {
      case ErrorType.warning:
        return const Color(0xFFFF9800); // برتقالي
      case ErrorType.error:
        return const Color(0xFFE53935); // أحمر
      case ErrorType.critical:
        return const Color(0xFFD32F2F); // أحمر داكن
    }
  }

  IconData get icon {
    switch (this) {
      case ErrorType.warning:
        return Icons.warning_amber;
      case ErrorType.error:
        return Icons.error;
      case ErrorType.critical:
        return Icons.error_outline;
    }
  }
}
