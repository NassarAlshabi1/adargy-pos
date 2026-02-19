import 'package:flutter/material.dart';

class DarkModeUtils {
  // Get appropriate background color based on theme
  static Color getBackgroundColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return scheme.surface;
  }

  // Get appropriate surface color based on theme
  static Color getSurfaceColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return scheme.surface;
  }

  // Get appropriate card color based on theme
  static Color getCardColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return scheme.surface;
  }

  // Get appropriate border color based on theme
  static Color getBorderColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey.shade700 : Colors.grey.shade300;
  }

  // Get appropriate divider color based on theme
  static Color getDividerColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey.shade700 : Colors.grey.shade200;
  }

  // Get appropriate shadow color based on theme
  static Color getShadowColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Colors.black.withOpacity(isDark ? 0.5 : 0.1);
  }

  // Get primary color from theme
  static Color getPrimaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  // Get secondary color from theme
  static Color getSecondaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.secondary;
  }

  // Get appropriate text color based on theme
  static Color getTextColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return scheme.onSurface;
  }

  // Get appropriate secondary text color based on theme
  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
  }

  // Get appropriate icon color based on theme
  static Color getIconColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  // Get appropriate gradient colors based on theme
  static List<Color> getGradientColors(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness == Brightness.dark) {
      return [
        const Color(0xFF2D2D2D),
        const Color(0xFF1A1A1A),
        const Color(0xFF0F0F0F),
      ];
    } else {
      return [
        const Color(0xFFF8FAFC),
        const Color(0xFFF1F3F4),
        const Color(0xFFE8EAED),
      ];
    }
  }

  // Get appropriate primary gradient colors based on theme
  static List<Color> getPrimaryGradientColors(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return [
      scheme.primary.withOpacity(0.7),
      scheme.primary,
      scheme.primaryContainer,
    ];
  }

  // Get appropriate backdrop filter color based on theme
  static Color getBackdropColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return (isDark ? Colors.black : Colors.white)
        .withOpacity(isDark ? 0.3 : 0.25);
  }

  // Get appropriate backdrop border color based on theme
  static Color getBackdropBorderColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Colors.white.withOpacity(isDark ? 0.2 : 0.35);
  }

  // Create a dark mode compatible container decoration
  static BoxDecoration createContainerDecoration(BuildContext context) {
    return BoxDecoration(
      color: getCardColor(context),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: getBorderColor(context),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: getShadowColor(context),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Create a dark mode compatible card decoration
  static BoxDecoration createCardDecoration(BuildContext context) {
    return BoxDecoration(
      color: getSurfaceColor(context),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: getBorderColor(context),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: getShadowColor(context),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Create a dark mode compatible input decoration
  static InputDecoration createInputDecoration(
    BuildContext context, {
    String? hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool filled = true,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      suffixIcon: suffixIcon,
      filled: filled,
      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: getBorderColor(context)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: getBorderColor(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  // Create a dark mode compatible pill input decoration
  static InputDecoration createPillInputDecoration(
    BuildContext context, {
    String? hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: getBorderColor(context)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    );
  }

  // Get appropriate status colors based on theme
  static Color getSuccessColor(BuildContext context) {
    // Prefer semantic colors if available; fallback to green shades
    return Theme.of(context).colorScheme.tertiary;
  }

  static Color getWarningColor(BuildContext context) {
    return Colors.orange;
  }

  static Color getErrorColor(BuildContext context) {
    return Theme.of(context).colorScheme.error;
  }

  static Color getInfoColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  // Create a dark mode compatible list tile
  static Widget createListTile({
    required BuildContext context,
    required Widget leading,
    required Widget title,
    Widget? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: getBorderColor(context)),
      ),
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
        contentPadding: contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Create a dark mode compatible chip
  static Widget createChip({
    required BuildContext context,
    required String label,
    Color? backgroundColor,
    Color? textColor,
    VoidCallback? onDeleted,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            color: textColor ?? theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.transparent,
        deleteIcon: onDeleted != null
            ? Icon(Icons.close,
                size: 16, color: textColor ?? theme.colorScheme.primary)
            : null,
        onDeleted: onDeleted,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
