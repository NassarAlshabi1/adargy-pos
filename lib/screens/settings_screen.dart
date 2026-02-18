import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

enum SettingsSection {
  percentage,
  appearance,
  all // Default or for general access
}

class SettingsScreen extends StatefulWidget {
  final SettingsSection sectionToShow;

  const SettingsScreen({super.key, this.sectionToShow = SettingsSection.all});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _percentageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // استرجاع القيمة المحفوظة مسبقًا عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsProvider =
          Provider.of<SettingsProvider>(context, listen: false);
      _percentageController.text =
          settingsProvider.engineerPercentage.toString();
    });
  }

  @override
  void dispose() {
    _percentageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    // Use settingsProvider.themeMode to determine isDark, instead of Theme.of(context).brightness
    // This ensures the UI reacts to the provider's state immediately.
    final isDark = settingsProvider.themeMode == ThemeMode.dark ||
        (settingsProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    bool showPercentageSettings =
        widget.sectionToShow == SettingsSection.percentage ||
            widget.sectionToShow == SettingsSection.all;
    bool showAppearanceSettings =
        widget.sectionToShow == SettingsSection.appearance ||
            widget.sectionToShow == SettingsSection.all;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'الإعدادات',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor:
              isDark ? Colors.grey.shade900 : AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showPercentageSettings) ...[
                    Text(
                      'إعدادات الحسابات',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // بطاقة نسبة المهندس
                    Card(
                      elevation: 2,
                      color: isDark ? Colors.grey.shade800 : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.engineering,
                                  color: isDark
                                      ? Colors.blue.shade300
                                      : AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'نسبة المهندس',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'أدخل النسبة المئوية لربح المهندس. سيتم استخدام هذه النسبة لجميع الإدخالات الجديدة.',
                              style: const TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _percentageController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'النسبة المئوية',
                                suffixText: '%',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade50,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'الرجاء إدخال النسبة المئوية';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'الرجاء إدخال رقم صحيح';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16), // Added space
                            Center(
                              // Center the save button for this card
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    final percentage = double.parse(
                                        _percentageController.text);
                                    settingsProvider
                                        .setEngineerPercentage(percentage);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'تم حفظ نسبة المهندس بنجاح',
                                          style: const TextStyle(),
                                          textAlign: TextAlign.center,
                                        ),
                                        backgroundColor: Colors.green.shade600,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.save_alt_outlined),
                                label: Text(
                                  'حفظ النسبة',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark
                                      ? Colors.teal.shade600
                                      : Colors.teal.shade500,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (showAppearanceSettings)
                      const SizedBox(
                          height: 24), // Add space only if both are shown
                  ],
                  if (showAppearanceSettings) ...[
                    Text(
                      'إعدادات المظهر',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      color: isDark ? Colors.grey.shade800 : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isDark
                                      ? Icons.brightness_7
                                      : Icons.brightness_4,
                                  color: isDark
                                      ? Colors.yellow.shade700
                                      : AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'وضع التطبيق',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              isDark
                                  ? 'التطبيق حاليًا في الوضع الداكن.'
                                  : 'التطبيق حاليًا في الوضع الفاتح.',
                              style: const TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  settingsProvider.toggleThemeMode();
                                },
                                icon: Icon(isDark
                                    ? Icons.light_mode
                                    : Icons.dark_mode),
                                label: Text(
                                  isDark
                                      ? 'التحويل إلى الوضع الفاتح'
                                      : 'التحويل إلى الوضع الداكن',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark
                                      ? AppTheme.accentColor
                                      : AppTheme.secondaryColor,
                                  foregroundColor:
                                      isDark ? Colors.black87 : Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24), // Added space at the bottom
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
