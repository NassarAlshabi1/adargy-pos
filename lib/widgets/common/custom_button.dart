import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum ButtonType { primary, secondary, outline, text }

enum ButtonSize { small, medium, large }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonType type;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Define styles for different button types
    final buttonStyle = _getButtonStyle(context, type, isDark);

    // Build button content with optional icon and loading indicator
    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                    _getLoaderColor(type, isDark)),
              ),
            ),
          )
        else if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(icon, size: _getIconSize(size)),
          ),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: _getTextSize(size),
          ),
        ),
      ],
    );

    // Apply custom container for more styling control if needed
    final buttonWidget = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: buttonContent,
    );

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: buttonStyle,
      child: buttonWidget,
    );

    // Apply full width if requested
    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  EdgeInsetsGeometry _getButtonSize(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }

  ButtonStyle _getButtonStyle(
      BuildContext context, ButtonType type, bool isDark) {
    final radius = borderRadius != null
        ? BorderRadius.circular(borderRadius!)
        : AppTheme.mediumRadius;

    switch (type) {
      case ButtonType.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: _getButtonSize(size),
          shape: RoundedRectangleBorder(borderRadius: radius),
          elevation: 2,
        );

      case ButtonType.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppTheme.secondaryColor,
          foregroundColor: Colors.white,
          padding: _getButtonSize(size),
          shape: RoundedRectangleBorder(borderRadius: radius),
          elevation: 2,
        );

      case ButtonType.outline:
        return OutlinedButton.styleFrom(
          foregroundColor: AppTheme.primaryColor,
          side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
          padding: _getButtonSize(size),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.pressed)) {
                return AppTheme.primaryColor.withOpacity(0.1);
              }
              return Colors.transparent;
            },
          ),
        );

      case ButtonType.text:
        return TextButton.styleFrom(
          foregroundColor: AppTheme.primaryColor,
          padding: _getButtonSize(size),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.pressed)) {
                return AppTheme.primaryColor.withOpacity(0.1);
              }
              return Colors.transparent;
            },
          ),
        );
    }
  }

  double _getTextSize(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return 14;
      case ButtonSize.medium:
        return 16;
      case ButtonSize.large:
        return 18;
    }
  }

  double _getIconSize(ButtonSize size) {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  Color _getLoaderColor(ButtonType type, bool isDark) {
    switch (type) {
      case ButtonType.primary:
      case ButtonType.secondary:
        return Colors.white;
      case ButtonType.outline:
      case ButtonType.text:
        return AppTheme.primaryColor;
    }
  }
}
