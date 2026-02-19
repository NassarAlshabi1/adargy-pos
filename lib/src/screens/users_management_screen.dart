import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth/auth_provider.dart';
import '../services/db/database_service.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user_model.dart';
import '../utils/dark_mode_utils.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  int _credsVersion = 0;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final db = context.read<DatabaseService>();

    // التحقق من الصلاحية
    if (!authProvider.hasPermission(UserPermission.manageUsers)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('إدارة المستخدمين'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              Text(
                'ليس لديك صلاحية للوصول إلى هذه الصفحة',
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.onPrimary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.people,
                color: scheme.onPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('إدارة المستخدمين'),
          ],
        ),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
      ),
      backgroundColor: DarkModeUtils.getBackgroundColor(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات المستخدم الحالي - تصميم مضغوط
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, color: scheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'المستخدم الحالي:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    authProvider.currentUserName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      authProvider.currentUserRole,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // إدارة أسماء المستخدمين وكلمات المرور
            _UserCredsEditor(key: ValueKey(_credsVersion), db: db),

            const SizedBox(height: 12),

            // زر إعادة ضبط كلمات المرور (للمدير فقط)
            if (authProvider.currentUserRole == 'مدير')
              _buildResetPasswordsButton(
                context,
                db,
                () {
                  setState(() {
                    _credsVersion++;
                  });
                },
              ),

            const SizedBox(height: 12),

            // شرح الصلاحيات - تصميم مضغوط
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DarkModeUtils.getCardColor(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: scheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.security, color: scheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'شرح الصلاحيات',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // الأدوار في صف واحد
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildCompactPermissionInfo('مدير',
                                  UserRole.manager.permissionsDescription),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildCompactPermissionInfo('مشرف',
                                  UserRole.supervisor.permissionsDescription),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildCompactPermissionInfo('موظف',
                                  UserRole.employee.permissionsDescription),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildCompactPermissionInfo('مدير',
                                UserRole.manager.permissionsDescription),
                            const SizedBox(height: 12),
                            _buildCompactPermissionInfo('مشرف',
                                UserRole.supervisor.permissionsDescription),
                            const SizedBox(height: 12),
                            _buildCompactPermissionInfo('موظف',
                                UserRole.employee.permissionsDescription),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactPermissionInfo(String role, String permissions) {
    final scheme = Theme.of(context).colorScheme;
    final roleColors = {
      'مدير': Colors.blue,
      'مشرف': Colors.orange,
      'موظف': Colors.green,
    };
    final roleColor = roleColors[role] ?? scheme.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: roleColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: roleColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                role == 'مدير'
                    ? Icons.admin_panel_settings
                    : role == 'مشرف'
                        ? Icons.supervisor_account
                        : Icons.person,
                color: roleColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                role,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: roleColor,
                      fontSize: 13,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            permissions,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  height: 1.5,
                  color: scheme.onSurface.withOpacity(0.7),
                ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _UserCredsEditor extends StatefulWidget {
  const _UserCredsEditor({super.key, required this.db});
  final DatabaseService db;

  @override
  State<_UserCredsEditor> createState() => _UserCredsEditorState();
}

class _UserCredsEditorState extends State<_UserCredsEditor> {
  final TextEditingController _supervisorUsername = TextEditingController();
  final TextEditingController _employeeUsername = TextEditingController();
  final TextEditingController _supervisorPassword = TextEditingController();
  final TextEditingController _employeePassword = TextEditingController();
  bool _showSupervisorPassword = false;
  bool _showEmployeePassword = false;
  bool _savingSupervisor = false;
  bool _savingEmployee = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sup = (await widget.db.database.query('users',
            where: 'role = ?', whereArgs: ['supervisor'], limit: 1))
        .firstOrNull;
    final emp = (await widget.db.database.query('users',
            where: 'role = ?', whereArgs: ['employee'], limit: 1))
        .firstOrNull;
    setState(() {
      _supervisorUsername.text = (sup?['username']?.toString() ?? 'supervisor');
      _employeeUsername.text = (emp?['username']?.toString() ?? 'employee');
    });
  }

  @override
  void dispose() {
    _supervisorUsername.dispose();
    _employeeUsername.dispose();
    _supervisorPassword.dispose();
    _employeePassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // User editor cards - responsive layout
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildEditorCard(
                  title: 'المشرف',
                  icon: Icons.supervisor_account,
                  color: Colors.orange,
                  usernameController: _supervisorUsername,
                  passwordController: _supervisorPassword,
                  showPassword: _showSupervisorPassword,
                  isSaving: _savingSupervisor,
                  onToggleObscure: () => setState(() {
                    _showSupervisorPassword = !_showSupervisorPassword;
                  }),
                  onSave: () async {
                    if (_savingSupervisor) return;
                    setState(() => _savingSupervisor = true);
                    try {
                      await _saveSupervisor(context);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('فشل حفظ بيانات المشرف'),
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            width: 300,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _savingSupervisor = false);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildEditorCard(
                  title: 'الموظف',
                  icon: Icons.person,
                  color: Colors.blue,
                  usernameController: _employeeUsername,
                  passwordController: _employeePassword,
                  showPassword: _showEmployeePassword,
                  isSaving: _savingEmployee,
                  onToggleObscure: () => setState(() {
                    _showEmployeePassword = !_showEmployeePassword;
                  }),
                  onSave: () async {
                    if (_savingEmployee) return;
                    setState(() => _savingEmployee = true);
                    try {
                      await _saveEmployee(context);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('فشل حفظ بيانات الموظف'),
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                            width: 300,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _savingEmployee = false);
                    }
                  },
                ),
              ),
            ],
          )
        else ...[
          _buildEditorCard(
            title: 'المشرف',
            icon: Icons.supervisor_account,
            color: Colors.orange,
            usernameController: _supervisorUsername,
            passwordController: _supervisorPassword,
            showPassword: _showSupervisorPassword,
            isSaving: _savingSupervisor,
            onToggleObscure: () => setState(() {
              _showSupervisorPassword = !_showSupervisorPassword;
            }),
            onSave: () async {
              if (_savingSupervisor) return;
              setState(() => _savingSupervisor = true);
              try {
                await _saveSupervisor(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('فشل حفظ بيانات المشرف'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _savingSupervisor = false);
              }
            },
          ),
          const SizedBox(height: 12),
          _buildEditorCard(
            title: 'الموظف',
            icon: Icons.person,
            color: Colors.blue,
            usernameController: _employeeUsername,
            passwordController: _employeePassword,
            showPassword: _showEmployeePassword,
            isSaving: _savingEmployee,
            onToggleObscure: () => setState(() {
              _showEmployeePassword = !_showEmployeePassword;
            }),
            onSave: () async {
              if (_savingEmployee) return;
              setState(() => _savingEmployee = true);
              try {
                await _saveEmployee(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('فشل حفظ بيانات الموظف'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _savingEmployee = false);
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildEditorCard({
    required String title,
    required IconData icon,
    required Color color,
    required TextEditingController usernameController,
    required TextEditingController passwordController,
    required bool showPassword,
    required bool isSaving,
    required VoidCallback onToggleObscure,
    required Future<void> Function() onSave,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DarkModeUtils.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title - تصميم مضغوط
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Username field - تصميم مضغوط
          TextField(
            controller: usernameController,
            decoration: InputDecoration(
              labelText: 'اسم المستخدم',
              labelStyle: TextStyle(fontSize: 13, color: color),
              hintText: 'اسم المستخدم',
              prefixIcon: Icon(Icons.person, color: color, size: 18),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color, width: 1.5),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Password field - تصميم مضغوط
          TextField(
            controller: passwordController,
            obscureText: !showPassword,
            decoration: InputDecoration(
              labelText: 'كلمة المرور الجديدة',
              labelStyle: TextStyle(fontSize: 13, color: color),
              hintText:
                  '6 أحرف على الأقل (اتركها فارغة للحفاظ على الكلمة الحالية)',
              hintStyle: TextStyle(fontSize: 11),
              prefixIcon: Icon(Icons.lock, color: color, size: 18),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color, width: 1.5),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  showPassword ? Icons.visibility_off : Icons.visibility,
                  color: color,
                  size: 18,
                ),
                onPressed: onToggleObscure,
                tooltip:
                    showPassword ? 'إخفاء كلمة المرور' : 'إظهار كلمة المرور',
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Save button - تصميم مضغوط
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isSaving ? null : () => onSave(),
              icon: isSaving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.save, size: 16),
              label: Text(
                isSaving ? 'جارٍ الحفظ...' : 'حفظ $title',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSupervisor(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final nowIso = DateTime.now().toIso8601String();
    final newName = _supervisorUsername.text.trim();
    bool hasChanges = false; // تتبع التغييرات

    // التحقق من اسم المستخدم
    if (newName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('اسم المستخدم لا يمكن أن يكون فارغاً'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          width: 300,
        ));
      }
      return;
    }

    // التحقق من كلمة المرور إذا تم إدخالها
    if (_supervisorPassword.text.isNotEmpty &&
        _supervisorPassword.text.length < 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('كلمة المرور يجب أن تكون 6 أحرف على الأقل'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          width: 300,
        ));
      }
      return;
    }

    // الحصول على بيانات المشرف الحالي
    final currentSupervisor = (await widget.db.database.query('users',
            where: 'role = ?', whereArgs: ['supervisor'], limit: 1))
        .firstOrNull;

    if (currentSupervisor == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('لم يتم العثور على حساب المشرف'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          width: 300,
        ));
      }
      return;
    }

    final currentUsername = currentSupervisor['username']?.toString() ?? '';
    final supervisorId = currentSupervisor['id'];
    final currentUserId = authProvider.currentUser?.id;

    // التحقق من التضارب فقط إذا كان اسم المستخدم مختلف
    if (currentUsername != newName) {
      // تحذير إذا كان المستخدم الحالي هو المشرف
      if (currentUserId == supervisorId) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text('تحذير'),
              ],
            ),
            content: const Text(
              'أنت على وشك تغيير اسم المستخدم الخاص بك. سيتم تسجيل خروجك تلقائياً بعد التغيير.\n\n'
              'هل تريد المتابعة؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('متابعة'),
              ),
            ],
          ),
        );

        if (confirmed != true) {
          return;
        }
      }

      final conflict = await widget.db.database.query('users',
          where: 'username = ? AND id != ?',
          whereArgs: [newName, supervisorId],
          limit: 1);
      if (conflict.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('الاسم "$newName" مستخدم من حساب آخر'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ));
        }
        return;
      }

      // تحديث اسم المستخدم
      await widget.db.database.update(
          'users', {'username': newName, 'updated_at': nowIso},
          where: 'id = ?', whereArgs: [supervisorId]);
      hasChanges = true;

      // تسجيل خروج المستخدم الحالي إذا كان هو المشرف
      if (currentUserId == supervisorId && mounted) {
        authProvider.logout();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                const Text('تم تغيير اسم المستخدم. يرجى تسجيل الدخول مرة أخرى'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            width: 300,
          ));
        }
        return;
      }
    }

    // تحديث كلمة المرور إذا تم إدخالها
    if (_supervisorPassword.text.isNotEmpty) {
      await widget.db.database.update(
        'users',
        {
          'password': _sha256Hash(_supervisorPassword.text),
          'updated_at': nowIso
        },
        where: 'id = ?',
        whereArgs: [supervisorId],
      );
      _supervisorPassword.clear();
      hasChanges = true;
    }

    // إعادة تحميل البيانات فقط إذا كان هناك تغيير
    if (hasChanges) {
      await _load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('تم حفظ بيانات المشرف بنجاح'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          width: 300,
        ));
      }
    } else {
      // لا توجد تغييرات
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('لم يتم إجراء أي تغييرات'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          width: 300,
        ));
      }
    }
  }

  Future<void> _saveEmployee(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final nowIso = DateTime.now().toIso8601String();
    final newName = _employeeUsername.text.trim();
    bool hasChanges = false; // تتبع التغييرات

    // التحقق من اسم المستخدم
    if (newName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('اسم المستخدم لا يمكن أن يكون فارغاً'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          width: 300,
        ));
      }
      return;
    }

    // التحقق من كلمة المرور إذا تم إدخالها
    if (_employeePassword.text.isNotEmpty &&
        _employeePassword.text.length < 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('كلمة المرور يجب أن تكون 6 أحرف على الأقل'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          width: 300,
        ));
      }
      return;
    }

    // الحصول على بيانات الموظف الحالي
    final currentEmployee = (await widget.db.database.query('users',
            where: 'role = ?', whereArgs: ['employee'], limit: 1))
        .firstOrNull;

    if (currentEmployee == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('لم يتم العثور على حساب الموظف'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          width: 300,
        ));
      }
      return;
    }

    final currentUsername = currentEmployee['username']?.toString() ?? '';
    final employeeId = currentEmployee['id'];
    final currentUserId = authProvider.currentUser?.id;

    // التحقق من التضارب فقط إذا كان اسم المستخدم مختلف
    if (currentUsername != newName) {
      // تحذير إذا كان المستخدم الحالي هو الموظف
      if (currentUserId == employeeId) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text('تحذير'),
              ],
            ),
            content: const Text(
              'أنت على وشك تغيير اسم المستخدم الخاص بك. سيتم تسجيل خروجك تلقائياً بعد التغيير.\n\n'
              'هل تريد المتابعة؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('متابعة'),
              ),
            ],
          ),
        );

        if (confirmed != true) {
          return;
        }
      }

      final conflict = await widget.db.database.query('users',
          where: 'username = ? AND id != ?',
          whereArgs: [newName, employeeId],
          limit: 1);
      if (conflict.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('الاسم "$newName" مستخدم من حساب آخر'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ));
        }
        return;
      }

      // تحديث اسم المستخدم
      await widget.db.database.update(
          'users', {'username': newName, 'updated_at': nowIso},
          where: 'id = ?', whereArgs: [employeeId]);
      hasChanges = true;

      // تسجيل خروج المستخدم الحالي إذا كان هو الموظف
      if (currentUserId == employeeId && mounted) {
        authProvider.logout();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                const Text('تم تغيير اسم المستخدم. يرجى تسجيل الدخول مرة أخرى'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            width: 300,
          ));
        }
        return;
      }
    }

    // تحديث كلمة المرور إذا تم إدخالها
    if (_employeePassword.text.isNotEmpty) {
      await widget.db.database.update(
        'users',
        {'password': _sha256Hash(_employeePassword.text), 'updated_at': nowIso},
        where: 'id = ?',
        whereArgs: [employeeId],
      );
      _employeePassword.clear();
      hasChanges = true;
    }

    // إعادة تحميل البيانات فقط إذا كان هناك تغيير
    if (hasChanges) {
      await _load();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('تم حفظ بيانات الموظف بنجاح'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          width: 300,
        ));
      }
    } else {
      // لا توجد تغييرات
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('لم يتم إجراء أي تغييرات'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          width: 300,
        ));
      }
    }
  }
}

