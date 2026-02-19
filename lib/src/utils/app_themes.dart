import 'package:flutter/material.dart';

class AppThemes {
  // Light Theme Colors - Professional Sales System Colors
  static const Color _lightPrimaryColor =
      Color(0xFF1976D2); // Professional Blue
  static const Color _lightBackgroundColor =
      Color(0xFFF8FAFC); // Light Gray Background
  static const Color _lightSurfaceColor =
      Color(0xFFFFFFFF); // Pure White Surface
  static const Color _lightOnPrimaryColor = Color(0xFFFFFFFF);
  static const Color _lightOnBackgroundColor =
      Color(0xFF1E293B); // Dark Gray Text
  static const Color _lightOnSurfaceColor = Color(0xFF1E293B); // Dark Gray Text
  static const Color _lightErrorColor = Color(0xFFDC2626); // Professional Red
  static const Color _lightOnErrorColor = Color(0xFFFFFFFF);

  // Dark Theme Colors - Professional Sales System Colors
  static const Color _darkPrimaryColor = Color(0xFF3B82F6); // Bright Blue
  static const Color _darkBackgroundColor = Color(0xFF0F172A); // Dark Navy
  static const Color _darkSurfaceColor = Color(0xFF1E293B); // Dark Gray Surface
  static const Color _darkOnPrimaryColor =
      Color(0xFF0F172A); // Dark Text on Primary
  static const Color _darkOnBackgroundColor =
      Color(0xFFF1F5F9); // Light Gray Text
  static const Color _darkOnSurfaceColor = Color(0xFFF1F5F9); // Light Gray Text
  static const Color _darkErrorColor = Color(0xFFEF4444); // Bright Red
  static const Color _darkOnErrorColor = Color(0xFF0F172A);

