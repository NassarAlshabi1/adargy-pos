import 'package:flutter/material.dart';
import '../utils/error_messages.dart';

/// مكونات عرض الأخطاء المحسنة للمستخدم

/// عرض خطأ في SnackBar محسن
class ErrorSnackBar {
  static void show(
    BuildContext context,
    dynamic error, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onActionPressed,
    String? actionLabel,
  }) {
    final errorInfo = ErrorMessages.analyzeError(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  errorInfo.type.icon,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorInfo.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              errorInfo.message,
              style: const TextStyle(fontSize: 12),
            ),
            if (errorInfo.solution.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '💡 ${errorInfo.solution}',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: errorInfo.type.color,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: onActionPressed != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onActionPressed,
              )
            : null,
      ),
    );
  }
}

/// عرض خطأ في حوار منفصل
class ErrorDialog {
  static Future<void> show(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
    String? retryLabel,
    String? dismissLabel,
  }) {
    final errorInfo = ErrorMessages.analyzeError(error);

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                errorInfo.type.icon,
                color: errorInfo.type.color,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  errorInfo.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: errorInfo.type.color,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                errorInfo.message,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (errorInfo.solution.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: errorInfo.type.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: errorInfo.type.color.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: errorInfo.type.color,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorInfo.solution,
                          style: TextStyle(
                            fontSize: 13,
                            color: errorInfo.type.color.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (onDismiss != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onDismiss();
                },
                child: Text(
                  dismissLabel ?? 'إغلاق',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
              ),
            if (onRetry != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: errorInfo.type.color,
                  foregroundColor: Colors.white,
                ),
                child: Text(retryLabel ?? 'إعادة المحاولة'),
              ),
          ],
        ),
      ),
    );
  }
}

/// مكون عرض خطأ في الصفحة
class ErrorWidget extends StatelessWidget {
  final dynamic error;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final Widget? customIcon;
  final String? customTitle;

  const ErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.retryLabel,
    this.customIcon,
    this.customTitle,
  });

  @override
  Widget build(BuildContext context) {
    final errorInfo = ErrorMessages.analyzeError(error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: errorInfo.type.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: customIcon ??
                  Icon(
                    errorInfo.type.icon,
                    size: 64,
                    color: errorInfo.type.color,
                  ),
            ),
            const SizedBox(height: 24),
            Text(
              customTitle ?? errorInfo.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: errorInfo.type.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              errorInfo.message,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (errorInfo.solution.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: errorInfo.type.color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: errorInfo.type.color.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: errorInfo.type.color,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorInfo.solution,
                        style: TextStyle(
                          fontSize: 13,
                          color: errorInfo.type.color.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel ?? 'إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: errorInfo.type.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// مكون عرض تحميل مع إمكانية الخطأ
class LoadingWithErrorWidget extends StatelessWidget {
  final bool isLoading;
  final dynamic error;
  final Widget child;
  final VoidCallback? onRetry;
  final String? loadingMessage;

  const LoadingWithErrorWidget({
    super.key,
    required this.isLoading,
    required this.error,
    required this.child,
    this.onRetry,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            if (loadingMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                loadingMessage!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (error != null) {
      return ErrorWidget(
        error: error,
        onRetry: onRetry,
      );
    }

    return child;
  }
}
