import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// نظام التصميم الموحد للتطبيق
class AppDesignSystem {
  // منع إنشاء مثيل من الكلاس
  AppDesignSystem._();

  // المسافات الموحدة
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 12.0;
  static const double spacingLG = 16.0;
  static const double spacingXL = 20.0;
  static const double spacingXXL = 24.0;
  static const double spacingXXXL = 32.0;

  // الحدود الموحدة
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusRound = 50.0;

  // الارتفاعات الموحدة
  static const double elevationXS = 1.0;
  static const double elevationSM = 2.0;
  static const double elevationMD = 4.0;
  static const double elevationLG = 8.0;
  static const double elevationXL = 12.0;
  static const double elevationXXL = 16.0;

  // الأحجام الموحدة
  static const double sizeXS = 24.0;
  static const double sizeSM = 32.0;
  static const double sizeMD = 40.0;
  static const double sizeLG = 48.0;
  static const double sizeXL = 56.0;
  static const double sizeXXL = 64.0;

  // إنشاء BoxDecoration موحد
  static BoxDecoration createCardDecoration({
    Color? backgroundColor,
    Color? borderColor,
    double borderRadius = radiusMD,
    double elevation = elevationSM,
    Color? shadowColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(borderRadius),
      border: borderColor != null ? Border.all(color: borderColor) : null,
      boxShadow: elevation > 0
          ? [
              BoxShadow(
                color: shadowColor ?? AppColors.shadowLight,
                blurRadius: elevation,
                offset: Offset(0, elevation / 2),
              ),
            ]
          : null,
    );
  }

