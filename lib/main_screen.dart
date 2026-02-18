import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:daily/models/entry.dart';
import 'package:daily/providers/entry_provider.dart';
import 'package:daily/providers/settings_provider.dart';

import 'screens/daily_reports/daily_reports.dart';
import 'screens/statistics_screen.dart';
import 'screens/customer_screen/customers_screen.dart';
import 'screens/settlements_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/entry_form.dart';
import 'database/customer_database_helper.dart';
import 'theme/app_theme.dart';
import 'widgets/common/custom_app_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  // Constants
  static const String appVersion = '1.0.0';
  static const List<String> _tabTitles = [
    'التقارير اليومية',
    'الإحصائيات',
    'العملاء',
    'السدادات',
  ];

  // State variables
  int _currentIndex = 0;
  late TabController _tabController;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // Screen definitions
  final List<Widget> _screens = const [
    DailyReportsScreen(),
    StatisticsScreen(),
    CustomersScreen(),
    SettlementsScreen(),
  ];

  // Tab navigation data
  final List<_NavItemData> _navItems = [
    const _NavItemData(
      label: 'التقارير',
      activeIcon: Icons.assignment,
      inactiveIcon: Icons.assignment_outlined,
    ),
    const _NavItemData(
      label: 'الإحصائيات',
      activeIcon: Icons.bar_chart,
      inactiveIcon: Icons.bar_chart_outlined,
    ),
    const _NavItemData(
      label: 'العملاء',
      activeIcon: Icons.people,
      inactiveIcon: Icons.people_outline,
    ),
    const _NavItemData(
      label: 'السدادات',
      activeIcon: Icons.check_circle,
      inactiveIcon: Icons.check_circle_outline,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _screens.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadEntries();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Event handlers
  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _currentIndex = _tabController.index;
      });
    }
  }

  void _loadEntries() async {
    await Provider.of<EntryProvider>(context, listen: false).loadEntries();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  void _backupData() async {
    try {
      // جمع البيانات من مصادر مختلفة
      final entryProvider = Provider.of<EntryProvider>(context, listen: false);
      final customerDbHelper = CustomerDatabaseHelper();

      // بيانات الإدخالات
      final entries = entryProvider.entries;
      final entriesData = entries.map((entry) => entry.toJson()).toList();

      // بيانات العملاء (جميع العملاء بما في ذلك المسددين)
      final allCustomers = await customerDbHelper.database.then((db) async {
        final maps = await db.query('customers');
        return maps;
      });

      // بيانات المعاملات
      final allTransactions = await customerDbHelper.database.then((db) async {
        final maps = await db.query('transactions');
        return maps;
      });

      // بيانات السدادات
      final allSettlements = await customerDbHelper.getAllSettlements();

      // تجميع جميع البيانات
      final backupData = {
        'timestamp': DateTime.now().toIso8601String(),
        'version': '4.0', // إصدار قاعدة البيانات
        'entries': entriesData,
        'customers': allCustomers,
        'transactions': allTransactions,
        'settlements': allSettlements,
      };

      final directoryPath = await FilePicker.platform.getDirectoryPath();
      if (directoryPath == null) return;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile =
          await File('$directoryPath/backup_complete_$timestamp.json').create();
      await backupFile.writeAsString(json.encode(backupData));

      if (mounted) {
        _showSnackBar(
          'تم حفظ النسخة الاحتياطية الكاملة بنجاح',
          AppTheme.successColor,
          Icons.check_circle,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'فشل في حفظ النسخة الاحتياطية: $e',
          AppTheme.dangerColor,
          Icons.error,
        );
      }
    }
  }

  void _restoreData() async {
    try {
      // استخدام FilePicker لاختيار ملف النسخة الاحتياطية
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'اختر ملف النسخة الاحتياطية',
      );

      if (result == null || result.files.isEmpty) {
        // المستخدم ألغى اختيار الملف
        return;
      }

      // قراءة محتوى الملف
      final filePath = result.files.single.path;
      if (filePath == null) {
        throw Exception('مسار الملف غير صالح');
      }

      final file = File(filePath);
      final jsonString = await file.readAsString();

      // إظهار مربع حوار التأكيد قبل استعادة البيانات
      final bool? confirmRestore = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'تأكيد استعادة البيانات',
            style: const TextStyle(fontFamily: 'Arial', fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
          content: Text(
            'سيتم استبدال جميع البيانات الحالية (الإدخالات، العملاء، المعاملات، السدادات) بالنسخة الاحتياطية المختارة. هل أنت متأكد من المتابعة؟',
            style: const TextStyle(fontFamily: 'Arial'),
            textDirection: ui.TextDirection.rtl,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('إلغاء', style: const TextStyle(fontFamily: 'Arial')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('استعادة', style: const TextStyle(fontFamily: 'Arial')),
            ),
          ],
          actionsAlignment: MainAxisAlignment.spaceBetween,
        ),
      );

      if (confirmRestore != true) {
        return;
      }

      // تحليل البيانات
      Map<String, dynamic> backupData;
      try {
        backupData = json.decode(jsonString);
      } catch (e) {
        // محاولة التعامل مع النسخ الاحتياطية القديمة
        final cleanedJsonString = jsonString.replaceAll(RegExp(r'\[|\]'), '');
        final entriesJsonList = cleanedJsonString.split('},').map((entryStr) {
          if (!entryStr.endsWith('}')) {
            return '$entryStr}';
          }
          return entryStr;
        }).toList();

        backupData = {
          'entries': entriesJsonList
              .map((jsonStr) {
                if (jsonStr.isEmpty) return null;
                try {
                  return json.decode(jsonStr);
                } catch (e) {
                  return null;
                }
              })
              .where((item) => item != null)
              .toList(),
          'customers': [],
          'transactions': [],
          'settlements': [],
        };
      }

      final entryProvider = Provider.of<EntryProvider>(context, listen: false);
      final customerDbHelper = CustomerDatabaseHelper();

      int restoredCount = 0;

      // استعادة الإدخالات
      if (backupData['entries'] != null) {
        List<Entry> restoredEntries = [];
        for (var entryData in backupData['entries']) {
          try {
            final entry = Entry.fromMap(entryData);
            restoredEntries.add(entry);
          } catch (e) {
            print('خطأ في تحليل إدخال: $e');
          }
        }
        await entryProvider.restoreEntries(restoredEntries);
        restoredCount += restoredEntries.length;
      }

      // استعادة بيانات العملاء والمعاملات والسدادات
      if (backupData['customers'] != null ||
          backupData['transactions'] != null ||
          backupData['settlements'] != null) {
        final customers =
            List<Map<String, dynamic>>.from(backupData['customers'] ?? []);
        final transactions =
            List<Map<String, dynamic>>.from(backupData['transactions'] ?? []);
        final settlements =
            List<Map<String, dynamic>>.from(backupData['settlements'] ?? []);

        await customerDbHelper.restoreBackupData(
          customers: customers,
          transactions: transactions,
          settlements: settlements,
        );

        restoredCount +=
            customers.length + transactions.length + settlements.length;
      }

      // تحديث واجهة المستخدم بعد الاستعادة
      _loadEntries();

      if (mounted) {
        _showSnackBar(
          'تم استعادة البيانات بنجاح ($restoredCount عنصر)',
          AppTheme.successColor,
          Icons.check_circle,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'فشل في استعادة البيانات: $e',
          AppTheme.dangerColor,
          Icons.error,
        );
      }
    }
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontFamily: 'Arial',
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        appBar: _buildAppBar(isDark),
        drawer: _buildDrawer(isDark),
        body: TabBarView(
          controller: _tabController,
          physics: const ClampingScrollPhysics(),
          children: _screens,
        ),
        bottomNavigationBar: _buildBottomNavigationBar(isDark),
        floatingActionButton: _buildFloatingActionButton(isDark),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }

  // UI Building methods
  PreferredSizeWidget _buildAppBar(bool isDark) {
    return CustomAppBar(
      title: _isSearching ? '' : _tabTitles[_currentIndex],
      centerTitle: true,
      elevation: AppTheme.mediumElevation,
      actions: [
        IconButton(
          icon: Icon(
            isDark ? Icons.brightness_7 : Icons.brightness_4,
          ),
          onPressed: () {
            Provider.of<SettingsProvider>(context, listen: false)
                .toggleThemeMode();
          },
          tooltip: isDark ? 'الوضع النهاري' : 'الوضع الليلي',
        ),
      ],
      // bottom: _isSearching ? _buildSearchBar(isDark) : null,
    );
  }

  // PreferredSize _buildSearchBar(bool isDark) {
  //   return PreferredSize(
  //     preferredSize: const Size.fromHeight(60),
  //     child: Padding(
  //       padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
  //       child: TextField(
  //         controller: _searchController,
  //         textDirection: ui.TextDirection.rtl,
  //         style: const TextStyle(),
  //         decoration: InputDecoration(
  //           hintText: 'بحث...',
  //           hintTextDirection: ui.TextDirection.rtl,
  //           filled: true,
  //           fillColor: isDark ? AppTheme.darkCardColor : Colors.white,
  //           prefixIcon: const Icon(Icons.search),
  //           border: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(10),
  //             borderSide: BorderSide.none,
  //           ),
  //           contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
  //         ),
  //         onChanged: (value) {
  //           // Implement search functionality
  //         },
  //       ),
  //     ),
  //   );
  // }

  Widget _buildDrawer(bool isDark) {
    final Color drawerColor =
        isDark ? AppTheme.darkScaffoldColor : Colors.white;

    return Drawer(
      backgroundColor: drawerColor,
      elevation: isDark ? 1 : 4,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(0),
          bottomLeft: Radius.circular(0),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(isDark),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 8),
                  _DrawerSectionTitle(title: 'البيانات', isDark: isDark),
                  _buildDrawerItem(
                    icon: Icons.restore,
                    title: 'استرجاع البيانات',
                    onTap: () {
                      Navigator.pop(context);
                      _restoreData();
                    },
                    isDark: isDark,
                  ),
                  _buildDrawerItem(
                    icon: Icons.backup,
                    title: 'نسخة احتياطية',
                    onTap: () {
                      Navigator.pop(context);
                      _backupData();
                    },
                    isDark: isDark,
                  ),
                  const Divider(),
                  _DrawerSectionTitle(title: 'إعدادات النسبة', isDark: isDark),
                  _buildDrawerItem(
                    icon: Icons.calculate_outlined,
                    title: 'اضافه نسبة المهندس',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(
                              sectionToShow: SettingsSection.percentage),
                        ),
                      );
                    },
                    isDark: isDark,
                  ),
                  const Divider(),
                  _DrawerSectionTitle(title: 'إعدادات المظهر', isDark: isDark),
                  _buildDrawerItem(
                    icon: Icons.brightness_6_outlined,
                    title: 'تغيير المظهر',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(
                              sectionToShow: SettingsSection.appearance),
                        ),
                      );
                    },
                    isDark: isDark,
                  ),
                  const Divider(),
                  _DrawerSectionTitle(title: 'حول', isDark: isDark),
                  _buildDrawerItem(
                    icon: Icons.info_outline,
                    title: 'حول التطبيق',
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutDialog();
                    },
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _AppVersion(isDark: isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'دفتر مهندس',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Arial',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'إدارة العملاء والتقارير اليومية',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontFamily: 'Arial',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDark ? Colors.white70 : Colors.grey.shade700,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : Colors.grey.shade800,
        ),
      ),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      hoverColor: isDark
          ? Colors.white.withOpacity(0.05)
          : Colors.grey.withOpacity(0.1),
    );
  }

  Widget _buildBottomNavigationBar(bool isDark) {
    final Color backgroundColor =
        isDark ? AppTheme.darkCardColor : Colors.white;
    final Color shadowColor = Colors.black.withOpacity(isDark ? 0.2 : 0.05);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // العنصر الأول
              _buildNavItem(0, isDark),
              // العنصر الثاني
              _buildNavItem(1, isDark),
              // مساحة فارغة للزر العائم
              const SizedBox(width: 60),
              // العنصر الثالث
              _buildNavItem(2, isDark),
              // العنصر الرابع
              _buildNavItem(3, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(bool isDark) {
    return FloatingActionButton(
      onPressed: () {
        // فتح نموذج إضافة إدخال جديد
        final entryFormHelper = EntryFormHelper();
        entryFormHelper.showEntryInputDialog(context);
      },
      backgroundColor: isDark ? AppTheme.secondaryColor : AppTheme.primaryColor,
      foregroundColor: Colors.white,
      elevation: 8,
      child: const Icon(
        Icons.add,
        size: 28,
      ),
    );
  }

  Widget _buildNavItem(int index, bool isDark) {
    final bool isSelected = _currentIndex == index;
    final _NavItemData item = _navItems[index];

    final Color activeColor =
        isDark ? AppTheme.secondaryColor : AppTheme.primaryColor;
    final Color inactiveColor =
        isDark ? Colors.grey.shade400 : AppTheme.lightSecondaryTextColor;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentIndex = index;
              _tabController.animateTo(index);
            });
          },
          borderRadius: BorderRadius.circular(12),
          splashColor: activeColor.withOpacity(0.1),
          highlightColor: activeColor.withOpacity(0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                      ? activeColor.withOpacity(0.15)
                      : activeColor.withOpacity(0.08))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? item.activeIcon : item.inactiveIcon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    color: isSelected ? activeColor : inactiveColor,
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontFamily: 'Arial',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor =
        isDark ? AppTheme.darkCardColor : Colors.white;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'حول التطبيق',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey.shade800,
          ),
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: SvgPicture.asset(
                    'lib/assets/images/app_logo.svg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'دفتر مهندس',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                  fontFamily: 'Arial',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'تطبيق لإدارة العملاء والتقارير اليومية',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                  fontFamily: 'Arial',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _AboutInfoItem(
                rtl: false,
                icon: Icons.info_outline,
                label: 'الإصدار',
                value: appVersion,
                isDark: isDark,
              ),
              _AboutInfoItem(
                rtl: true,
                icon: Icons.calendar_month_outlined,
                label: 'تاريخ التطوير',
                value: '2025',
                isDark: isDark,
              ),
              _AboutInfoItem(
                rtl: true,
                icon: Icons.code_outlined,
                label: 'بواسطة',
                value: "م / وليد السقاف",
                isDark: isDark,
              ),
            ],
          ),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'موافق',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper widgets
class _DrawerSectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;

  const _DrawerSectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16, left: 16, top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _AppVersion extends StatelessWidget {
  final bool isDark;

  const _AppVersion({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Text(
        'الإصدار ${_MainScreenState.appVersion}',
        style: TextStyle(
          color: isDark
              ? AppTheme.darkSecondaryTextColor
              : AppTheme.lightSecondaryTextColor,
          fontSize: 12,
          fontFamily: 'Arial',
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _AboutInfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final bool rtl;

  const _AboutInfoItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    required this.rtl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Directionality(
        textDirection: ui.TextDirection.ltr,
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isDark
                  ? AppTheme.darkSecondaryTextColor
                  : AppTheme.lightSecondaryTextColor,
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey.shade800,
              ),
              textAlign: TextAlign.left,
            ),
            const Spacer(),
            Text(
              '$label ',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppTheme.darkSecondaryTextColor
                    : AppTheme.lightSecondaryTextColor,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }
}

// Data class for navigation items
class _NavItemData {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;

  const _NavItemData({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });
}
