import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primaryColor = Color.fromRGBO(21, 101, 192, 1);
  static const Color secondaryColor = Color(0xFFFFA000);
  static const Color accentColor = Color(0xFF00BCD4);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color dangerColor = Color(0xFFE53935);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color infoColor = Color(0xFF2196F3);

  // Light theme colors
  static const Color lightScaffoldColor = Color(0xFFF5F5F5);
  static const Color lightCardColor = Colors.white;
  static const Color lightDividerColor = Color(0xFFE0E0E0);
  static const Color lightTextColor = Color(0xFF212121);
  static const Color lightSecondaryTextColor = Color(0xFF757575);

  // Dark theme colors
  static const Color darkScaffoldColor = Color(0xFF121212);
  static const Color darkCardColor = Color(0xFF1E1E1E);
  static const Color darkDividerColor = Color(0xFF323232);
  static const Color darkTextColor = Color(0xFFEEEEEE);
  static const Color darkSecondaryTextColor = Color(0xFFAAAAAA);

  // Padding and spacing
  static const double smallPadding = 8.0;
  static const double mediumPadding = 16.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;

  // Border radius
  static final BorderRadius smallRadius = BorderRadius.circular(4.0);
  static final BorderRadius mediumRadius = BorderRadius.circular(8.0);
  static final BorderRadius largeRadius = BorderRadius.circular(12.0);
  static final BorderRadius extraLargeRadius = BorderRadius.circular(24.0);

  // Elevation values
  static const double noElevation = 0.0;
  static const double smallElevation = 2.0;
  static const double mediumElevation = 4.0;
  static const double largeElevation = 8.0;

  // Animation durations
  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration longDuration = Duration(milliseconds: 500);

  // Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: lightScaffoldColor,
    cardColor: lightCardColor,
    dividerColor: lightDividerColor,
    fontFamily: 'Arial',
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: lightCardColor,
      error: dangerColor,
    ),
    appBarTheme: AppBarTheme(
      elevation: mediumElevation,
      centerTitle: true,
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      titleTextStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontFamily: 'Arial',
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: smallElevation,
        padding: const EdgeInsets.symmetric(
            horizontal: mediumPadding, vertical: smallPadding),
        shape: RoundedRectangleBorder(borderRadius: mediumRadius),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Arial',
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(
            horizontal: mediumPadding, vertical: smallPadding),
        shape: RoundedRectangleBorder(borderRadius: mediumRadius),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Arial',
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(
            horizontal: mediumPadding, vertical: smallPadding),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Arial',
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: mediumElevation,
    ),
    cardTheme: CardThemeData(
      color: lightCardColor,
      elevation: smallElevation,
      shape: RoundedRectangleBorder(borderRadius: mediumRadius),
      margin: const EdgeInsets.all(smallPadding),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(mediumPadding),
      border: OutlineInputBorder(
        borderRadius: mediumRadius,
        borderSide: const BorderSide(color: primaryColor, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: mediumRadius,
        borderSide:
            BorderSide(color: primaryColor.withOpacity(0.5), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: mediumRadius,
        borderSide: const BorderSide(color: primaryColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: mediumRadius,
        borderSide: const BorderSide(color: dangerColor, width: 1.0),
      ),
      labelStyle: const TextStyle(color: lightSecondaryTextColor),
      hintStyle: TextStyle(color: lightSecondaryTextColor.withOpacity(0.7)),
    ),
    textTheme: TextTheme(
      displayLarge: const TextStyle(
        color: lightTextColor,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        fontFamily: 'Arial',
      ),
      displayMedium: const TextStyle(
        color: lightTextColor,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        fontFamily: 'Arial',
      ),
      displaySmall: const TextStyle(
        color: lightTextColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        fontFamily: 'Arial',
      ),
      headlineMedium: const TextStyle(
        color: lightTextColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Arial',
      ),
      titleLarge: const TextStyle(
        color: lightTextColor,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Arial',
      ),
      bodyLarge: const TextStyle(
        color: lightTextColor,
        fontSize: 16,
        fontFamily: 'Arial',
      ),
      bodyMedium: const TextStyle(
        color: lightTextColor,
        fontSize: 14,
        fontFamily: 'Arial',
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryColor,
      unselectedItemColor: lightSecondaryTextColor,
      type: BottomNavigationBarType.fixed,
      elevation: largeElevation,
      selectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        fontFamily: 'Arial',
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontFamily: 'Arial',
      ),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: primaryColor,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontFamily: 'Arial',
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: mediumRadius),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: lightCardColor,
      elevation: largeElevation,
      shape: RoundedRectangleBorder(borderRadius: mediumRadius),
      titleTextStyle: const TextStyle(
        color: lightTextColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Arial',
      ),
      contentTextStyle: const TextStyle(
        color: lightTextColor,
        fontSize: 16,
        fontFamily: 'Arial',
      ),
    ),
    platform: TargetPlatform.android,
  );

  // Dark theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: darkScaffoldColor,
    cardColor: darkCardColor,
    dividerColor: darkDividerColor,
    fontFamily: 'Arial',
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: darkCardColor,
      error: dangerColor,
      onSurface: darkTextColor,
    ),
    appBarTheme: AppBarTheme(
      elevation: mediumElevation,
      centerTitle: true,
      backgroundColor: darkCardColor,
      foregroundColor: darkTextColor,
      titleTextStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: darkTextColor,
        fontFamily: 'Arial',
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: smallElevation,
        padding: const EdgeInsets.symmetric(
            horizontal: mediumPadding, vertical: smallPadding),
        shape: RoundedRectangleBorder(borderRadius: mediumRadius),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Arial',
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor, width: 1.5),
        padding: const EdgeInsets.symmetric(
            horizontal: mediumPadding, vertical: smallPadding),
        shape: RoundedRectangleBorder(borderRadius: mediumRadius),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Arial',
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(
            horizontal: mediumPadding, vertical: smallPadding),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Arial',
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: mediumElevation,
    ),
    cardTheme: CardThemeData(
      color: darkCardColor,
      elevation: smallElevation,
      shape: RoundedRectangleBorder(borderRadius: mediumRadius),
      margin: const EdgeInsets.all(smallPadding),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCardColor,
      contentPadding: const EdgeInsets.all(mediumPadding),
      border: OutlineInputBorder(
        borderRadius: mediumRadius,
        borderSide: const BorderSide(color: primaryColor, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: mediumRadius,
        borderSide:
            BorderSide(color: primaryColor.withOpacity(0.5), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: mediumRadius,
        borderSide: const BorderSide(color: primaryColor, width: 2.0),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: mediumRadius,
        borderSide: const BorderSide(color: dangerColor, width: 1.0),
      ),
      labelStyle: const TextStyle(color: darkSecondaryTextColor),
      hintStyle: TextStyle(color: darkSecondaryTextColor.withOpacity(0.7)),
    ),
    textTheme: TextTheme(
      displayLarge: const TextStyle(
        color: darkTextColor,
        fontSize: 32,
        fontWeight: FontWeight.bold,
        fontFamily: 'Arial',
      ),
      displayMedium: const TextStyle(
        color: darkTextColor,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        fontFamily: 'Arial',
      ),
      displaySmall: const TextStyle(
        color: darkTextColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        fontFamily: 'Arial',
      ),
      headlineMedium: const TextStyle(
        color: darkTextColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Arial',
      ),
      titleLarge: const TextStyle(
        color: darkTextColor,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Arial',
      ),
      bodyLarge: const TextStyle(
        color: darkTextColor,
        fontSize: 16,
        fontFamily: 'Arial',
      ),
      bodyMedium: const TextStyle(
        color: darkTextColor,
        fontSize: 14,
        fontFamily: 'Arial',
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: darkCardColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: darkSecondaryTextColor,
      type: BottomNavigationBarType.fixed,
      elevation: largeElevation,
      selectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
      ),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkCardColor,
      contentTextStyle: const TextStyle(
        color: darkTextColor,
        fontSize: 14,
        fontFamily: 'Arial',
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: mediumRadius),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: darkCardColor,
      elevation: largeElevation,
      shape: RoundedRectangleBorder(borderRadius: mediumRadius),
      titleTextStyle: const TextStyle(
        color: darkTextColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'Arial',
      ),
      contentTextStyle: const TextStyle(
        color: darkTextColor,
        fontSize: 16,
        fontFamily: 'Arial',
      ),
    ),
    platform: TargetPlatform.android,
  );
}
