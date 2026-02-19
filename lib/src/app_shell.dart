import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth/auth_provider.dart';
import 'services/store_config.dart';
import 'services/theme_provider.dart';
import 'services/license/license_provider.dart';
import 'services/db/database_service.dart';
import 'utils/strings.dart';
import 'utils/app_themes.dart';
import 'utils/dark_mode_utils.dart';
import 'utils/responsive_utils.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/products/products_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/suppliers_screen.dart';
import 'screens/sales_screen.dart';
import 'screens/sales_history_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/debts_screen.dart';
import 'screens/unified_reports_screen.dart';
import 'screens/license_check_screen.dart';
import 'screens/users_management_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/returns_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/event_log_screen.dart';
import 'screens/deleted_items_screen.dart';
import 'screens/product_discounts_screen.dart';
import 'screens/discount_coupons_screen.dart';
import 'models/user_model.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

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
    final auth = context.watch<AuthProvider>();
    final store = context.watch<StoreConfig>();
    final themeProvider = context.watch<ThemeProvider>();
    final licenseProvider = context.watch<LicenseProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final gradients = theme.extension<AppGradients>();

    // Get screen dimensions for responsive design
    final isSmallScreen = ResponsiveUtils.isSmallScreen(context);
    final isMediumScreen = ResponsiveUtils.isMediumScreen(context);
    final isLargeScreen = ResponsiveUtils.isLargeScreen(context);

    // Update theme provider with current system brightness
    WidgetsBinding.instance.addPostFrameCallback((_) {
      themeProvider.updateDarkModeStatus(isDark);
    });

    // فحص الترخيص أولاً (يسمح بالتجربة المجانية)
    if (!licenseProvider.isActivated && !licenseProvider.isTrialActive) {
      return const LicenseCheckScreen();
    }

    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    // Disabled forced password change screen on default login per request

    final pages = <Widget>[
      const DashboardScreen(),
      const SalesScreen(),
      const SalesHistoryScreen(),
      const ProductsScreen(),
      const CategoriesScreen(),
      const ProductDiscountsScreen(), // خصومات المنتجات
      const DiscountCouponsScreen(), // كوبونات الخصم
      const InventoryScreen(),
      const CustomersScreen(),
      const SuppliersScreen(),
      const ExpensesScreen(), // المصروفات
      const ReturnsScreen(), // المرتجعات
      const DebtsScreen(), // الديون
      const UnifiedReportsScreen(), // التقارير الموحدة
      const AnalyticsScreen(), // التحليلات
      const EventLogScreen(), // سجل الأحداث
      const DeletedItemsScreen(), // سلة المحذوفات
      const SettingsScreen(),
      const UsersManagementScreen(), // إدارة المستخدمين
    ];

    bool canAccessIndex(int index) {
      switch (index) {
        case 0:
          return true; // Dashboard متاح للجميع بعد تسجيل الدخول
        case 1:
          return auth.hasPermission(UserPermission.manageSales);
        case 2:
          return auth.hasPermission(UserPermission.viewReports);
        case 3:
          return auth.hasPermission(UserPermission.manageProducts);
        case 4:
          return auth.hasPermission(UserPermission.manageCategories);
        case 5:
          return auth
              .hasPermission(UserPermission.manageProducts); // خصومات المنتجات
        case 6:
          return auth
              .hasPermission(UserPermission.manageProducts); // كوبونات الخصم
        case 7:
          return auth.hasPermission(UserPermission.manageInventory);
        case 8:
          return auth.hasPermission(UserPermission.manageCustomers);
        case 9:
          return auth.hasPermission(UserPermission.manageSuppliers);
        case 10:
          return auth.hasPermission(UserPermission.viewReports); // المصروفات
        case 11:
          return auth.hasPermission(UserPermission.manageSales); // المرتجعات
        case 12:
          return auth.hasPermission(UserPermission.viewReports); // الديون
        case 13:
          return auth
              .hasPermission(UserPermission.viewReports); // التقارير الموحدة
        case 14:
          // التحليلات - للمدير فقط
          return auth.isManager;
        case 15:
          // سجل الأحداث - للمدير فقط
          return auth.isManager;
        case 16:
          // سلة المحذوفات - للمدير فقط
          return auth.isManager;
        case 17:
          return auth.hasPermission(UserPermission.systemSettings);
        case 18:
          return auth.hasPermission(UserPermission.manageUsers);
        default:
          return false;
      }
    }

    // منع الوصول غير المصرّح به عند تغيير المستخدم أو الصلاحيات
    if (!canAccessIndex(_selectedIndex)) {
      _selectedIndex = 0;
    }

    return Scaffold(
      appBar: isSmallScreen
          ? null
          : AppBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    store.appTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              leading: _selectedIndex != 0
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => _selectedIndex = 0),
                      tooltip: 'العودة للرئيسية',
                    )
                  : null,
              actions: [
                // زر التنبيهات (ثابت في AppBar)
                _InventoryAlertsButton(),
                // Dark mode toggle button
                IconButton(
                  tooltip: themeProvider.isDarkMode
                      ? 'الوضع الفاتح'
                      : 'الوضع المظلم',
                  icon: Icon(themeProvider.isDarkMode
                      ? Icons.light_mode
                      : Icons.dark_mode),
                  onPressed: () => themeProvider.toggleTheme(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                    child: Text(
                      auth.currentUserName.isNotEmpty
                          ? auth.currentUserName
                          : 'المستخدم',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: AppStrings.logout,
                  icon: const Icon(Icons.logout),
                  onPressed: () => context.read<AuthProvider>().logout(),
                ),
              ],
              bottom: licenseProvider.isTrialActive
                  ? PreferredSize(
                      preferredSize: const Size.fromHeight(36),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        color: Colors.blue.withOpacity(0.1),
                        child: Row(
                          children: [
                            const Icon(Icons.hourglass_bottom,
                                size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'نسخة تجريبية: متبقّي ${context.read<LicenseProvider>().trialDaysLeft} يوم',
                                style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const LicenseCheckScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.key, size: 16),
                              label: const Text('تفعيل الآن'),
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : null,
            ),
      body: isSmallScreen
          ? _buildMobileLayout(context, pages, canAccessIndex, auth, store,
              themeProvider, licenseProvider, scheme, isDark, gradients)
          : _buildDesktopLayout(
              context,
              pages,
              canAccessIndex,
              auth,
              store,
              themeProvider,
              licenseProvider,
              scheme,
              isDark,
              gradients,
              isSmallScreen,
              isMediumScreen,
              isLargeScreen),
      bottomNavigationBar: isSmallScreen
          ? _buildBottomNavigation(context, canAccessIndex)
          : null,
    );
  }

  Widget _buildMobileLayout(
      BuildContext context,
      List<Widget> pages,
      bool Function(int) canAccessIndex,
      AuthProvider auth,
      StoreConfig store,
      ThemeProvider themeProvider,
      LicenseProvider licenseProvider,
      ColorScheme scheme,
      bool isDark,
      AppGradients? gradients) {
    return Column(
      children: [
        // Mobile header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                gradients?.sidebarStart ?? scheme.primary.withOpacity(0.08),
                gradients?.sidebarMiddle ?? scheme.primary.withOpacity(0.12),
                gradients?.sidebarEnd ?? scheme.primary.withOpacity(0.16),
              ],
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => _showMobileMenu(context, canAccessIndex),
                    icon: const Icon(Icons.menu),
                    tooltip: 'القائمة',
                  ),
                  Expanded(
                    child: Text(
                      store.appTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    tooltip: themeProvider.isDarkMode
                        ? 'الوضع الفاتح'
                        : 'الوضع المظلم',
                    icon: Icon(themeProvider.isDarkMode
                        ? Icons.light_mode
                        : Icons.dark_mode),
                    onPressed: () => themeProvider.toggleTheme(),
                  ),
                  IconButton(
                    tooltip: AppStrings.logout,
                    icon: const Icon(Icons.logout),
                    onPressed: () => context.read<AuthProvider>().logout(),
                  ),
                ],
              ),
              if (licenseProvider.isTrialActive)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_bottom,
                          size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'نسخة تجريبية: متبقّي ${licenseProvider.trialDaysLeft} يوم',
                          style: TextStyle(color: scheme.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Main content
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey(_selectedIndex),
              child: canAccessIndex(_selectedIndex)
                  ? pages[_selectedIndex]
                  : const Center(
                      child: Text('صلاحيات غير كافية للوصول إلى هذه الصفحة'),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(
      BuildContext context,
      List<Widget> pages,
      bool Function(int) canAccessIndex,
      AuthProvider auth,
      StoreConfig store,
      ThemeProvider themeProvider,
      LicenseProvider licenseProvider,
      ColorScheme scheme,
      bool isDark,
      AppGradients? gradients,
      bool isSmallScreen,
      bool isMediumScreen,
      bool isLargeScreen) {
    return Row(
      children: [
        // Enhanced Sidebar with better design
        Container(
          width: ResponsiveUtils.getResponsiveSidebarWidth(context),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      gradients?.sidebarStart ??
                          scheme.primary.withOpacity(0.08),
                      gradients?.sidebarMiddle ??
                          scheme.primary.withOpacity(0.12),
                      gradients?.sidebarEnd ?? scheme.primary.withOpacity(0.16),
                    ]
                  : [
                      scheme.surface,
                      scheme.surfaceContainerHighest.withOpacity(0.3),
                      scheme.surfaceContainerHighest.withOpacity(0.5),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: DarkModeUtils.getShadowColor(context),
                blurRadius: 10,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header section
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      scheme.primary,
                      scheme.primary.withOpacity(0.85),
                      scheme.primaryContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0.0, 0.6, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/images/soft.png',
                        height: 36,
                        width: 36,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppStrings.mainMenu,
                            style: TextStyle(
                              color: scheme.onPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            AppStrings.selectSection,
                            style: TextStyle(
                              color: scheme.onPrimary.withOpacity(0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Navigation items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _buildNavItem(
                      icon: Icons.space_dashboard,
                      label: AppStrings.dashboard,
                      index: 0,
                      isSelected: _selectedIndex == 0,
                    ),
                    if (canAccessIndex(1))
                      _buildNavItem(
                        icon: Icons.point_of_sale,
                        label: AppStrings.sales,
                        index: 1,
                        isSelected: _selectedIndex == 1,
                      ),
                    if (canAccessIndex(2))
                      _buildNavItem(
                        icon: Icons.history,
                        label: AppStrings.salesHistory,
                        index: 2,
                        isSelected: _selectedIndex == 2,
                      ),
                    if (canAccessIndex(3))
                      _buildNavItem(
                        icon: Icons.inventory_2,
                        label: AppStrings.products,
                        index: 3,
                        isSelected: _selectedIndex == 3,
                      ),
                    if (canAccessIndex(4))
                      _buildNavItem(
                        icon: Icons.category,
                        label: AppStrings.categories,
                        index: 4,
                        isSelected: _selectedIndex == 4,
                      ),
                    if (canAccessIndex(5))
                      _buildNavItem(
                        icon: Icons.local_offer,
                        label: 'خصومات المنتجات',
                        index: 5,
                        isSelected: _selectedIndex == 5,
                      ),
                    if (canAccessIndex(6))
                      _buildNavItem(
                        icon: Icons.card_giftcard,
                        label: 'كوبونات الخصم',
                        index: 6,
                        isSelected: _selectedIndex == 6,
                      ),
                    if (canAccessIndex(7))
                      _buildNavItem(
                        icon: Icons.warehouse,
                        label: AppStrings.inventory,
                        index: 7,
                        isSelected: _selectedIndex == 7,
                      ),
                    if (canAccessIndex(8))
                      _buildNavItem(
                        icon: Icons.people_alt,
                        label: AppStrings.customers,
                        index: 8,
                        isSelected: _selectedIndex == 8,
                      ),
                    if (canAccessIndex(9))
                      _buildNavItem(
                        icon: Icons.local_shipping,
                        label: AppStrings.suppliers,
                        index: 9,
                        isSelected: _selectedIndex == 9,
                      ),
                    if (canAccessIndex(10))
                      _buildNavItem(
                        icon: Icons.receipt_long,
                        label: 'المصروفات',
                        index: 10,
                        isSelected: _selectedIndex == 10,
                      ),
                    if (canAccessIndex(11))
                      _buildNavItem(
                        icon: Icons.assignment_return,
                        label: 'المرتجعات',
                        index: 11,
                        isSelected: _selectedIndex == 11,
                      ),
                    if (canAccessIndex(12))
                      _buildNavItem(
                        icon: Icons.payments,
                        label: AppStrings.debts,
                        index: 12,
                        isSelected: _selectedIndex == 12,
                      ),
                    if (canAccessIndex(13))
                      _buildNavItem(
                        icon: Icons.assessment,
                        label: 'التقارير الموحدة',
                        index: 13,
                        isSelected: _selectedIndex == 13,
                      ),
                    if (canAccessIndex(14))
                      _buildNavItem(
                        icon: Icons.analytics,
                        label: 'التحليلات',
                        index: 14,
                        isSelected: _selectedIndex == 14,
                      ),
                    if (canAccessIndex(15))
                      _buildNavItem(
                        icon: Icons.history,
                        label: 'سجل الأحداث',
                        index: 15,
                        isSelected: _selectedIndex == 15,
                      ),
                    if (canAccessIndex(16))
                      _buildNavItem(
                        icon: Icons.delete_outline,
                        label: 'سلة المحذوفات',
                        index: 16,
                        isSelected: _selectedIndex == 16,
                      ),
                    // إدارة المستخدمين - للمديرين فقط
                    if (canAccessIndex(18))
                      _buildNavItem(
                        icon: Icons.people,
                        label: 'إدارة المستخدمين',
                        index: 18,
                        isSelected: _selectedIndex == 18,
                      ),
                    if (canAccessIndex(17))
                      _buildNavItem(
                        icon: Icons.settings,
                        label: AppStrings.settings,
                        index: 17,
                        isSelected: _selectedIndex == 17,
                      ),
                  ],
                ),
              ),

              // Footer section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: scheme.primary.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          scheme.primaryContainer.withOpacity(0.25),
                      child: Icon(
                        Icons.person,
                        color: scheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.currentUserName.isNotEmpty
                                ? auth.currentUserName
                                : AppStrings.user,
                            style: TextStyle(
                              color: DarkModeUtils.getTextColor(context),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            auth.currentUserRole.isNotEmpty
                                ? auth.currentUserRole
                                : AppStrings.activeUser,
                            style: TextStyle(
                              color:
                                  DarkModeUtils.getSecondaryTextColor(context),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const VerticalDivider(width: 1),

        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: Container(
              key: ValueKey(_selectedIndex),
              child: canAccessIndex(_selectedIndex)
                  ? pages[_selectedIndex]
                  : const Center(
                      child: Text('صلاحيات غير كافية للوصول إلى هذه الصفحة'),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(
      BuildContext context, bool Function(int) canAccessIndex) {
    // Create a list of accessible indices for mobile navigation
    final accessibleIndices = <int>[];
    if (canAccessIndex(0)) accessibleIndices.add(0);
    if (canAccessIndex(1)) accessibleIndices.add(1);
    if (canAccessIndex(3)) accessibleIndices.add(3);
    if (canAccessIndex(6)) accessibleIndices.add(6);
    if (canAccessIndex(13)) accessibleIndices.add(13);

    // Ensure we always have at least the dashboard (index 0)
    if (accessibleIndices.isEmpty) {
      accessibleIndices.add(0);
    }

    // Find the current index in the accessible indices
    int currentBottomNavIndex = 0;
    if (accessibleIndices.contains(_selectedIndex)) {
      currentBottomNavIndex = accessibleIndices.indexOf(_selectedIndex);
    } else {
      // If current _selectedIndex is not accessible, default to first accessible index
      currentBottomNavIndex = 0;
      _selectedIndex = accessibleIndices[0];
    }

    // Ensure currentBottomNavIndex is within bounds
    currentBottomNavIndex =
        currentBottomNavIndex.clamp(0, accessibleIndices.length - 1);

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentBottomNavIndex,
      onTap: (index) {
        if (index < accessibleIndices.length) {
          setState(() => _selectedIndex = accessibleIndices[index]);
        }
      },
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor:
          Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      items: accessibleIndices.map((index) {
        switch (index) {
          case 0:
            return const BottomNavigationBarItem(
              icon: Icon(Icons.space_dashboard),
              label: 'الرئيسية',
            );
          case 1:
            return const BottomNavigationBarItem(
              icon: Icon(Icons.point_of_sale),
              label: 'المبيعات',
            );
          case 3:
            return const BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2),
              label: 'المنتجات',
            );
          case 6:
            return const BottomNavigationBarItem(
              icon: Icon(Icons.card_giftcard),
              label: 'كوبونات الخصم',
            );
          case 8:
            return const BottomNavigationBarItem(
              icon: Icon(Icons.people_alt),
              label: 'العملاء',
            );
          case 13:
            return const BottomNavigationBarItem(
              icon: Icon(Icons.assessment),
              label: 'التقارير',
            );
          case 17:
            return const BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'الإعدادات',
            );
          default:
            return const BottomNavigationBarItem(
              icon: Icon(Icons.space_dashboard),
              label: 'الرئيسية',
            );
        }
      }).toList(),
    );
  }

  void _showMobileMenu(
      BuildContext context, bool Function(int) canAccessIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.menu,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'القائمة الرئيسية',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildMobileNavItem(
                    icon: Icons.space_dashboard,
                    label: 'الرئيسية',
                    index: 0,
                    isSelected: _selectedIndex == 0,
                    canAccess: canAccessIndex(0),
                  ),
                  if (canAccessIndex(1))
                    _buildMobileNavItem(
                      icon: Icons.point_of_sale,
                      label: 'المبيعات',
                      index: 1,
                      isSelected: _selectedIndex == 1,
                      canAccess: true,
                    ),
                  if (canAccessIndex(2))
                    _buildMobileNavItem(
                      icon: Icons.history,
                      label: 'تاريخ المبيعات',
                      index: 2,
                      isSelected: _selectedIndex == 2,
                      canAccess: true,
                    ),
                  if (canAccessIndex(3))
                    _buildMobileNavItem(
                      icon: Icons.inventory_2,
                      label: 'المنتجات',
                      index: 3,
                      isSelected: _selectedIndex == 3,
                      canAccess: true,
                    ),
                  if (canAccessIndex(4))
                    _buildMobileNavItem(
                      icon: Icons.category,
                      label: 'الأقسام',
                      index: 4,
                      isSelected: _selectedIndex == 4,
                      canAccess: true,
                    ),
                  if (canAccessIndex(5))
                    _buildMobileNavItem(
                      icon: Icons.local_offer,
                      label: 'خصومات المنتجات',
                      index: 5,
                      isSelected: _selectedIndex == 5,
                      canAccess: true,
                    ),
                  if (canAccessIndex(6))
                    _buildMobileNavItem(
                      icon: Icons.card_giftcard,
                      label: 'كوبونات الخصم',
                      index: 6,
                      isSelected: _selectedIndex == 6,
                      canAccess: true,
                    ),
                  if (canAccessIndex(7))
                    _buildMobileNavItem(
                      icon: Icons.warehouse,
                      label: 'المخزون',
                      index: 7,
                      isSelected: _selectedIndex == 7,
                      canAccess: true,
                    ),
                  if (canAccessIndex(8))
                    _buildMobileNavItem(
                      icon: Icons.people_alt,
                      label: 'العملاء',
                      index: 8,
                      isSelected: _selectedIndex == 8,
                      canAccess: true,
                    ),
                  if (canAccessIndex(9))
                    _buildMobileNavItem(
                      icon: Icons.local_shipping,
                      label: 'الموردين',
                      index: 9,
                      isSelected: _selectedIndex == 9,
                      canAccess: true,
                    ),
                  if (canAccessIndex(10))
                    _buildMobileNavItem(
                      icon: Icons.receipt_long,
                      label: 'المصروفات',
                      index: 10,
                      isSelected: _selectedIndex == 10,
                      canAccess: true,
                    ),
                  if (canAccessIndex(11))
                    _buildMobileNavItem(
                      icon: Icons.assignment_return,
                      label: 'المرتجعات',
                      index: 11,
                      isSelected: _selectedIndex == 11,
                      canAccess: true,
                    ),
                  if (canAccessIndex(12))
                    _buildMobileNavItem(
                      icon: Icons.payments,
                      label: 'الديون',
                      index: 12,
                      isSelected: _selectedIndex == 12,
                      canAccess: true,
                    ),
                  if (canAccessIndex(13))
                    _buildMobileNavItem(
                      icon: Icons.assessment,
                      label: 'التقارير الموحدة',
                      index: 13,
                      isSelected: _selectedIndex == 13,
                      canAccess: true,
                    ),
                  if (canAccessIndex(14))
                    _buildMobileNavItem(
                      icon: Icons.analytics,
                      label: 'التحليلات',
                      index: 14,
                      isSelected: _selectedIndex == 14,
                      canAccess: true,
                    ),
                  if (canAccessIndex(15))
                    _buildMobileNavItem(
                      icon: Icons.history,
                      label: 'سجل الأحداث',
                      index: 15,
                      isSelected: _selectedIndex == 15,
                      canAccess: true,
                    ),
                  if (canAccessIndex(16))
                    _buildMobileNavItem(
                      icon: Icons.delete_outline,
                      label: 'سلة المحذوفات',
                      index: 16,
                      isSelected: _selectedIndex == 16,
                      canAccess: true,
                    ),
                  if (canAccessIndex(17))
                    _buildMobileNavItem(
                      icon: Icons.settings,
                      label: 'الإعدادات',
                      index: 17,
                      isSelected: _selectedIndex == 17,
                      canAccess: true,
                    ),
                  if (canAccessIndex(18))
                    _buildMobileNavItem(
                      icon: Icons.people,
                      label: 'إدارة المستخدمين',
                      index: 18,
                      isSelected: _selectedIndex == 18,
                      canAccess: true,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دالة لإرجاع اللون المناسب لكل صفحة
  Color _getPageColor(int index) {
    switch (index) {
      case 0: // Dashboard
        return const Color(0xFF2196F3); // أزرق
      case 1: // Sales
        return const Color(0xFF4CAF50); // أخضر
      case 2: // Sales History
        return const Color(0xFF03A9F4); // أزرق فاتح
      case 3: // Products
        return const Color(0xFFFF9800); // برتقالي
      case 4: // Categories
        return const Color(0xFF9C27B0); // بنفسجي
      case 5: // Inventory
        return const Color(0xFF1976D2); // أزرق داكن
      case 6: // Customers
        return const Color(0xFF00BCD4); // أزرق سماوي
      case 7: // Suppliers
        return const Color(0xFFFF5722); // برتقالي محمر
      case 8: // Expenses
        return const Color(0xFFF44336); // أحمر
      case 9: // Returns
        return const Color(0xFFFF6F00); // برتقالي داكن
      case 10: // Debts
        return const Color(0xFFE91E63); // وردي/أحمر
      case 11: // Unified Reports
        return const Color(0xFF3F51B5); // أزرق بنفسجي
      case 12: // Analytics
        return const Color(0xFF009688); // أخضر مزرق
      case 13: // Event Log
        return const Color(0xFF607D8B); // رمادي مزرق
      case 14: // Deleted Items
        return const Color(0xFFD32F2F); // أحمر داكن
      case 15: // Settings
        return const Color(0xFF757575); // رمادي
      case 16: // Users Management
        return const Color(0xFF7B1FA2); // بنفسجي داكن
      default:
        return const Color(0xFF2196F3); // أزرق افتراضي
    }
  }

  Widget _buildMobileNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
    required bool canAccess,
  }) {
    final pageColor = _getPageColor(index);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: canAccess
              ? () {
                  setState(() => _selectedIndex = index);
                  Navigator.pop(context);
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color:
                  isSelected ? pageColor.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: pageColor,
                      width: 2,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? pageColor.withOpacity(0.2)
                        : pageColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? pageColor : pageColor.withOpacity(0.8),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? pageColor : scheme.onSurface,
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: pageColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageColor = _getPageColor(index);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _selectedIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? pageColor.withOpacity(isDark ? 0.25 : 0.18)
                  : (isDark
                      ? Colors.transparent
                      : scheme.surfaceContainerHighest.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(
                      color: pageColor.withOpacity(isDark ? 0.5 : 0.6),
                      width: 1.5,
                    )
                  : (isDark
                      ? null
                      : Border.all(
                          color: scheme.outline.withOpacity(0.1),
                          width: 0.5,
                        )),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? pageColor.withOpacity(isDark ? 0.25 : 0.2)
                        : pageColor.withOpacity(isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? pageColor : pageColor.withOpacity(0.8),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? pageColor
                          : (isDark
                              ? scheme.onSurface.withOpacity(0.85)
                              : scheme.onSurface.withOpacity(0.9)),
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: pageColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget لزر تنبيهات المخزون
class _InventoryAlertsButton extends StatefulWidget {
  const _InventoryAlertsButton();

  @override
  State<_InventoryAlertsButton> createState() => _InventoryAlertsButtonState();
}

class _InventoryAlertsButtonState extends State<_InventoryAlertsButton> {
  int _alertsCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAlertsCount();
    });
  }

  Future<void> _loadAlertsCount() async {
    if (!mounted) return;
    final db = context.read<DatabaseService>();
    final count = await _getAlertsCount(db);
    if (mounted) {
      setState(() {
        _alertsCount = count;
      });
    }
  }

  Future<int> _getAlertsCount(DatabaseService db) async {
    try {
      final lowStock = await db.getLowStock();
      final outOfStock = await db.getOutOfStock();
      return lowStock.length + outOfStock.length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _showInventoryAlerts(
      BuildContext context, DatabaseService db) async {
    try {
      // عرض مؤشر التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // جلب البيانات
      final lowStock = await db.getLowStock();
      final outOfStock = await db.getOutOfStock();

      if (!context.mounted) return;

      // إغلاق مؤشر التحميل
      Navigator.of(context).pop();

      // عرض Dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.inventory_2,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('تنبيهات المخزون'),
            ],
          ),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // المنتجات النافدة
                  if (outOfStock.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.error,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'منتجات نافدة (${outOfStock.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...outOfStock.map((product) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cancel,
                                  color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['name']?.toString() ?? 'منتج',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'الكمية: ${product['quantity'] ?? 0}',
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],

                  // المنتجات منخفضة المخزون
                  if (lowStock.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.warning,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'منتجات منخفضة المخزون (${lowStock.length})',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...lowStock.map((product) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber,
                                  color: Colors.orange, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product['name']?.toString() ?? 'منتج',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'الكمية: ${product['quantity'] ?? 0} | الحد الأدنى: ${product['min_quantity'] ?? 0}',
                                      style: TextStyle(
                                        color: Colors.orange.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],

                  // لا توجد تنبيهات
                  if (outOfStock.isEmpty && lowStock.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد تنبيهات',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'جميع المنتجات في حالة جيدة',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في جلب التنبيهات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.notifications,
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.onSurface
                : Colors.black,
          ),
          if (_alertsCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  _alertsCount > 99 ? '99+' : '$_alertsCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      tooltip: 'تنبيهات المخزون',
      onPressed: () async {
        await _showInventoryAlerts(context, db);
        // تحديث عدد التنبيهات بعد إغلاق الحوار
        _loadAlertsCount();
      },
    );
  }
}
