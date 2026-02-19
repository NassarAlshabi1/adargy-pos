import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/error_messages.dart';
import '../widgets/error_display_widgets.dart';

/// خدمة إدارة ومعالجة الأخطاء
class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  factory ErrorHandlerService() => _instance;
  ErrorHandlerService._internal();

  /// معالج الأخطاء الرئيسي
  static Future<T?> handleError<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String? customErrorMessage,
    bool showSnackBar = true,
    bool showDialog = false,
    VoidCallback? onError,
    VoidCallback? onSuccess,
    String? retryLabel,
    String? dismissLabel,
  }) async {
    try {
      final result = await operation();
      onSuccess?.call();
      return result;
    } catch (error) {
      if (onError != null) {
        onError();
      }

      if (customErrorMessage != null) {
        _showCustomError(context, customErrorMessage, showSnackBar, showDialog);
      } else {
        _showError(
            context, error, showSnackBar, showDialog, retryLabel, dismissLabel);
      }

      return null;
    }
  }

  /// معالج الأخطاء للعمليات غير المتزامنة
  static void handleAsyncError(
    BuildContext context,
    Future<void> Function() operation, {
    String? customErrorMessage,
    bool showSnackBar = true,
    VoidCallback? onError,
    VoidCallback? onSuccess,
  }) {
    operation().then((_) {
      onSuccess?.call();
    }).catchError((error) {
      if (onError != null) {
        onError();
      }

      if (!context.mounted) {
        return;
      }

      if (customErrorMessage != null) {
        _showCustomError(context, customErrorMessage, showSnackBar, false);
      } else {
        _showError(context, error, showSnackBar, false, null, null);
      }
    });
  }

  /// معالج الأخطاء مع إعادة المحاولة
  static Future<T?> handleErrorWithRetry<T>(
    BuildContext context,
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
    String? retryLabel,
    String? dismissLabel,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        final result = await operation();
        return result;
      } catch (error) {
        attempts++;

        if (attempts >= maxRetries) {
          // عرض خطأ مع إمكانية إعادة المحاولة اليدوية
          ErrorDialog.show(
            context,
            error,
            onRetry: () => handleErrorWithRetry(
              context,
              operation,
              maxRetries: maxRetries,
              retryDelay: retryDelay,
              retryLabel: retryLabel,
              dismissLabel: dismissLabel,
            ),
            retryLabel: retryLabel,
            dismissLabel: dismissLabel,
          );
          return null;
        }

        // انتظار قبل إعادة المحاولة
        await Future.delayed(retryDelay);
      }
    }

    return null;
  }

  /// عرض خطأ مخصص
  static void _showCustomError(
    BuildContext context,
    String message,
    bool showSnackBar,
    bool showDialog,
  ) {
    final errorInfo = ErrorInfo(
      title: 'خطأ',
      message: message,
      solution: '',
      type: ErrorType.error,
    );

    if (showDialog) {
      ErrorDialog.show(
        context,
        errorInfo,
        dismissLabel: 'إغلاق',
      );
    } else if (showSnackBar) {
      ErrorSnackBar.show(context, errorInfo);
    }
  }

  /// عرض خطأ مع تحليل
  static void _showError(
    BuildContext context,
    dynamic error,
    bool showSnackBar,
    bool showDialog,
    String? retryLabel,
    String? dismissLabel,
  ) {
    if (showDialog) {
      ErrorDialog.show(
        context,
        error,
        retryLabel: retryLabel,
        dismissLabel: dismissLabel,
      );
    } else if (showSnackBar) {
      ErrorSnackBar.show(context, error);
    }
  }

  /// تسجيل الخطأ للتحليل
  static void logError(dynamic error,
      {String? context, Map<String, dynamic>? additionalInfo}) {
    final timestamp = DateTime.now().toIso8601String();
    final errorInfo = ErrorMessages.analyzeError(error);

    // في الإنتاج، يمكن إرسال هذا إلى خدمة تحليل الأخطاء
    // في وضع التطوير، نطبع المعلومات للمساعدة في التصحيح
    if (kDebugMode) {
      debugPrint('Error logged at $timestamp');
      debugPrint('Context: ${context ?? 'Unknown'}');
      debugPrint('Error type: ${errorInfo.type.name}');
      debugPrint('Error title: ${errorInfo.title}');
      debugPrint('Error message: ${errorInfo.message}');
      if (additionalInfo != null && additionalInfo.isNotEmpty) {
        debugPrint('Additional info: $additionalInfo');
      }
    }

    // يمكن استخدام logEntry في المستقبل لإرسال البيانات إلى خدمة تحليل الأخطاء
    // final logEntry = {
    //   'timestamp': timestamp,
    //   'context': context ?? 'Unknown',
    //   'error_type': errorInfo.type.name,
    //   'error_title': errorInfo.title,
    //   'error_message': errorInfo.message,
    //   'raw_error': error.toString(),
    //   'additional_info': additionalInfo ?? {},
    // };
  }

  /// معالج الأخطاء للعمليات الحرجة
  static Future<bool> handleCriticalOperation(
    BuildContext context,
    Future<void> Function() operation, {
    String? operationName,
    bool showProgressDialog = true,
  }) async {
    if (showProgressDialog) {
      if (!context.mounted) {
        return false;
      }
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  operationName ?? 'جاري المعالجة...',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    try {
      await operation();

      if (showProgressDialog && context.mounted) {
        Navigator.of(context).pop();
      }

      return true;
    } catch (error) {
      if (showProgressDialog && context.mounted) {
        Navigator.of(context).pop();
      }

      logError(error, context: operationName ?? 'Critical Operation');

      if (context.mounted) {
        ErrorDialog.show(
          context,
          error,
          dismissLabel: 'إغلاق',
        );
      }

      return false;
    }
  }

  /// التحقق من صحة البيانات مع رسائل خطأ واضحة
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName مطلوب';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'تنسيق البريد الإلكتروني غير صحيح';
    }

    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'رقم الهاتف مطلوب';
    }

    final phoneRegex = RegExp(r'^[0-9+\-\s\(\)]{7,15}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'تنسيق رقم الهاتف غير صحيح';
    }

    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'المبلغ مطلوب';
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'المبلغ يجب أن يكون رقماً';
    }

    if (amount <= 0) {
      return 'المبلغ يجب أن يكون أكبر من صفر';
    }

    return null;
  }

  static String? validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'الكمية مطلوبة';
    }

    final quantity = int.tryParse(value);
    if (quantity == null) {
      return 'الكمية يجب أن تكون رقماً صحيحاً';
    }

    if (quantity <= 0) {
      return 'الكمية يجب أن تكون أكبر من صفر';
    }

    return null;
  }
}