// زر إعادة ضبط كلمات المرور (للمدير فقط)
Widget _buildResetPasswordsButton(
    BuildContext context, DatabaseService db, VoidCallback onAfterReset) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      border: Border.all(
        color: Colors.red,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: ElevatedButton.icon(
      onPressed: () => _showResetPasswordsDialog(context, db, onAfterReset),
      icon: const Icon(Icons.refresh, color: Colors.white),
      label: const Text(
        'إعادة ضبط أسماء المستخدمين وكلمات المرور',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
  );
}

// حوار تأكيد إعادة ضبط كلمات المرور
Future<void> _showResetPasswordsDialog(
    BuildContext context, DatabaseService db, VoidCallback onAfterReset) async {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, color: Colors.red, size: 20),
            const SizedBox(width: 6),
            const Text('تأكيد إعادة الضبط', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'هل أنت متأكد من إعادة ضبط أسماء المستخدمين وكلمات المرور؟',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue.shade700, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'بيانات الدخول الافتراضية:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildCredentialRow(
                        context, 'المدير', 'manager', 'man2026', isDark),
                    const SizedBox(height: 6),
                    _buildCredentialRow(
                        context, 'المشرف', 'supervisor', 'sup2026', isDark),
                    const SizedBox(height: 6),
                    _buildCredentialRow(
                        context, 'الموظف', 'employee', 'emp2026', isDark),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.orange.shade700, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'تحذير: سيتم إعادة تعيين كلمات المرور إلى القيم الافتراضية. يرجى تغييرها فوراً للأمان.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء', style: TextStyle(fontSize: 13)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _resetAllPasswords(context, db, onAfterReset);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('تأكيد الإعادة', style: TextStyle(fontSize: 13)),
          ),
        ],
      );
    },
  );
}

