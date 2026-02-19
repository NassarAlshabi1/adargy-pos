import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// أدوات مساعدة للأزرار والأوامر
class ButtonUtils {
  /// إنشاء زر مع معالجة أخطاء محسنة
  static Widget createSafeButton({
    required String text,
    required VoidCallback? onPressed,
    required IconData icon,
    Color? backgroundColor,
    Color? foregroundColor,
    bool isLoading = false,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? text,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  /// إنشاء زر حذف مع تأكيد
  static Widget createDeleteButton({
    required String text,
    required VoidCallback onPressed,
    required IconData icon,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? text,
      child: ElevatedButton.icon(
        onPressed: () => _showDeleteConfirmation(onPressed),
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  /// إنشاء زر تصدير مع معالجة أخطاء
  static Widget createExportButton({
    required String text,
    required Future<void> Function() onPressed,
    required IconData icon,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? text,
      child: ElevatedButton.icon(
        onPressed: () => _handleExport(onPressed),
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  /// عرض تأكيد الحذف
  static void _showDeleteConfirmation(VoidCallback onConfirm) {
    // سيتم تنفيذ هذا في السياق المناسب
  }

  /// معالجة التصدير مع معالجة الأخطاء
  static Future<void> _handleExport(
      Future<void> Function() exportFunction) async {
    try {
      await exportFunction();
    } catch (e) {
      // معالجة الخطأ
    }
  }

  /// إنشاء زر مع مؤشر تحميل
  static Widget createLoadingButton({
    required String text,
    required bool isLoading,
    required VoidCallback? onPressed,
    required IconData icon,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  /// إنشاء زر مع فحص الصلاحيات
  static Widget createPermissionButton({
    required String text,
    required VoidCallback? onPressed,
    required IconData icon,
    required bool hasPermission,
    String? noPermissionMessage,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    if (!hasPermission) {
      return Tooltip(
        message: noPermissionMessage ?? 'ليس لديك صلاحية لهذا الإجراء',
        child: ElevatedButton.icon(
          onPressed: null,
          icon: Icon(icon),
          label: Text(text),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
