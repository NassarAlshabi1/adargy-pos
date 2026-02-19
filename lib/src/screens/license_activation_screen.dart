// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/license/license_service.dart';
import '../services/store_config.dart';
import '../utils/dark_mode_utils.dart';

class LicenseActivationScreen extends StatefulWidget {
  const LicenseActivationScreen({super.key});

  @override
  State<LicenseActivationScreen> createState() =>
      _LicenseActivationScreenState();
}

class _LicenseActivationScreenState extends State<LicenseActivationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseController = TextEditingController();

  final LicenseService _licenseService = LicenseService();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final storeConfig = context.watch<StoreConfig>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: DarkModeUtils.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: DarkModeUtils.getTextColor(context),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'تفعيل الترخيص',
          style: TextStyle(
            color: DarkModeUtils.getTextColor(context),
          ),
        ),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // شعار التطبيق
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.business_center,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // عنوان التطبيق
                      Text(
                        storeConfig.appTitle,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: DarkModeUtils.getTextColor(context),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'تجارتي',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: DarkModeUtils.getTextColor(context)
                              .withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 48),

                      // نموذج التفعيل
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: DarkModeUtils.getCardColor(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: DarkModeUtils.getBorderColor(context),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تفعيل الترخيص',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: DarkModeUtils.getTextColor(context),
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                'أدخل مفتاح الترخيص الذي تم إرساله لك',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: DarkModeUtils.getTextColor(context)
                                      .withOpacity(0.7),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // حقل مفتاح الترخيص
                              TextFormField(
                                controller: _licenseController,
                                decoration: InputDecoration(
                                  labelText: 'مفتاح الترخيص',
                                  hintText: 'OFFICE-2024-XXXXXX-XXXXXXXX',
                                  prefixIcon: const Icon(Icons.key),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'يرجى إدخال مفتاح الترخيص';
                                  }

                                  final cleanValue = value.toUpperCase().trim();
                                  if (!cleanValue.startsWith('OFFICE-')) {
                                    return 'يجب أن يبدأ المفتاح بـ OFFICE-';
                                  }

                                  // التحقق من التنسيق الأساسي
                                  final parts = cleanValue.split('-');
                                  if (parts.length < 4) {
                                    return 'تنسيق المفتاح غير صحيح. يجب أن يكون: OFFICE-YYYY-XXXXXX-XXXXXXXX';
                                  }

                                  return null;
                                },
                                textCapitalization:
                                    TextCapitalization.characters,
                              ),

                              const SizedBox(height: 24),

                              // زر التفعيل
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoading ? null : _activateLicense,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'تفعيل الترخيص',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // معلومات إضافية
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.primaryColor,
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'معلومات مهمة:',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '• مفتاح الترخيص مرتبط بهذا الجهاز فقط\n'
                              '• لا يمكن نقل الترخيص لجهاز آخر\n'
                              '• في حالة تغيير الجهاز، يرجى التواصل مع الدعم الفني',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: DarkModeUtils.getTextColor(context)
                                    .withOpacity(0.8),
                              ),
                              textAlign: TextAlign.center,
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

  Future<void> _activateLicense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result =
          await _licenseService.activateLicense(_licenseController.text.trim());

      if (result.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(result.message)),
                ],
              ),
              backgroundColor: Color(0xFF059669), // Professional Green
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );

          // تأخير بسيط قبل الانتقال
          await Future.delayed(const Duration(milliseconds: 500));

          // العودة للتطبيق الرئيسي
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/');
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(result.message)),
                ],
              ),
              backgroundColor: Color(0xFFDC2626), // Professional Red
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'إعادة المحاولة',
                textColor: Colors.white,
                onPressed: () {
                  _licenseController.clear();
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في التفعيل: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _licenseController.dispose();
    super.dispose();
  }
}