  // إنشاء InputDecoration موحد
  static InputDecoration createInputDecoration({
    String? hintText,
    String? labelText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    Color? borderColor,
    Color? focusColor,
    double borderRadius = radiusSM,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: borderColor ?? AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: borderColor ?? AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide:
            BorderSide(color: focusColor ?? AppColors.borderFocus, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: AppColors.errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: AppColors.errorRed, width: 2),
      ),
      contentPadding: contentPadding ??
          const EdgeInsets.symmetric(
              horizontal: spacingLG, vertical: spacingMD),
    );
  }

  // إنشاء ButtonStyle موحد
  static ButtonStyle createButtonStyle({
    Color? backgroundColor,
    Color? foregroundColor,
    double borderRadius = radiusSM,
    double elevation = elevationSM,
    EdgeInsetsGeometry? padding,
  }) {
    return ButtonStyle(
      backgroundColor:
          WidgetStateProperty.all(backgroundColor ?? AppColors.primaryBlue),
      foregroundColor:
          WidgetStateProperty.all(foregroundColor ?? AppColors.white),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      elevation: WidgetStateProperty.all(elevation),
      padding: WidgetStateProperty.all(padding ??
          const EdgeInsets.symmetric(
              horizontal: spacingLG, vertical: spacingMD)),
    );
  }

  // إنشاء Card موحد
  static Widget createCard({
    required Widget child,
    Color? backgroundColor,
    Color? borderColor,
    double borderRadius = radiusMD,
    double elevation = elevationSM,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.all(spacingSM),
      child: Card(
        color: backgroundColor ?? AppColors.surfaceLight,
        elevation: elevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: borderColor != null
              ? BorderSide(color: borderColor)
              : BorderSide.none,
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(spacingLG),
          child: child,
        ),
      ),
    );
  }

  // إنشاء ListTile موحد
  static Widget createListTile({
    required Widget title,
    Widget? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    Color? backgroundColor,
    double borderRadius = radiusSM,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: spacingSM, vertical: spacingXS),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ListTile(
        leading: leading,
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
        contentPadding: contentPadding ??
            const EdgeInsets.symmetric(
                horizontal: spacingLG, vertical: spacingSM),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  // إنشاء Chip موحد
  static Widget createChip({
    required String label,
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
    VoidCallback? onDeleted,
    double borderRadius = radiusRound,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
      ),
      child: Chip(
        label: Text(
          label,
          style: AppTextStyles.chip
              .copyWith(color: textColor ?? AppColors.primaryBlue),
        ),
        backgroundColor: Colors.transparent,
        deleteIcon: onDeleted != null
            ? Icon(Icons.close,
                size: 16, color: textColor ?? AppColors.primaryBlue)
            : null,
        onDeleted: onDeleted,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // إنشاء Badge موحد
  static Widget createBadge({
    required String text,
    Color? backgroundColor,
    Color? textColor,
    double borderRadius = radiusRound,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(
              horizontal: spacingSM, vertical: spacingXS),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.errorRed,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        text,
        style:
            AppTextStyles.badge.copyWith(color: textColor ?? AppColors.white),
      ),
    );
  }

  // إنشاء Divider موحد
  static Widget createDivider({
    Color? color,
    double thickness = 1.0,
    double height = 1.0,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: spacingMD),
      child: Divider(
        color: color ?? AppColors.borderLight,
        thickness: thickness,
        height: height,
      ),
    );
  }

  // إنشاء Spacer موحد
  static Widget createSpacer({double height = spacingLG}) {
    return SizedBox(height: height);
  }

  // إنشاء Horizontal Spacer موحد
  static Widget createHorizontalSpacer({double width = spacingLG}) {
    return SizedBox(width: width);
  }

  // إنشاء Container موحد
  static Widget createContainer({
    required Widget child,
    Color? backgroundColor,
    Color? borderColor,
    double borderRadius = radiusSM,
    double elevation = 0,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? width,
    double? height,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(spacingLG),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor != null ? Border.all(color: borderColor) : null,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: elevation,
                  offset: Offset(0, elevation / 2),
                ),
              ]
            : null,
      ),
      child: child,
    );
  }

  // إنشاء Row موحد
  static Widget createRow({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    double spacing = spacingSM,
  }) {
    if (spacing == 0) {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: children,
      );
    }

    final List<Widget> spacedChildren = [];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(SizedBox(width: spacing));
      }
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: spacedChildren,
    );
  }

  // إنشاء Column موحد
  static Widget createColumn({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    double spacing = spacingSM,
  }) {
    if (spacing == 0) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: children,
      );
    }

    final List<Widget> spacedChildren = [];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(SizedBox(height: spacing));
      }
    }

    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: spacedChildren,
    );
  }

  // إنشاء Grid موحد
  static Widget createGrid({
    required List<Widget> children,
    int crossAxisCount = 2,
    double childAspectRatio = 1.0,
    double spacing = spacingSM,
    double runSpacing = spacingSM,
  }) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: spacing,
      mainAxisSpacing: runSpacing,
      children: children,
    );
  }

  // إنشاء Wrap موحد
  static Widget createWrap({
    required List<Widget> children,
    double spacing = spacingSM,
    double runSpacing = spacingSM,
    WrapAlignment alignment = WrapAlignment.start,
    WrapCrossAlignment crossAxisAlignment = WrapCrossAlignment.start,
  }) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    );
  }

  // إنشاء Stack موحد
  static Widget createStack({
    required List<Widget> children,
    AlignmentGeometry alignment = AlignmentDirectional.topStart,
    StackFit fit = StackFit.loose,
    Clip clipBehavior = Clip.hardEdge,
  }) {
    return Stack(
      alignment: alignment,
      fit: fit,
      clipBehavior: clipBehavior,
      children: children,
    );
  }

  // إنشاء Positioned موحد
  static Widget createPositioned({
    required Widget child,
    double? top,
    double? bottom,
    double? left,
    double? right,
    double? width,
    double? height,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      width: width,
      height: height,
      child: child,
    );
  }

  // إنشاء Flexible موحد
  static Widget createFlexible({
    required Widget child,
    int flex = 1,
    FlexFit fit = FlexFit.loose,
  }) {
    return Flexible(
      flex: flex,
      fit: fit,
      child: child,
    );
  }

  // إنشاء Expanded موحد
  static Widget createExpanded({
    required Widget child,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: child,
    );
  }

  // إنشاء SizedBox موحد
  static Widget createSizedBox({
    double? width,
    double? height,
  }) {
    return SizedBox(
      width: width,
      height: height,
    );
  }

  // إنشاء Container موحد للخلفية
  static Widget createBackgroundContainer({
    required Widget child,
    Color? backgroundColor,
    String? backgroundImage,
    BoxFit fit = BoxFit.cover,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        image: backgroundImage != null
            ? DecorationImage(
                image: AssetImage(backgroundImage),
                fit: fit,
              )
            : null,
      ),
      child: child,
    );
  }

  // إنشاء Container موحد للحدود
  static Widget createBorderedContainer({
    required Widget child,
    Color? borderColor,
    double borderWidth = 1.0,
    double borderRadius = radiusSM,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor ?? AppColors.borderLight,
          width: borderWidth,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: child,
    );
  }

  // إنشاء Container موحد للظلال
  static Widget createShadowedContainer({
    required Widget child,
    Color? shadowColor,
    double elevation = elevationSM,
    double borderRadius = radiusSM,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: shadowColor ?? AppColors.shadowLight,
            blurRadius: elevation,
            offset: Offset(0, elevation / 2),
          ),
        ],
      ),
      child: child,
    );
  }
}
