import 'package:flutter/foundation.dart';
import '../db/database_service.dart';
import '../../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._db);

  final DatabaseService _db;

  UserModel? _currentUser;
  GroupModel? _currentGroup;

  UserModel? get currentUser => _currentUser;
  GroupModel? get currentGroup => _currentGroup;

  // Forced password change disabled per request
  bool get mustChangePassword => false;

  bool get isAuthenticated => _currentUser != null;
  bool get isManager => _currentUser?.role == UserRole.manager;
  bool get isSupervisor => _currentUser?.role == UserRole.supervisor;
  bool get isEmployee => _currentUser?.role == UserRole.employee;

  /// التحقق من وجود صلاحية معينة للمستخدم الحالي
  bool hasPermission(UserPermission permission) {
    if (_currentUser == null) return false;

    // استخدام نظام المجموعات إذا كان المستخدم لديه مجموعة
    if (_currentGroup != null) {
      return _currentGroup!.hasPermission(permission);
    }

    // استخدام النظام القديم (roles) للتوافق
    return _currentUser!.hasPermission(permission, group: null);
  }

  /// الحصول على اسم المستخدم الحالي
  String get currentUserName => _currentUser?.username ?? '';

  /// الحصول على رمز الموظف الحالي
  String get currentEmployeeCode => _currentUser?.employeeCode ?? '';

  /// الحصول على دور المستخدم الحالي
  String get currentUserRole => _currentUser?.roleDisplayName ?? '';

  Future<bool> login(String username, String password) async {
    final userData = await _db.findUserByCredentials(username, password);
    if (userData == null) {
      return false;
    }

    _currentUser = UserModel.fromMap(userData);

    // تحميل مجموعة المستخدم إذا كان لديه group_id
    if (_currentUser?.groupId != null) {
      try {
        _currentGroup = await _db.getUserGroup(_currentUser!.id!);
      } catch (e) {
        _currentGroup = null;
      }
    } else {
      _currentGroup = null;
    }

    // تسجيل حدث تسجيل الدخول
    try {
      await _db.logEvent(
        eventType: 'login',
        entityType: 'user',
        entityId: _currentUser?.id,
        userId: _currentUser?.id,
        username: _currentUser?.username,
        description:
            'تسجيل دخول المستخدم: ${_currentUser?.name} (${_currentUser?.username})',
        details: 'الدور: ${_currentUser?.roleDisplayName}',
      );
    } catch (e) {
      // تجاهل خطأ تسجيل الحدث والاستمرار في تسجيل الدخول
    }

    notifyListeners();
    return true;
  }

  void logout() async {
    // تسجيل حدث تسجيل الخروج قبل مسح المستخدم
    if (_currentUser != null) {
      try {
        await _db.logEvent(
          eventType: 'logout',
          entityType: 'user',
          entityId: _currentUser?.id,
          userId: _currentUser?.id,
          username: _currentUser?.username,
          description:
              'تسجيل خروج المستخدم: ${_currentUser?.name} (${_currentUser?.username})',
          details: 'الدور: ${_currentUser?.roleDisplayName}',
        );
      } catch (e) {
        // تجاهل خطأ تسجيل الحدث والاستمرار في تسجيل الخروج
      }
    }

    _currentUser = null;
    _currentGroup = null;
    notifyListeners();
  }
}
