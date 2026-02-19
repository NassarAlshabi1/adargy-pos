import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'enhanced_privacy_policy_screen.dart';
import '../services/auth/auth_provider.dart';
import '../services/db/database_service.dart';
import '../utils/dark_mode_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String _selectedUserType = 'manager'; // القيمة الافتراضية

  // بيانات المستخدمين الحقيقية من قاعدة البيانات
  final Map<String, String> _realUsernames = {
    'manager': 'manager',
    'supervisor': 'supervisor',
    'employee': 'employee',
  };

  @override
  void initState() {
    super.initState();
    // مسح أي بيانات غير صحيحة أولاً
    _clearInvalidStoredData();
    // تحميل البيانات الصحيحة
    _loadLastUsername();
    _loadRealUsernames();
  }

  @override
  void didUpdateWidget(LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // إعادة تحميل أسماء المستخدمين عند تحديث الصفحة
    _loadRealUsernames();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // إعادة تحميل أسماء المستخدمين عند العودة من صفحات أخرى
    _loadRealUsernames();
    // إعادة تحميل آخر اسم مستخدم لتحديث المؤشر والحقل بعد تسجيل الخروج
    _loadLastUsername();
    // تأكيد الاتساق عند العودة
    _reconcileUserTypeAndUsername();
  }

  /// مسح البيانات المحفوظة غير الصحيحة
  Future<void> _clearInvalidStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUsername = prefs.getString('last_username');

      if (lastUsername != null && lastUsername.isNotEmpty) {
        final validUsernames = ['manager', 'supervisor', 'employee'];

        if (!validUsernames.contains(lastUsername.toLowerCase())) {
          // احذف القيمة غير الصحيحة
          await prefs.remove('last_username');

          // إظهار رسالة للمستخدم
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم مسح اسم المستخدم غير الصحيح: $lastUsername'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      // تجاهل خطأ تحميل الإعدادات والاستمرار بالقيم الافتراضية
    }
  }

  Future<void> _loadLastUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUsername = prefs.getString('last_username');

      // التحقق من أن اسم المستخدم المحفوظ صحيح
      if (lastUsername != null && lastUsername.isNotEmpty) {
        // قائمة بأسماء المستخدمين الصحيحة
        final validUsernames = ['manager', 'supervisor', 'employee'];

        if (validUsernames.contains(lastUsername.toLowerCase())) {
          _usernameController.text = lastUsername;
          _autoSelectRoleFor(lastUsername);
          _passwordController.clear();
        } else {
          // إذا كان اسم المستخدم غير صحيح، احذف القيمة المحفوظة
          await prefs.remove('last_username');
          // اترك الحقل فارغاً
          _usernameController.clear();
          // اختر المدير كقيمة افتراضية
          _selectedUserType = 'manager';
        }
      }
    } catch (e) {
      // تجاهل خطأ تحميل اسم المستخدم الأخير
    }
    // Ensure consistency after loading
    if (mounted) _reconcileUserTypeAndUsername();
  }

  Future<void> _loadRealUsernames() async {
    try {
      final db = context.read<DatabaseService>();

      // جلب اسم المستخدم للمدير
      final manager = (await db.database.query('users',
              where: 'role = ?', whereArgs: ['manager'], limit: 1))
          .firstOrNull;
      if (manager != null) {
        _realUsernames['manager'] =
            manager['username']?.toString() ?? 'manager';
      }

      // جلب اسم المستخدم للمشرف
      final supervisor = (await db.database.query('users',
              where: 'role = ?', whereArgs: ['supervisor'], limit: 1))
          .firstOrNull;
      if (supervisor != null) {
        _realUsernames['supervisor'] =
            supervisor['username']?.toString() ?? 'supervisor';
      }

      // جلب اسم المستخدم للموظف
      final employee = (await db.database.query('users',
              where: 'role = ?', whereArgs: ['employee'], limit: 1))
          .firstOrNull;
      if (employee != null) {
        _realUsernames['employee'] =
            employee['username']?.toString() ?? 'employee';
      }

      if (mounted) {
        _reconcileUserTypeAndUsername();
        setState(() {});
      }
    } catch (e) {
      // تجاهل خطأ حفظ اسم المستخدم والاستمرار
    }
  }

  void _autoSelectRoleFor(String username) {
    final u = username.toLowerCase();

    // التحقق من الأسماء الحقيقية أولاً
    if (_realUsernames['manager']?.toLowerCase() == u) {
      _selectedUserType = 'manager';
    } else if (_realUsernames['supervisor']?.toLowerCase() == u) {
      _selectedUserType = 'supervisor';
    } else if (_realUsernames['employee']?.toLowerCase() == u) {
      _selectedUserType = 'employee';
    } else {
      // التحقق من الأسماء الافتراضية كبديل
      if (u == 'manager') {
        _selectedUserType = 'manager';
      } else if (u == 'supervisor') {
        _selectedUserType = 'supervisor';
      } else if (u == 'employee') {
        _selectedUserType = 'employee';
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _attemptLogin(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final ok = await context.read<AuthProvider>().login(
          _usernameController.text.trim(),
          _passwordController.text,
        );
    setState(() => _loading = false);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'بيانات الدخول غير صحيحة - تأكد من اسم المستخدم وكلمة المرور'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    // Save last username
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_username', _usernameController.text.trim());
    } catch (e) {
      // تجاهل خطأ حفظ اسم المستخدم الأخير
    }
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'مرحباً ${authProvider.currentUserName} - ${authProvider.currentUserRole}'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<String> _fetchUsernameForRole(
      BuildContext context, String role) async {
    try {
      final db = context.read<DatabaseService>();
      final result = await db.database.query(
        'users',
        columns: ['username'],
        where: 'role = ?',
        whereArgs: [role],
        limit: 1,
      );
      if (result.isNotEmpty) {
        final value = result.first['username']?.toString();
        if (value != null && value.isNotEmpty) return value;
      }
    } catch (e) {
      // تجاهل خطأ الاستعلام والاستمرار بالقيم الافتراضية
    }
    // Fallbacks
    switch (role) {
      case 'manager':
        return 'manager';
      case 'supervisor':
        return 'supervisor';
      case 'employee':
      default:
        return 'employee';
    }
  }

  Future<void> _selectUserType(String userType) async {
    final username = await _fetchUsernameForRole(context, userType);
    if (!mounted) return;
    setState(() {
      _selectedUserType = userType;
      _realUsernames[userType] = username; // keep cache in sync
      _usernameController.text = username;
      _passwordController.clear();
    });
  }

  void _reconcileUserTypeAndUsername() {
    final currentText = _usernameController.text.trim();
    if (currentText.isNotEmpty) {
      // اجعل المؤشر يطابق النص الحالي
      _autoSelectRoleFor(currentText);
    } else {
      // اجعل النص يطابق المؤشر الحالي باستخدام القيم الحقيقية من قاعدة البيانات
      // ignore: discarded_futures
      _selectUserType(_selectedUserType);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DarkModeUtils.getBackgroundColor(context),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Card(
              elevation: 8,
              color: DarkModeUtils.getCardColor(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // عنوان الترحيب + الشعار
                      Container(
                        margin: const EdgeInsets.only(bottom: 32),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/images/soft.png',
                                width: 220,
                                height: 250,
                                fit: BoxFit.cover,
                              ),
                            ),

                            const SizedBox(height: 14),
                            // تمت إضافة الشعار بدلاً من الصندوق الزخرفي
                          ],
                        ),
                      ),
                      // اختيار نوع المستخدم
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'اختر نوع المستخدم',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildUserTypeSelector(),
                          ],
                        ),
                      ),

                      // حقول تسجيل الدخول
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _usernameController,
                              textInputAction: TextInputAction.next,
                              decoration: DarkModeUtils.createInputDecoration(
                                context,
                                hintText:
                                    'اسم المستخدم: manager أو supervisor أو employee',
                                prefixIcon: Icons.person,
                              ).copyWith(
                                filled: true,
                                fillColor:
                                    DarkModeUtils.getBackgroundColor(context)
                                        .withOpacity(0.5),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'مطلوب';
                                }
                                final validUsernames = [
                                  'manager',
                                  'supervisor',
                                  'employee'
                                ];
                                if (!validUsernames.contains(v.toLowerCase())) {
                                  return 'اسم المستخدم غير صحيح. استخدم: manager, supervisor, أو employee';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              textInputAction: TextInputAction.done,
                              decoration: DarkModeUtils.createInputDecoration(
                                context,
                                hintText: 'كلمة المرور',
                                prefixIcon: Icons.lock,
                                suffixIcon: IconButton(
                                  tooltip: _obscure ? 'إظهار' : 'إخفاء',
                                  icon: Icon(_obscure
                                      ? Icons.visibility
                                      : Icons.visibility_off),
                                  onPressed: () => setState(() {
                                    _obscure = !_obscure;
                                  }),
                                ),
                              ).copyWith(
                                filled: true,
                                fillColor:
                                    DarkModeUtils.getBackgroundColor(context)
                                        .withOpacity(0.5),
                              ),
                              obscureText: _obscure,
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'مطلوب' : null,
                              onFieldSubmitted: (_) =>
                                  _loading ? null : _attemptLogin(context),
                            ),
                          ],
                        ),
                      ),

                      // زر تسجيل الدخول
                      Container(
                        width: double.infinity,
                        height: 56,
                        margin: const EdgeInsets.only(bottom: 24),
                        child: FilledButton(
                          onPressed: _loading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate())
                                    return;
                                  setState(() => _loading = true);

                                  // منع طباعة بيانات حساسة

                                  final ok =
                                      await context.read<AuthProvider>().login(
                                            _usernameController.text.trim(),
                                            _passwordController.text,
                                          );

                                  setState(() => _loading = false);
                                  if (!ok && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                            'بيانات الدخول غير صحيحة - تأكد من اسم المستخدم وكلمة المرور'),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  } else if (ok && mounted) {
                                    final authProvider =
                                        context.read<AuthProvider>();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'مرحباً ${authProvider.currentUserName} - ${authProvider.currentUserRole}',
                                        ),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                },
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.login, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'تسجيل الدخول',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      // روابط سياسة الخصوصية
                      Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const EnhancedPrivacyPolicyScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'سياسة الخصوصية',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            const Text(' • ', style: TextStyle(fontSize: 12)),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const EnhancedTermsConditionsScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'شروط الاستخدام',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// بناء منتقي نوع المستخدم
  Widget _buildUserTypeSelector() {
    final options = const [
      (
        'manager',
        'Manager - مدير',
        Icons.admin_panel_settings,
      ),
      (
        'supervisor',
        'Supervisor - مشرف',
        Icons.supervisor_account,
      ),
      (
        'employee',
        'Employee - موظف',
        Icons.person,
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final o in options)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(o.$3, size: 20),
                    const SizedBox(height: 4),
                    Text(
                      o.$2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                selected: _selectedUserType == o.$1,
                onSelected: (_) async {
                  await _selectUserType(o.$1);
                },
                selectedColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.15),
                labelStyle: Theme.of(context).textTheme.bodySmall,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _selectedUserType == o.$1
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// بناء بطاقة نوع المستخدم
}
