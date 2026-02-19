import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tijarati/src/screens/app_usage_guide_screen.dart';
import 'package:tijarati/src/screens/database_settings_dialog.dart';
import 'package:tijarati/src/screens/enhanced_privacy_policy_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/dark_mode_utils.dart';
import '../services/db/database_service.dart';
import '../services/store_config.dart';
import '../services/theme_provider.dart';
import '../config/store_info.dart';
import 'license_check_screen.dart';
import 'store_info_screen.dart';
import '../services/store_info_service.dart';

class EnhancedSettingsScreen extends StatefulWidget {
  const EnhancedSettingsScreen({super.key});

  @override
  State<EnhancedSettingsScreen> createState() => _EnhancedSettingsScreenState();
}

class _EnhancedSettingsScreenState extends State<EnhancedSettingsScreen> {
  int _storeInfoUpdateCounter = 0; // لتتبع تحديث معلومات المتجر

  @override
  void initState() {
    super.initState();
    _checkDataExists();
    // تحديث معلومات المتجر عند فتح الشاشة
    _refreshStoreInfo();
  }

  /// تحديث معلومات المتجر
  void _refreshStoreInfo() {
    setState(() {
      _storeInfoUpdateCounter++;
    });
  }

  Future<void> _checkDataExists() async {
    try {
      // Check data exists - this can be used for future features
      if (!mounted) return;
      final db = context.read<DatabaseService>();
      await db.getAllProducts();
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: const Text('الإعدادات'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: Container(
          color: Theme.of(context).colorScheme.surface,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                _buildHeaderCard(),
                const SizedBox(height: 20),

                // Appearance Settings Section
                _buildSectionHeader('إعدادات المظهر'),
                _buildAppearanceSection(),
                const SizedBox(height: 20),

                // Store Information Section (قابل للتعديل)
                _buildSectionHeader('معلومات المتجر'),
                _buildStoreInfoSection(),
                const SizedBox(height: 20),

                // Database Settings Section
                _buildSectionHeader('إعدادات قاعدة البيانات'),
                _buildDatabaseSettingsSection(),
                const SizedBox(height: 20),

                // Support Section
                _buildSectionHeader('الدعم والمساعدة'),
                _buildSupportSection(),
                const SizedBox(height: 20),

                // Legal Section
                _buildSectionHeader('المعلومات القانونية'),
                _buildLegalSection(),
                const SizedBox(height: 20),

                // App Information Section
                _buildSectionHeader('معلومات التطبيق'),
                _buildAppInfoSection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: DarkModeUtils.getShadowColor(context),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الإعدادات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                Text(
                  'إدارة النظام والإعدادات',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          decoration: DarkModeUtils.createCardDecoration(context),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'غيّر مظهر التطبيق بين الوضع الفاتح والمظلم أو اتبع إعدادات نظام التشغيل.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.75),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    themeProvider.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                title: const Text(
                  'الوضع المظلم',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  themeProvider.isDarkMode ? 'مفعل' : 'معطل',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) => themeProvider.toggleTheme(),
                  activeThumbColor: Theme.of(context).colorScheme.primary,
                ),
                onTap: () => themeProvider.toggleTheme(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.palette,
                title: 'نمط التطبيق',
                subtitle: themeProvider.themeMode == ThemeMode.system
                    ? 'يتبع إعدادات النظام'
                    : (themeProvider.isDarkMode
                        ? 'مظلم دائماً'
                        : 'فاتح دائماً'),
                trailing: Icons.arrow_forward_ios,
                onTap: () => _showThemeModeDialog(themeProvider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStoreInfoSection() {
    return Consumer<StoreConfig>(
      builder: (context, store, child) {
        return Container(
          decoration: DarkModeUtils.createCardDecoration(context),
          child: Column(
            children: [
              // تعليق توضيحي
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info,
                        color: Theme.of(context).colorScheme.primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'يمكنك تعديل معلومات المتجر التي تظهر على الفواتير والتقارير من هنا',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // زر تعديل معلومات المتجر
              _buildSettingsTile(
                icon: Icons.edit,
                title: 'تعديل معلومات المتجر',
                subtitle: 'إدارة معلومات المتجر للفواتير والتقارير',
                trailing: Icons.arrow_forward_ios,
                onTap: () async {
                  await StoreInfoScreen.show(context);
                  // تحديث معلومات المحل في StoreConfig
                  final storeConfig = context.read<StoreConfig>();
                  await storeConfig.refreshStoreInfo();
                  // تحديث الشاشة عند العودة من تعديل معلومات المتجر
                  setState(() {
                    _storeInfoUpdateCounter++;
                  });
                },
              ),

              // عرض معلومات المتجر المبسطة
              FutureBuilder<Map<String, String>>(
                key: ValueKey(
                    _storeInfoUpdateCounter), // للتحديث عند تغيير المعلومات
                future: StoreInfoService.getDisplayInfo(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final storeInfo = snapshot.data!;
                    return Column(
                      children: [
                        _buildDivider(),
                        _buildInfoTile(
                          icon: Icons.store,
                          title: 'اسم المحل',
                          value: storeInfo['اسم المحل'] ?? 'غير محدد',
                          isEditable: false,
                        ),
                        _buildDivider(),
                        _buildInfoTile(
                          icon: Icons.location_on,
                          title: 'العنوان',
                          value: storeInfo['العنوان'] ?? 'غير محدد',
                          isEditable: false,
                        ),
                        _buildDivider(),
                        _buildInfoTile(
                          icon: Icons.phone,
                          title: 'رقم الهاتف',
                          value: storeInfo['الهاتف'] ?? 'غير محدد',
                          isEditable: false,
                        ),
                        _buildDivider(),
                        _buildInfoTile(
                          icon: Icons.info,
                          title: 'الوصف',
                          value: storeInfo['الوصف'] ?? 'غير محدد',
                          isEditable: false,
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSupportSection() {
    return Container(
      decoration: DarkModeUtils.createCardDecoration(context),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تجد هنا شرحاً مفصلاً للاستخدام وخيارات التواصل مع الدعم الفني في حال واجهت مشكلة.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.75),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildSettingsTile(
            icon: Icons.book,
            title: 'دليل الاستخدام',
            subtitle: 'شرح خطوة بخطوة لكل الميزات مع أمثلة ونصائح',
            trailing: Icons.arrow_forward_ios,
            onTap: () {
              _showUsageGuideDialog();
            },
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.support_agent,
            title: 'الدعم الفني',
            subtitle: 'أرقام واتساب وبريد إلكتروني وطرق تواصل مباشرة',
            trailing: Icons.arrow_forward_ios,
            onTap: () {
              _showSupportDialog();
            },
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.web,
            title: 'الموقع الإلكتروني',
            subtitle: 'barzandawood.com - زيارة موقعنا الرسمي',
            trailing: Icons.arrow_forward_ios,
            onTap: () {
              _openWebsite();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection() {
    return Container(
      decoration: DarkModeUtils.createCardDecoration(context),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.privacy_tip,
            title: 'سياسة الخصوصية',
            subtitle: 'تفاصيل جمع البيانات وحمايتها وحقوقك في التحكم بها',
            trailing: Icons.arrow_forward_ios,
            onTap: () {
              _showPrivacyPolicyDialog();
            },
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.description,
            title: 'شروط الاستخدام',
            subtitle: 'قواعد استخدام النظام ومسؤوليات الأطراف',
            trailing: Icons.arrow_forward_ios,
            onTap: () {
              _showTermsConditionsDialog();
            },
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.copyright,
            title: 'حقوق الطبع والنشر',
            subtitle: 'معلومات الملكية الفكرية والاستخدام المسموح',
            trailing: Icons.arrow_forward_ios,
            onTap: () {
              _showCopyrightDialog();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoSection() {
    return Consumer<StoreConfig>(
      builder: (context, store, child) {
        return Container(
          decoration: DarkModeUtils.createCardDecoration(context),
          child: Column(
            children: [
              _buildInfoTile(
                icon: Icons.info_outline,
                title: 'إصدار التطبيق',
                value: store.displayVersion,
              ),
              _buildDivider(),
              _buildInfoTile(
                icon: Icons.calendar_today,
                title: 'تاريخ الإصدار',
                value: store.releaseYear,
              ),
              _buildDivider(),
              _buildInfoTile(
                icon: Icons.developer_mode,
                title: 'المطور',
                value: store.developer,
              ),
              _buildDivider(),
              _buildInfoTile(
                icon: Icons.language,
                title: 'اللغة',
                value: store.language,
              ),
              _buildDivider(),
              _buildInfoTile(
                icon: Icons.location_on,
                title: 'البلد',
                value: store.country,
              ),
              _buildDivider(),
              _buildSettingsTile(
                icon: Icons.key,
                title: 'فحص الترخيص',
                subtitle: 'فحص حالة الترخيص وإدارة المفاتيح',
                trailing: Icons.arrow_forward_ios,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => const LicenseCheckDialog(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    IconData? trailing,
    Color? iconColor,
    VoidCallback? onTap,
    bool isEditable = true,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isEditable
              ? (iconColor ?? scheme.primary).withOpacity(0.1)
              : scheme.onSurface.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isEditable ? (iconColor ?? scheme.primary) : scheme.onSurface,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: scheme.onSurface.withOpacity(0.7),
        ),
      ),
      trailing: trailing != null
          ? Icon(
              trailing,
              size: 16,
              color: Theme.of(context).dividerColor.withOpacity(0.6),
            )
          : null,
      onTap: isEditable ? onTap : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    bool isEditable = true,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isEditable
              ? scheme.primary.withOpacity(0.1)
              : scheme.onSurface.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isEditable ? scheme.primary : scheme.onSurface,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: scheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!isEditable) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.lock,
              size: 16,
              color: scheme.onSurface.withOpacity(0.6),
            ),
          ],
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        color: Theme.of(context).dividerColor.withOpacity(0.4),
      ),
    );
  }

  // Methods

  void _showCopyrightDialog() {
    showDialog(
      context: context,
      builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.copyright,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                const Text('حقوق الطبع والنشر'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  StoreInfo.copyright,
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
                SizedBox(height: 8),
                Text(StoreInfo.rightsReserved, textAlign: TextAlign.right),
                SizedBox(height: 8),
                Text(StoreInfo.ownership, textAlign: TextAlign.right),
                SizedBox(height: 8),
                Text(
                    'لا يجوز نسخ أو توزيع أو تعديل أي جزء من هذا التطبيق بدون إذن كتابي صريح.'),
                SizedBox(height: 8),
                Text(
                    'العلامات التجارية والعلامات التجارية المسجلة هي ملكية أصحابها.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إغلاق'),
              ),
            ],
          )),
    );
  }

  Future<void> _showUsageGuideDialog() async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.book,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'دليل الاستخدام',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: const AppUsageGuideScreen(showAppBar: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => Consumer<StoreConfig>(
        builder: (context, store, child) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.support_agent,
                  color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 8),
              const Text('الدعم الفني'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // معلومات التطبيق
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .secondaryContainer
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.support_agent,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'تجارتي',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // معلومات التواصل
                const Text(
                  'طرق التواصل:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // رقم الواتساب
                _buildContactItem(
                  icon: Icons.phone,
                  title: 'واتساب',
                  subtitle: store.whatsapp,
                  color: Theme.of(context).colorScheme.tertiary,
                  onTap: () => _openWhatsAppClient(store.whatsapp),
                ),
                const SizedBox(height: 8),

                // البريد الإلكتروني
                _buildContactItem(
                  icon: Icons.email,
                  title: 'البريد الإلكتروني',
                  subtitle: store.email,
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () => _openEmailClient(store.email),
                ),
                const SizedBox(height: 8),

                // العنوان
                _buildContactItem(
                  icon: Icons.location_on,
                  title: 'العنوان',
                  subtitle: store.city,
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: () => _copyToClipboard(store.city),
                ),
                const SizedBox(height: 8),

                // الموقع الإلكتروني
                _buildContactItem(
                  icon: Icons.web,
                  title: 'الموقع الإلكتروني',
                  subtitle: 'barzandawood.com',
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () => _openWebsite(),
                ),
                const SizedBox(height: 16),

                // معلومات إضافية
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: DarkModeUtils.getBorderColor(context)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info,
                          color: Theme.of(context).colorScheme.primary,
                          size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'اضغط على أي عنصر لنسخه إلى الحافظة',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: DarkModeUtils.getBorderColor(context)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.copy,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم نسخ "$text" إلى الحافظة'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في النسخ: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _openEmailClient(String email) async {
    try {
      // عرض نافذة اختيار العمل
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.email, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('فتح البريد الإلكتروني'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اختر طريقة التواصل:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // فتح تطبيق البريد
              ListTile(
                leading: Icon(Icons.email,
                    color: Theme.of(context).colorScheme.primary),
                title: const Text('فتح تطبيق البريد'),
                subtitle: const Text('فتح تطبيق البريد الافتراضي'),
                onTap: () async {
                  Navigator.pop(context);
                  await _launchEmailApp(email);
                },
              ),

              // نسخ الإيميل
              ListTile(
                leading: Icon(Icons.copy,
                    color: Theme.of(context).colorScheme.primary),
                title: const Text('نسخ الإيميل'),
                subtitle: const Text('نسخ الإيميل إلى الحافظة'),
                onTap: () async {
                  Navigator.pop(context);
                  await _copyToClipboard(email);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في فتح البريد الإلكتروني: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _launchEmailApp(String email) async {
    try {
      // إنشاء رابط البريد الإلكتروني
      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: email,
        query:
            'subject=${StoreInfo.defaultEmailSubject}&body=${StoreInfo.defaultEmailBody}',
      );

      // محاولة فتح تطبيق البريد
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم فتح تطبيق البريد الإلكتروني'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // إذا فشل فتح التطبيق، عرض نافذة بديلة
        await _showEmailFallbackDialog(email);
      }
    } catch (e) {
      // في حالة الفشل، عرض نافذة بديلة
      await _showEmailFallbackDialog(email);
    }
  }

  Future<void> _showEmailFallbackDialog(String email) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.email, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('البريد الإلكتروني'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'لم يتم العثور على تطبيق بريد إلكتروني. تم نسخ الإيميل إلى الحافظة:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2)),
              ),
              child: Text(
                email,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.info,
                    color: Theme.of(context).colorScheme.primary, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'يمكنك الآن لصق الإيميل في تطبيق البريد المفضل لديك',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('موافق'),
          ),
        ],
      ),
    );

    // نسخ الإيميل إلى الحافظة
    await _copyToClipboard(email);
  }

  Future<void> _openWhatsAppClient(String phoneNumber) async {
    try {
      // عرض نافذة اختيار العمل
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.phone, color: Color(0xFF059669)), // Professional Green
              const SizedBox(width: 8),
              const Text('فتح الواتساب'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اختر طريقة التواصل:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // فتح الواتساب
              ListTile(
                leading: Icon(Icons.phone,
                    color: Color(0xFF059669)), // Professional Green
                title: const Text('فتح الواتساب'),
                subtitle: const Text('فتح تطبيق الواتساب'),
                onTap: () async {
                  Navigator.pop(context);
                  await _openWhatsApp(phoneNumber);
                },
              ),

              // نسخ الرقم
              ListTile(
                leading: Icon(Icons.copy,
                    color: Color(0xFF1976D2)), // Professional Blue
                title: const Text('نسخ الرقم'),
                subtitle: const Text('نسخ رقم الواتساب إلى الحافظة'),
                onTap: () async {
                  Navigator.pop(context);
                  await _copyToClipboard(phoneNumber);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في فتح الواتساب: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _showPrivacyPolicyDialog() async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.privacy_tip,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'سياسة الخصوصية',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: const EnhancedPrivacyPolicyScreen(showAppBar: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showTermsConditionsDialog() async {
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.description,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'شروط الاستخدام',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: const EnhancedTermsConditionsScreen(showAppBar: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    try {
      // إزالة أي رموز غير مرغوب فيها من رقم الهاتف
      String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      // إنشاء رابط الواتساب
      final Uri whatsappUri = Uri.parse(
          'https://wa.me/$cleanNumber?text=${StoreInfo.defaultWhatsAppMessage}');

      // محاولة فتح الواتساب
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم فتح الواتساب'),
              backgroundColor: null,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // إذا فشل فتح الواتساب، نسخ الرقم
        await _copyToClipboard(phoneNumber);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم نسخ رقم الواتساب إلى الحافظة'),
              backgroundColor: null,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // في حالة الفشل، نسخ الرقم
      await _copyToClipboard(phoneNumber);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم نسخ رقم الواتساب إلى الحافظة'),
            backgroundColor: null,
          ),
        );
      }
    }
  }

  Widget _buildDatabaseSettingsSection() {
    return Container(
      decoration: DarkModeUtils.createCardDecoration(context),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.storage,
            title: 'إعدادات قاعدة البيانات',
            subtitle: 'إدارة النسخ الاحتياطية والاستعادة',
            trailing: Icons.arrow_forward_ios,
            iconColor: Theme.of(context).colorScheme.tertiary,
            onTap: () => _showDatabaseSettingsDialog(),
          ),
        ],
      ),
    );
  }

  // تم حذف منطق إدارة المستخدمين من شاشة الإعدادات بعد نقله إلى صفحة إدارة المستخدمين

  // تم إزالة دالة _sha256 بعد نقل إدارة المستخدمين

  Future<void> _showDatabaseSettingsDialog() async {
    await showDialog(
      context: context,
      builder: (context) => const DatabaseSettingsDialog(),
    );
  }

  Future<void> _openWebsite() async {
    try {
      // عرض نافذة اختيار العمل
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.web, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              const Text('فتح الموقع الإلكتروني'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'اختر طريقة فتح الموقع:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // فتح الموقع في المتصفح
              ListTile(
                leading: Icon(Icons.open_in_browser,
                    color: Theme.of(context).colorScheme.primary),
                title: const Text('فتح في المتصفح'),
                subtitle: const Text('فتح الموقع في المتصفح الافتراضي'),
                onTap: () async {
                  Navigator.pop(context);
                  await _launchWebsite();
                },
              ),

              // نسخ رابط الموقع
              ListTile(
                leading: Icon(Icons.copy,
                    color: Theme.of(context).colorScheme.primary),
                title: const Text('نسخ الرابط'),
                subtitle: const Text('نسخ رابط الموقع إلى الحافظة'),
                onTap: () async {
                  Navigator.pop(context);
                  await _copyToClipboard('https://barzandawood.com');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في فتح الموقع الإلكتروني: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _launchWebsite() async {
    try {
      final Uri websiteUri = Uri.parse('https://barzandawood.com');

      // محاولة فتح الموقع في المتصفح
      if (await canLaunchUrl(websiteUri)) {
        await launchUrl(websiteUri, mode: LaunchMode.externalApplication);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم فتح الموقع الإلكتروني في المتصفح'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // إذا فشل فتح المتصفح، نسخ الرابط
        await _copyToClipboard('https://barzandawood.com');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('تم نسخ رابط الموقع إلى الحافظة'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // في حالة الفشل، نسخ الرابط
      await _copyToClipboard('https://barzandawood.com');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم نسخ رابط الموقع إلى الحافظة'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }
  }

  Future<void> _showThemeModeDialog(ThemeProvider themeProvider) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.palette, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('اختيار نمط التطبيق'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('نظام التشغيل'),
              subtitle: const Text('يتبع إعدادات النظام'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('فاتح'),
              subtitle: const Text('الوضع الفاتح دائماً'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('مظلم'),
              subtitle: const Text('الوضع المظلم دائماً'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}