// دالة مساعدة لعرض بيانات الدخول
Widget _buildCredentialRow(BuildContext context, String roleName,
    String username, String password, bool isDark) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color:
          isDark ? Colors.grey.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: Theme.of(context).dividerColor.withOpacity(0.2),
      ),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            roleName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: SelectableText(
              username,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: SelectableText(
              password,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                color: Colors.green.shade700,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

// دالة إعادة ضبط كلمات المرور
Future<void> _resetAllPasswords(
    BuildContext context, DatabaseService db, VoidCallback onAfterReset) async {
  try {
    // إظهار مؤشر التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final nowIso = DateTime.now().toIso8601String();

    // إعادة ضبط المدير (اسم المستخدم + كلمة المرور)
    final managerId = await _getUserIdByRole(db, 'manager');
    if (managerId != null) {
      // فض أي تعارض على اسم manager
      final conflict = await db.database.query(
        'users',
        columns: ['id'],
        where: 'username = ? AND id != ?',
        whereArgs: ['manager', managerId],
        limit: 1,
      );
      if (conflict.isNotEmpty) {
        final otherId = conflict.first['id'];
        await db.database.update(
          'users',
          {
            'username': 'manager_conflict_$otherId',
            'updated_at': nowIso,
          },
          where: 'id = ?',
          whereArgs: [otherId],
        );
      }
      await db.database.update(
        'users',
        {
          'username': 'manager',
          'password': _sha256Hash('man2026'),
          'updated_at': nowIso,
        },
        where: 'id = ?',
        whereArgs: [managerId],
      );
    }

    // إعادة ضبط المشرف (اسم المستخدم + كلمة المرور)
    final supervisorId = await _getUserIdByRole(db, 'supervisor');
    if (supervisorId != null) {
      try {
        // فض أي تعارض على اسم supervisor
        final conflict = await db.database.query(
          'users',
          columns: ['id'],
          where: 'username = ? AND id != ?',
          whereArgs: ['supervisor', supervisorId],
          limit: 1,
        );
        if (conflict.isNotEmpty) {
          final otherId = conflict.first['id'];
          await db.database.update(
            'users',
            {
              'username': 'supervisor_conflict_$otherId',
              'updated_at': nowIso,
            },
            where: 'id = ?',
            whereArgs: [otherId],
          );
        }
        await db.database.update(
          'users',
          {
            'username': 'supervisor',
            'password': _sha256Hash('sup2026'),
            'updated_at': nowIso,
          },
          where: 'id = ?',
          whereArgs: [supervisorId],
        );
      } catch (e) {
        // محاولة تحديث كلمة المرور فقط
        try {
          await db.database.update(
            'users',
            {
              'password': _sha256Hash('sup2026'),
              'updated_at': nowIso,
            },
            where: 'id = ?',
            whereArgs: [supervisorId],
          );
        } catch (e2) {
          // تجاهل خطأ تحديث كلمة المرور
        }
      }
    }

    // إعادة ضبط الموظف (اسم المستخدم + كلمة المرور)
    final employeeId = await _getUserIdByRole(db, 'employee');
    if (employeeId != null) {
      try {
        // فض أي تعارض على اسم employee
        final conflict = await db.database.query(
          'users',
          columns: ['id'],
          where: 'username = ? AND id != ?',
          whereArgs: ['employee', employeeId],
          limit: 1,
        );
        if (conflict.isNotEmpty) {
          final otherId = conflict.first['id'];
          await db.database.update(
            'users',
            {
              'username': 'employee_conflict_$otherId',
              'updated_at': nowIso,
            },
            where: 'id = ?',
            whereArgs: [otherId],
          );
        }
        await db.database.update(
          'users',
          {
            'username': 'employee',
            'password': _sha256Hash('emp2026'),
            'updated_at': nowIso,
          },
          where: 'id = ?',
          whereArgs: [employeeId],
        );
      } catch (e) {
        // محاولة تحديث كلمة المرور فقط
        try {
          await db.database.update(
            'users',
            {
              'password': _sha256Hash('emp2026'),
              'updated_at': nowIso,
            },
            where: 'id = ?',
            whereArgs: [employeeId],
          );
        } catch (e2) {
          // تجاهل خطأ تحديث كلمة المرور
        }
      }
    }

    // إغلاق مؤشر التحميل
    if (context.mounted) Navigator.of(context).pop();

    // إظهار رسالة نجاح
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('تم إعادة ضبط أسماء المستخدمين وكلمات المرور بنجاح'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          width: 300,
        ),
      );
    }
    onAfterReset();
  } catch (e) {
    // إغلاق مؤشر التحميل
    if (context.mounted) Navigator.of(context).pop();

    // إظهار رسالة خطأ
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('فشل إعادة ضبط أسماء المستخدمين وكلمات المرور'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          width: 300,
        ),
      );
    }
  }
}

// دالة تشفير كلمة المرور (مشتركة)
String _sha256Hash(String input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

// دالة مساعدة للحصول على معرف المستخدم حسب الدور
Future<int?> _getUserIdByRole(DatabaseService db, String role) async {
  try {
    final result = await db.database.query(
      'users',
      columns: ['id'],
      where: 'role = ?',
      whereArgs: [role],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int?;
    }
    return null;
  } catch (e) {
    return null;
  }
}
