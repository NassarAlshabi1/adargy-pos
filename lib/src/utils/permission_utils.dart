import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth/auth_provider.dart';
import '../models/user_model.dart';

/// أدوات فحص الصلاحيات
class PermissionUtils {
  /// فحص الصلاحية مع عرض رسالة واضحة
  static bool checkPermission(
    BuildContext context,
    UserPermission permission, {
    bool showMessage = true,
    String? customMessage,
  }) {
    final auth = context.read<AuthProvider>();
    final hasPermission = auth.hasPermission(permission);

    if (!hasPermission && showMessage) {
      _showPermissionDeniedMessage(context, permission, customMessage);
    }

    return hasPermission;
  }

  /// عرض رسالة عدم الصلاحية
  static void _showPermissionDeniedMessage(
    BuildContext context,
    UserPermission permission,
    String? customMessage,
  ) {
    final message = customMessage ?? _getPermissionMessage(permission);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// الحصول على رسالة الصلاحية
  static String _getPermissionMessage(UserPermission permission) {
    switch (permission) {
      case UserPermission.manageSales:
        return 'ليس لديك صلاحية لإدارة المبيعات';
      case UserPermission.manageProducts:
        return 'ليس لديك صلاحية لإدارة المنتجات';
      case UserPermission.manageCustomers:
        return 'ليس لديك صلاحية لإدارة العملاء';
      case UserPermission.manageSuppliers:
        return 'ليس لديك صلاحية لإدارة الموردين';
      case UserPermission.manageCategories:
        return 'ليس لديك صلاحية لإدارة الأقسام';
      case UserPermission.manageInventory:
        return 'ليس لديك صلاحية لإدارة المخزون';
      case UserPermission.viewReports:
        return 'ليس لديك صلاحية لعرض التقارير';
      case UserPermission.viewProfitCosts:
        return 'ليس لديك صلاحية لعرض الأرباح والتكاليف';
      case UserPermission.manageUsers:
        return 'ليس لديك صلاحية لإدارة المستخدمين';
      case UserPermission.systemSettings:
        return 'ليس لديك صلاحية لإعدادات النظام';
      default:
        return 'ليس لديك صلاحية لهذا الإجراء';
    }
  }

  /// إنشاء زر مع فحص الصلاحية
  static Widget createPermissionButton({
    required BuildContext context,
    required UserPermission permission,
    required String text,
    required VoidCallback? onPressed,
    required IconData icon,
    Color? backgroundColor,
    Color? foregroundColor,
    String? tooltip,
  }) {
    final auth = context.watch<AuthProvider>();
    final hasPermission = auth.hasPermission(permission);

    return Tooltip(
      message: tooltip ?? text,
      child: ElevatedButton.icon(
        onPressed: hasPermission ? onPressed : null,
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: hasPermission ? backgroundColor : Colors.grey,
          foregroundColor: hasPermission ? foregroundColor : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  /// إنشاء قائمة أزرار مع فحص الصلاحيات
  static List<Widget> createPermissionButtons(
    BuildContext context,
    List<PermissionButtonConfig> configs,
  ) {
    return configs.map((config) {
      return createPermissionButton(
        context: context,
        permission: config.permission,
        text: config.text,
        onPressed: config.onPressed,
        icon: config.icon,
        backgroundColor: config.backgroundColor,
        foregroundColor: config.foregroundColor,
        tooltip: config.tooltip,
      );
    }).toList();
  }

  /// فحص الصلاحية مع إعادة التوجيه
  static void checkPermissionWithRedirect(
    BuildContext context,
    UserPermission permission,
    VoidCallback onSuccess,
  ) {
    if (checkPermission(context, permission)) {
      onSuccess();
    } else {
      // إعادة التوجيه إلى الصفحة الرئيسية
      Navigator.of(context).pop();
    }
  }

  /// فحص الصلاحية مع عرض حوار
  static void checkPermissionWithDialog(
    BuildContext context,
    UserPermission permission,
    VoidCallback onSuccess,
  ) {
    if (checkPermission(context, permission)) {
      onSuccess();
    } else {
      _showPermissionDialog(context, permission);
    }
  }

  /// عرض حوار الصلاحية
  static void _showPermissionDialog(
    BuildContext context,
    UserPermission permission,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.orange),
            SizedBox(width: 8),
            Text('صلاحية مطلوبة'),
          ],
        ),
        content: Text(_getPermissionMessage(permission)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('موافق'),
          ),
        ],
      ),
    );
  }
}

/// تكوين زر الصلاحية
class PermissionButtonConfig {
  final UserPermission permission;
  final String text;
  final VoidCallback? onPressed;
  final IconData icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;

  const PermissionButtonConfig({
    required this.permission,
    required this.text,
    required this.onPressed,
    required this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
  });
}