  // Light Theme
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _lightPrimaryColor,
      brightness: Brightness.light,
      primary: _lightPrimaryColor,
      onPrimary: _lightOnPrimaryColor,
      secondary: const Color(0xFF059669), // Professional Green
      onSecondary: const Color(0xFFFFFFFF),
      error: _lightErrorColor,
      onError: _lightOnErrorColor,
      background: _lightBackgroundColor,
      onBackground: _lightOnBackgroundColor,
      surface: _lightSurfaceColor,
      onSurface: _lightOnSurfaceColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBackgroundColor,
      extensions: const <ThemeExtension<dynamic>>[
        AppGradients.light(),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: _lightSurfaceColor,
        foregroundColor: _lightOnSurfaceColor,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        titleTextStyle: const TextStyle(
          color: _lightOnSurfaceColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        iconTheme: const IconThemeData(
          color: _lightOnSurfaceColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _lightPrimaryColor,
          foregroundColor: _lightOnPrimaryColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _lightPrimaryColor,
          foregroundColor: _lightOnPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _lightPrimaryColor,
          side: BorderSide(color: _lightPrimaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _lightPrimaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _lightErrorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _lightErrorColor, width: 2),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade300,
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _darkPrimaryColor,
      brightness: Brightness.dark,
      primary: _darkPrimaryColor,
      onPrimary: _darkOnPrimaryColor,
      secondary: const Color(0xFF10B981), // Bright Green
      onSecondary: const Color(0xFF0F172A),
      error: _darkErrorColor,
      onError: _darkOnErrorColor,
      background: _darkBackgroundColor,
      onBackground: _darkOnBackgroundColor,
      surface: _darkSurfaceColor,
      onSurface: _darkOnSurfaceColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBackgroundColor,
      extensions: const <ThemeExtension<dynamic>>[
        AppGradients.dark(),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: _darkSurfaceColor,
        foregroundColor: _darkOnSurfaceColor,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        titleTextStyle: const TextStyle(
          color: _darkOnSurfaceColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        iconTheme: const IconThemeData(
          color: _darkOnSurfaceColor,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkPrimaryColor,
          foregroundColor: _darkOnPrimaryColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _darkPrimaryColor,
          foregroundColor: _darkOnPrimaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _darkPrimaryColor,
          side: BorderSide(color: _darkPrimaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _darkPrimaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _darkErrorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _darkErrorColor, width: 2),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade700,
        thickness: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Get theme based on brightness
  static ThemeData getThemeData(Brightness brightness) {
    return brightness == Brightness.dark ? darkTheme : lightTheme;
  }

  // Custom colors for specific UI elements - Professional Sales System
  static const Color lightSidebarGradientStart =
      Color(0xFF1976D2); // Professional Blue
  static const Color lightSidebarGradientMiddle =
      Color(0xFF1565C0); // Darker Blue
  static const Color lightSidebarGradientEnd = Color(0xFF0D47A1); // Dark Blue

  static const Color darkSidebarGradientStart = Color(0xFF1E293B); // Dark Gray
  static const Color darkSidebarGradientMiddle =
      Color(0xFF334155); // Medium Gray
  static const Color darkSidebarGradientEnd = Color(0xFF475569); // Light Gray

  // Professional Sales System Colors
  static const Color successGreen = Color(0xFF059669); // Professional Green
  static const Color warningOrange = Color(0xFFF59E0B); // Professional Orange
  static const Color errorRed = Color(0xFFDC2626); // Professional Red
  static const Color infoBlue = Color(0xFF3B82F6); // Professional Blue

  // Additional Professional Colors
  static const Color primaryBlue = Color(0xFF1976D2); // Primary Blue
  static const Color secondaryGreen = Color(0xFF10B981); // Secondary Green
  static const Color accentPurple = Color(0xFF7C3AED); // Accent Purple
  static const Color neutralGray = Color(0xFF64748B); // Neutral Gray
  static const Color lightGray = Color(0xFF94A3B8); // Light Gray
  static const Color darkGray = Color(0xFF374151); // Dark Gray
  static const Color white = Color(0xFFFFFFFF); // Pure White
  static const Color black = Color(0xFF000000); // Pure Black
}

// Custom colors for specific UI elements
class AppColors {
  // Professional Sales System Colors (kept for compatibility; prefer ColorScheme)
  static const Color successGreen = Color(0xFF059669); // Professional Green
  static const Color warningOrange = Color(0xFFF59E0B); // Professional Orange
  static const Color errorRed = Color(0xFFDC2626); // Professional Red
  static const Color infoBlue = Color(0xFF3B82F6); // Professional Blue

  // Additional Professional Colors
  static const Color primaryBlue = Color(0xFF1976D2); // Primary Blue
  static const Color secondaryGreen = Color(0xFF10B981); // Secondary Green
  static const Color accentPurple = Color(0xFF7C3AED); // Accent Purple
  static const Color neutralGray = Color(0xFF64748B); // Neutral Gray
  static const Color lightGray = Color(0xFF94A3B8); // Light Gray
  static const Color darkGray = Color(0xFF374151); // Dark Gray
  static const Color white = Color(0xFFFFFFFF); // Pure White
  static const Color black = Color(0xFF000000); // Pure Black

  // Status Colors
  static const Color statusSuccess = Color(0xFF059669); // Success Green
  static const Color statusWarning = Color(0xFFF59E0B); // Warning Orange
  static const Color statusError = Color(0xFFDC2626); // Error Red
  static const Color statusInfo = Color(0xFF3B82F6); // Info Blue

  // Background Colors
  static const Color backgroundLight = Color(0xFFF8FAFC); // Light Background
  static const Color backgroundDark = Color(0xFF0F172A); // Dark Background
  static const Color surfaceLight = Color(0xFFFFFFFF); // Light Surface
  static const Color surfaceDark = Color(0xFF1E293B); // Dark Surface

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B); // Primary Text
  static const Color textSecondary = Color(0xFF64748B); // Secondary Text
  static const Color textTertiary = Color(0xFF94A3B8); // Tertiary Text
  static const Color textInverse = Color(0xFFFFFFFF); // Inverse Text

  // Border Colors
  static const Color borderLight = Color(0xFFE2E8F0); // Light Border
  static const Color borderDark = Color(0xFF334155); // Dark Border
  static const Color borderFocus = Color(0xFF1976D2); // Focus Border

  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000); // Light Shadow
  static const Color shadowDark = Color(0x4D000000); // Dark Shadow
  static const Color shadowMedium = Color(0x33000000); // Medium Shadow
}

class AppGradients extends ThemeExtension<AppGradients> {
  final Color sidebarStart;
  final Color sidebarMiddle;
  final Color sidebarEnd;

  const AppGradients({
    required this.sidebarStart,
    required this.sidebarMiddle,
    required this.sidebarEnd,
  });

  const AppGradients.light()
      : sidebarStart = const Color(0xFF1976D2), // Professional Blue
        sidebarMiddle = const Color(0xFF1565C0), // Darker Blue
        sidebarEnd = const Color(0xFF0D47A1); // Dark Blue

  const AppGradients.dark()
      : sidebarStart = const Color(0xFF1E293B), // Dark Gray
        sidebarMiddle = const Color(0xFF334155), // Medium Gray
        sidebarEnd = const Color(0xFF475569); // Light Gray

  @override
  AppGradients copyWith({
    Color? sidebarStart,
    Color? sidebarMiddle,
    Color? sidebarEnd,
  }) {
    return AppGradients(
      sidebarStart: sidebarStart ?? this.sidebarStart,
      sidebarMiddle: sidebarMiddle ?? this.sidebarMiddle,
      sidebarEnd: sidebarEnd ?? this.sidebarEnd,
    );
  }

  @override
  AppGradients lerp(ThemeExtension<AppGradients>? other, double t) {
    if (other is! AppGradients) return this;
    return AppGradients(
      sidebarStart: Color.lerp(sidebarStart, other.sidebarStart, t)!,
      sidebarMiddle: Color.lerp(sidebarMiddle, other.sidebarMiddle, t)!,
      sidebarEnd: Color.lerp(sidebarEnd, other.sidebarEnd, t)!,
    );
  }
}
