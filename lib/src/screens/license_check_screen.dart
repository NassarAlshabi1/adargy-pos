import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/license/license_provider.dart';
import '../services/license/license_service.dart';
import '../services/store_config.dart';
import '../utils/dark_mode_utils.dart';
import 'license_activation_screen.dart';

class LicenseCheckScreen extends StatefulWidget {
  const LicenseCheckScreen({super.key});

  @override
  State<LicenseCheckScreen> createState() => _LicenseCheckScreenState();
}

class LicenseCheckDialog extends StatefulWidget {
  const LicenseCheckDialog({super.key});

  @override
  State<LicenseCheckDialog> createState() => _LicenseCheckDialogState();
}

class _LicenseCheckScreenState extends State<LicenseCheckScreen> {
  @override
  void initState() {
    super.initState();
    // تهيئة مزود الترخيص عند بدء الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LicenseProvider>().initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final storeConfig = context.watch<StoreConfig>();
    final licenseProvider = context.watch<LicenseProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: DarkModeUtils.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('فحص الترخيص'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // شعار التطبيق - أصغر
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.business_center,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // عنوان التطبيق - أصغر
                      Text(
                        storeConfig.appTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: DarkModeUtils.getTextColor(context),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'تجارتي',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: DarkModeUtils.getTextColor(context)
                              .withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // حالة الترخيص
                      _buildLicenseStatus(licenseProvider, theme),

                      const SizedBox(height: 20),

                      // أزرار الإجراءات
                      _buildActionButtons(licenseProvider, theme),
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

  Widget _buildLicenseStatus(LicenseProvider licenseProvider, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DarkModeUtils.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: licenseProvider.getStatusColor().withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          // أيقونة الحالة - أصغر
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: licenseProvider.getStatusColor().withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              licenseProvider.getStatusIcon(),
              size: 30,
              color: licenseProvider.getStatusColor(),
            ),
          ),

          const SizedBox(height: 12),

          // عنوان الحالة - أصغر
          Text(
            _getStatusTitle(licenseProvider.status),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: DarkModeUtils.getTextColor(context),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          // وصف الحالة - أصغر
          Text(
            _getStatusDescription(licenseProvider.status),
            style: theme.textTheme.bodySmall?.copyWith(
              color: DarkModeUtils.getTextColor(context).withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),

          // إذا كانت التجربة فعالة، عرض الأيام المتبقية
          if (licenseProvider.isTrialActive) ...[
            const SizedBox(height: 8),
            Text(
              'الأيام المتبقية في التجربة: ${licenseProvider.trialDaysLeft}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          // معلومات إضافية إذا كان الترخيص مفعل
          if (licenseProvider.isActivated &&
              licenseProvider.licenseInfo != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // معلومات الترخيص
            _buildLicenseInfo(licenseProvider.licenseInfo!, theme),
          ],

          // معلومات الجهاز
          if (licenseProvider.deviceInfo.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            _buildDeviceInfo(licenseProvider.deviceInfo, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildLicenseInfo(LicenseInfo licenseInfo, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'معلومات الترخيص:',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: DarkModeUtils.getTextColor(context),
          ),
        ),
        const SizedBox(height: 8),
        _buildInfoRow('مفتاح الترخيص', licenseInfo.licenseKey, theme),
        if (licenseInfo.activationDate.isNotEmpty)
          _buildInfoRow(
              'تاريخ التفعيل', _formatDate(licenseInfo.activationDate), theme),
        if (licenseInfo.customerInfo.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'معلومات العميل:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: DarkModeUtils.getTextColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            licenseInfo.customerInfo,
            style: theme.textTheme.bodySmall?.copyWith(
              color: DarkModeUtils.getTextColor(context).withOpacity(0.7),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDeviceInfo(Map<String, String> deviceInfo, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'معلومات الجهاز:',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: DarkModeUtils.getTextColor(context),
          ),
        ),
        const SizedBox(height: 8),
        ...deviceInfo.entries.map(
          (entry) => _buildInfoRow(entry.key, entry.value, theme),
        ),
        const SizedBox(height: 8),
        _buildInfoRow('البصمة الفريدة',
            context.read<LicenseProvider>().deviceFingerprint, theme),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: DarkModeUtils.getTextColor(context).withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: DarkModeUtils.getTextColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(LicenseProvider licenseProvider, ThemeData theme) {
    return Column(
      children: [
        // زر التفعيل
        if (licenseProvider.isNotActivated || licenseProvider.isInvalid)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () => _navigateToActivation(),
              icon: const Icon(Icons.key),
              label: const Text(
                'تفعيل الترخيص',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

        // زر إلغاء التفعيل
        if (licenseProvider.isActivated) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _showDeactivateDialog(),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text(
                'إلغاء التفعيل',
                style: TextStyle(fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],

        // زر إعادة الفحص
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => licenseProvider.checkLicenseStatus(),
            icon: const Icon(Icons.refresh),
            label: const Text(
              'إعادة فحص الترخيص',
              style: TextStyle(fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        // زر إعادة تعيين الترخيص (إذا كان هناك مشكلة)
        if (licenseProvider.hasError || licenseProvider.isInvalid) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _showResetLicenseDialog(),
              icon: const Icon(Icons.restart_alt),
              label: const Text(
                'إعادة تعيين الترخيص',
                style: TextStyle(fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getStatusTitle(LicenseStatus status) {
    switch (status) {
      case LicenseStatus.valid:
        return 'الترخيص مفعل';
      case LicenseStatus.notActivated:
        return 'الترخيص غير مفعل';
      case LicenseStatus.invalid:
        return 'مفتاح الترخيص غير صحيح';
      case LicenseStatus.deviceMismatch:
        return 'الجهاز لا يطابق الترخيص';
      case LicenseStatus.error:
        return 'خطأ في فحص الترخيص';
      case LicenseStatus.trialActive:
        return 'نسخة تجريبية فعالة';
      case LicenseStatus.trialExpired:
        return 'انتهت الفترة التجريبية';
    }
  }

  String _getStatusDescription(LicenseStatus status) {
    switch (status) {
      case LicenseStatus.valid:
        return 'يمكنك الآن استخدام جميع وظائف التطبيق';
      case LicenseStatus.notActivated:
        return 'يرجى إدخال مفتاح الترخيص لتفعيل التطبيق';
      case LicenseStatus.invalid:
        return 'المفتاح المستخدم غير صحيح أو تالف';
      case LicenseStatus.deviceMismatch:
        return 'هذا المفتاح مرتبط بجهاز آخر';
      case LicenseStatus.error:
        return 'حدث خطأ أثناء فحص الترخيص';
      case LicenseStatus.trialActive:
        return 'يمكنك استخدام التطبيق خلال الفترة التجريبية (30 يوم)';
      case LicenseStatus.trialExpired:
        return 'انتهت الفترة التجريبية. يرجى إدخال مفتاح الترخيص للمتابعة';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _navigateToActivation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LicenseActivationScreen(),
      ),
    );
  }

  void _showDeactivateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء تفعيل الترخيص'),
        content: const Text(
          'هل أنت متأكد من إلغاء تفعيل الترخيص؟\n'
          'سيتم إزالة جميع معلومات الترخيص من هذا الجهاز.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success =
                  await context.read<LicenseProvider>().deactivateLicense();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'تم إلغاء تفعيل الترخيص بنجاح'
                          : 'فشل في إلغاء تفعيل الترخيص',
                    ),
                    backgroundColor: success
                        ? Color(0xFF059669)
                        : Color(0xFFDC2626), // Professional Green/Red
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFDC2626), // Professional Red
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  void _showResetLicenseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة تعيين الترخيص'),
        content: const Text(
          'سيتم حذف جميع بيانات الترخيص الحالية.\n'
          'يمكنك بعد ذلك إدخال مفتاح ترخيص جديد.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success =
                  await context.read<LicenseProvider>().deactivateLicense();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          success ? Icons.check_circle : Icons.error,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            success
                                ? 'تم إعادة تعيين الترخيص بنجاح. يمكنك الآن إدخال مفتاح جديد.'
                                : 'فشل في إعادة تعيين الترخيص',
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: success
                        ? Color(0xFF059669)
                        : Color(0xFFDC2626), // Professional Green/Red
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFF59E0B), // Professional Orange
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }
}

class _LicenseCheckDialogState extends State<LicenseCheckDialog> {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // تهيئة مزود الترخيص عند بدء النافذة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LicenseProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final licenseProvider = context.watch<LicenseProvider>();
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'فحص الترخيص',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // حالة الترخيص
                    _buildLicenseStatus(licenseProvider, theme),

                    const SizedBox(height: 16),

                    // أزرار الإجراءات
                    _buildActionButtons(licenseProvider, theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLicenseStatus(LicenseProvider licenseProvider, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DarkModeUtils.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: licenseProvider.getStatusColor().withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          // أيقونة الحالة - أصغر
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: licenseProvider.getStatusColor().withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              licenseProvider.getStatusIcon(),
              size: 24,
              color: licenseProvider.getStatusColor(),
            ),
          ),

          const SizedBox(height: 12),

          // عنوان الحالة - أصغر
          Text(
            _getStatusTitle(licenseProvider.status),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: DarkModeUtils.getTextColor(context),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          // وصف الحالة - أصغر
          Text(
            _getStatusDescription(licenseProvider.status),
            style: theme.textTheme.bodySmall?.copyWith(
              color: DarkModeUtils.getTextColor(context).withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),

          // معلومات إضافية إذا كان الترخيص مفعل
          if (licenseProvider.isActivated &&
              licenseProvider.licenseInfo != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // معلومات الترخيص
            _buildLicenseInfo(licenseProvider.licenseInfo!, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(LicenseProvider licenseProvider, ThemeData theme) {
    return Column(
      children: [
        // زر تفعيل الترخيص (إذا لم يكن مفعل)
        if (!licenseProvider.isActivated) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LicenseActivationScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.key),
              label: const Text(
                'تفعيل الترخيص',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],

        // زر إلغاء التفعيل (إذا كان مفعل)
        if (licenseProvider.isActivated) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _showDeactivateDialog(),
              icon: const Icon(Icons.key_off),
              label: const Text(
                'إلغاء التفعيل',
                style: TextStyle(fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],

        // زر إعادة الفحص
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: _isChecking
                ? null
                : () async {
                    setState(() {
                      _isChecking = true;
                    });
                    try {
                      await licenseProvider.checkLicenseStatus();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'تم فحص الترخيص بنجاح',
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Color(0xFF059669),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  Icons.error,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'حدث خطأ أثناء فحص الترخيص',
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Color(0xFFDC2626),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isChecking = false;
                        });
                      }
                    }
                  },
            icon: _isChecking
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                : const Icon(Icons.refresh),
            label: Text(
              _isChecking ? 'جاري الفحص...' : 'إعادة فحص الترخيص',
              style: const TextStyle(fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        // زر إعادة تعيين الترخيص (إذا كان هناك مشكلة)
        if (licenseProvider.hasError || licenseProvider.isInvalid) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _showResetLicenseDialog(),
              icon: const Icon(Icons.restart_alt),
              label: const Text(
                'إعادة تعيين الترخيص',
                style: TextStyle(fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLicenseInfo(LicenseInfo licenseInfo, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('مفتاح الترخيص', licenseInfo.licenseKey),
        const SizedBox(height: 8),
        _buildInfoRow('تاريخ التفعيل', _formatDate(licenseInfo.activationDate)),
        // معلومات العميل (إذا كانت متوفرة)
        const SizedBox(height: 8),
        _buildInfoRow('البصمة', licenseInfo.deviceFingerprint),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusTitle(LicenseStatus status) {
    switch (status) {
      case LicenseStatus.valid:
        return 'الترخيص مفعل';
      case LicenseStatus.notActivated:
        return 'الترخيص غير مفعل';
      case LicenseStatus.invalid:
        return 'مفتاح الترخيص غير صحيح';
      case LicenseStatus.deviceMismatch:
        return 'الجهاز لا يطابق الترخيص';
      case LicenseStatus.error:
        return 'خطأ في فحص الترخيص';
      case LicenseStatus.trialActive:
        return 'نسخة تجريبية فعالة';
      case LicenseStatus.trialExpired:
        return 'انتهت الفترة التجريبية';
    }
  }

  String _getStatusDescription(LicenseStatus status) {
    switch (status) {
      case LicenseStatus.valid:
        return 'يمكنك الآن استخدام جميع وظائف التطبيق';
      case LicenseStatus.notActivated:
        return 'يرجى إدخال مفتاح الترخيص لتفعيل التطبيق';
      case LicenseStatus.invalid:
        return 'المفتاح المستخدم غير صحيح أو تالف';
      case LicenseStatus.deviceMismatch:
        return 'هذا المفتاح مرتبط بجهاز آخر';
      case LicenseStatus.error:
        return 'حدث خطأ أثناء فحص الترخيص';
      case LicenseStatus.trialActive:
        return 'يمكنك استخدام التطبيق خلال الفترة التجريبية (30 يوم)';
      case LicenseStatus.trialExpired:
        return 'انتهت الفترة التجريبية. يرجى إدخال مفتاح الترخيص للمتابعة';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  void _showDeactivateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء تفعيل الترخيص'),
        content: const Text(
          'هل أنت متأكد من إلغاء تفعيل الترخيص؟\n'
          'سيتم إزالة جميع معلومات الترخيص من هذا الجهاز.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success =
                  await context.read<LicenseProvider>().deactivateLicense();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'تم إلغاء تفعيل الترخيص بنجاح'
                          : 'فشل في إلغاء تفعيل الترخيص',
                    ),
                    backgroundColor: success
                        ? Color(0xFF059669)
                        : Color(0xFFDC2626), // Professional Green/Red
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFDC2626), // Professional Red
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  void _showResetLicenseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة تعيين الترخيص'),
        content: const Text(
          'سيتم حذف جميع بيانات الترخيص الحالية.\n'
          'يمكنك بعد ذلك إدخال مفتاح ترخيص جديد.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success =
                  await context.read<LicenseProvider>().deactivateLicense();

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          success ? Icons.check_circle : Icons.error,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            success
                                ? 'تم إعادة تعيين الترخيص بنجاح. يمكنك الآن إدخال مفتاح جديد.'
                                : 'فشل في إعادة تعيين الترخيص',
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: success
                        ? Color(0xFF059669)
                        : Color(0xFFDC2626), // Professional Green/Red
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFF59E0B), // Professional Orange
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }
}
