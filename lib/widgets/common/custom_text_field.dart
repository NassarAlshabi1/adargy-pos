import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final Widget? prefix;
  final Widget? suffix;
  final String? prefixText;
  final String? suffixText;
  final String? errorText;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool enableSuggestions;
  final bool autocorrect;
  final String? initialValue;
  final EdgeInsetsGeometry? contentPadding;
  final BorderRadius? borderRadius;
  final Color? fillColor;
  final TextDirection? textDirection;

  const CustomTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.prefix,
    this.suffix,
    this.prefixText,
    this.suffixText,
    this.errorText,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onTap,
    this.onEditingComplete,
    this.onSubmitted,
    this.autofocus = false,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.initialValue,
    this.contentPadding,
    this.borderRadius,
    this.fillColor,
    this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? AppTheme.mediumRadius;
    final padding = contentPadding ??
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16);

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      readOnly: readOnly,
      enabled: enabled,
      maxLines: maxLines,
      minLines: minLines,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      onTap: onTap,
      onEditingComplete: onEditingComplete,
      onFieldSubmitted: onSubmitted,
      autofocus: autofocus,
      enableSuggestions: enableSuggestions,
      autocorrect: autocorrect,
      initialValue: initialValue,
      textDirection: textDirection ?? TextDirection.rtl,
      textAlign: TextAlign.right,
      style: const TextStyle(
        color: isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor:
            fillColor ?? (isDark ? AppTheme.darkCardColor : Colors.white),
        contentPadding: padding,
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: isDark
                ? AppTheme.primaryColor.withOpacity(0.5)
                : AppTheme.primaryColor.withOpacity(0.5),
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: isDark
                ? AppTheme.primaryColor.withOpacity(0.3)
                : AppTheme.primaryColor.withOpacity(0.3),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(
            color: AppTheme.dangerColor,
            width: 1.0,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(
            color: AppTheme.dangerColor,
            width: 2.0,
          ),
        ),
        prefixIcon: prefix,
        suffixIcon: suffix,
        prefixText: prefixText,
        suffixText: suffixText,
        errorText: errorText,
        labelStyle: const TextStyle(
          color: isDark
              ? AppTheme.darkSecondaryTextColor
              : AppTheme.lightSecondaryTextColor,
          fontSize: 16,
        ),
        hintStyle: const TextStyle(
          color: isDark
              ? AppTheme.darkSecondaryTextColor.withOpacity(0.7)
              : AppTheme.lightSecondaryTextColor.withOpacity(0.7),
          fontSize: 14,
        ),
        errorStyle: const TextStyle(
          color: AppTheme.dangerColor,
          fontSize: 12,
        ),
        alignLabelWithHint: true,
      ),
    );
  }
}
