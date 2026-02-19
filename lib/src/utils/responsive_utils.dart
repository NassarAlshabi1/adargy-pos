import 'package:flutter/material.dart';

/// Utility class for responsive design
class ResponsiveUtils {
  /// Get screen size category
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 768) {
      return ScreenSize.small;
    } else if (width < 1024) {
      return ScreenSize.medium;
    } else if (width < 1440) {
      return ScreenSize.large;
    } else {
      return ScreenSize.extraLarge;
    }
  }

  /// Check if screen is small (mobile-like)
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 1024;
  }

  /// Check if screen is very small (mobile phones)
  static bool isVerySmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Check if screen is medium
  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 1024 && width < 1440;
  }

  /// Check if screen is large
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1440;
  }

  /// Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.small:
        return const EdgeInsets.all(8);
      case ScreenSize.medium:
        return const EdgeInsets.all(12);
      case ScreenSize.large:
        return const EdgeInsets.all(16);
      case ScreenSize.extraLarge:
        return const EdgeInsets.all(20);
    }
  }

  /// Get responsive margin
  static EdgeInsets getResponsiveMargin(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.small:
        return const EdgeInsets.all(8);
      case ScreenSize.medium:
        return const EdgeInsets.all(16);
      case ScreenSize.large:
        return const EdgeInsets.all(24);
      case ScreenSize.extraLarge:
        return const EdgeInsets.all(32);
    }
  }

  /// Get responsive font size
  static double getResponsiveFontSize(
      BuildContext context, double baseFontSize) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.small:
        return baseFontSize * 0.9;
      case ScreenSize.medium:
        return baseFontSize;
      case ScreenSize.large:
        return baseFontSize * 1.1;
      case ScreenSize.extraLarge:
        return baseFontSize * 1.2;
    }
  }

  /// Get responsive column count for grid
  static int getResponsiveColumnCount(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.small:
        return 1;
      case ScreenSize.medium:
        return 2;
      case ScreenSize.large:
        return 3;
      case ScreenSize.extraLarge:
        return 4;
    }
  }

  /// Get responsive sidebar width
  static double getResponsiveSidebarWidth(BuildContext context) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.small:
        return 170;
      case ScreenSize.medium:
        return 180;
      case ScreenSize.large:
        return 190;
      case ScreenSize.extraLarge:
        return 200;
    }
  }

  /// Get responsive table column widths
  static Map<int, TableColumnWidth> getResponsiveTableColumnWidths(
      BuildContext context) {
    final screenSize = getScreenSize(context);
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate minimum widths for better readability
    const double minIdWidth = 100; // عمود التسلسل
    const double minNameWidth = 180; // عمود المنتجات (الاسم)
    const double minBarcodeWidth = 120;
    const double minQuantityWidth = 100;
    const double minCostWidth = 110;
    const double minPriceWidth = 110;
    const double minActionsWidth = 160;

    switch (screenSize) {
      case ScreenSize.small:
        // For small screens, use minimum widths to ensure all columns are visible
        return {
          0: FixedColumnWidth(minIdWidth), // المعرف
          1: FixedColumnWidth(minNameWidth), // الاسم
          2: FixedColumnWidth(minBarcodeWidth), // الباركود
          3: FixedColumnWidth(minQuantityWidth), // الكمية
          4: FixedColumnWidth(minCostWidth), // التكلفة
          5: FixedColumnWidth(minPriceWidth), // السعر
          6: FixedColumnWidth(minActionsWidth), // الإجراءات
        };
      case ScreenSize.medium:
        // For medium screens, balance between minimum and proportional widths
        final double availableWidth = screenWidth - 200; // Account for padding
        final double nameWidth =
            (availableWidth * 0.28).clamp(minNameWidth, 240.0);
        final double barcodeWidth =
            (availableWidth * 0.20).clamp(minBarcodeWidth, 170.0);
        final double costPriceWidth =
            (availableWidth * 0.15).clamp(minCostWidth, 130.0);
        final double actionsWidth =
            (availableWidth * 0.20).clamp(minActionsWidth, 180.0);

        return {
          0: FixedColumnWidth(minIdWidth), // المعرف
          1: FixedColumnWidth(nameWidth), // الاسم
          2: FixedColumnWidth(barcodeWidth), // الباركود
          3: FixedColumnWidth(minQuantityWidth), // الكمية
          4: FixedColumnWidth(costPriceWidth), // التكلفة
          5: FixedColumnWidth(costPriceWidth), // السعر
          6: FixedColumnWidth(actionsWidth), // الإجراءات
        };
      case ScreenSize.large:
        // For large screens, use proportional widths with better distribution
        final double availableWidth = screenWidth - 300; // Account for padding
        final double nameWidth =
            (availableWidth * 0.25).clamp(minNameWidth, 260.0);
        final double barcodeWidth =
            (availableWidth * 0.18).clamp(minBarcodeWidth, 200.0);
        final double costPriceWidth =
            (availableWidth * 0.16).clamp(minCostWidth, 150.0);
        final double actionsWidth =
            (availableWidth * 0.16).clamp(minActionsWidth, 200.0);

        return {
          0: FixedColumnWidth(minIdWidth), // المعرف
          1: FixedColumnWidth(nameWidth), // الاسم
          2: FixedColumnWidth(barcodeWidth), // الباركود
          3: FixedColumnWidth(minQuantityWidth), // الكمية
          4: FixedColumnWidth(costPriceWidth), // التكلفة
          5: FixedColumnWidth(costPriceWidth), // السعر
          6: FixedColumnWidth(actionsWidth), // الإجراءات
        };
      case ScreenSize.extraLarge:
        // For extra large screens, use optimal proportional widths
        final double availableWidth = screenWidth - 400; // Account for padding
        final double nameWidth =
            (availableWidth * 0.22).clamp(minNameWidth, 320.0);
        final double barcodeWidth =
            (availableWidth * 0.18).clamp(minBarcodeWidth, 220.0);
        final double costPriceWidth =
            (availableWidth * 0.14).clamp(minCostWidth, 170.0);
        final double actionsWidth =
            (availableWidth * 0.16).clamp(minActionsWidth, 220.0);

        return {
          0: FixedColumnWidth(minIdWidth), // المعرف
          1: FixedColumnWidth(nameWidth), // الاسم
          2: FixedColumnWidth(barcodeWidth), // الباركود
          3: FixedColumnWidth(minQuantityWidth), // الكمية
          4: FixedColumnWidth(costPriceWidth), // التكلفة
          5: FixedColumnWidth(costPriceWidth), // السعر
          6: FixedColumnWidth(actionsWidth), // الإجراءات
        };
    }
  }
}

/// Screen size categories
enum ScreenSize {
  small, // < 768px (mobile)
  medium, // 768px - 1024px (tablet)
  large, // 1024px - 1440px (desktop)
  extraLarge, // > 1440px (large desktop)
}
