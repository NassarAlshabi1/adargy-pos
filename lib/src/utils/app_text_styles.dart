import 'package:flutter/material.dart';

/// نظام موحد للخطوط في التطبيق
class AppTextStyles {
  // منع إنشاء مثيل من الكلاس
  AppTextStyles._();

  // الخطوط الأساسية
  static const String _fontFamily = 'NotoSansArabic';

  // أحجام الخطوط الموحدة
  static const double _fontSizeH1 = 32.0;
  static const double _fontSizeH2 = 24.0;
  static const double _fontSizeH3 = 20.0;
  static const double _fontSizeH4 = 18.0;
  static const double _fontSizeH5 = 16.0;
  static const double _fontSizeH6 = 14.0;
  static const double _fontSizeBody1 = 16.0;
  static const double _fontSizeBody2 = 14.0;
  static const double _fontSizeCaption = 12.0;
  static const double _fontSizeSmall = 10.0;

  // أوزان الخطوط
  static const FontWeight _weightRegular = FontWeight.w400;
  static const FontWeight _weightMedium = FontWeight.w500;
  static const FontWeight _weightSemiBold = FontWeight.w600;
  static const FontWeight _weightBold = FontWeight.w700;
  static const FontWeight _weightExtraBold = FontWeight.w800;

  // العناوين الرئيسية
  static const TextStyle heading1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeH1,
    fontWeight: _weightBold,
    height: 1.2,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeH2,
    fontWeight: _weightBold,
    height: 1.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeH3,
    fontWeight: _weightSemiBold,
    height: 1.3,
  );

  static const TextStyle heading4 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeH4,
    fontWeight: _weightSemiBold,
    height: 1.4,
  );

  static const TextStyle heading5 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeH5,
    fontWeight: _weightMedium,
    height: 1.4,
  );

  static const TextStyle heading6 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeH6,
    fontWeight: _weightMedium,
    height: 1.4,
  );

  // النصوص الأساسية
  static const TextStyle body1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody1,
    fontWeight: _weightRegular,
    height: 1.5,
  );

  static const TextStyle body2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody2,
    fontWeight: _weightRegular,
    height: 1.5,
  );

  // النصوص الثانوية
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeCaption,
    fontWeight: _weightRegular,
    height: 1.4,
  );

  static const TextStyle small = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeSmall,
    fontWeight: _weightRegular,
    height: 1.3,
  );

  // النصوص الخاصة
  static const TextStyle button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody2,
    fontWeight: _weightMedium,
    height: 1.2,
  );

  static const TextStyle label = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeCaption,
    fontWeight: _weightMedium,
    height: 1.3,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeSmall,
    fontWeight: _weightMedium,
    height: 1.2,
    letterSpacing: 0.5,
  );

  // النصوص المخصصة للواجهة
  static const TextStyle appBarTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeH5,
    fontWeight: _weightSemiBold,
    height: 1.2,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeH6,
    fontWeight: _weightMedium,
    height: 1.3,
  );

  static const TextStyle listTileTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody2,
    fontWeight: _weightMedium,
    height: 1.3,
  );

  static const TextStyle listTileSubtitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeCaption,
    fontWeight: _weightRegular,
    height: 1.4,
  );

  // النصوص الخاصة بالحالة
  static const TextStyle success = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody2,
    fontWeight: _weightMedium,
    height: 1.3,
  );

  static const TextStyle error = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody2,
    fontWeight: _weightMedium,
    height: 1.3,
  );

  static const TextStyle warning = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody2,
    fontWeight: _weightMedium,
    height: 1.3,
  );

  static const TextStyle info = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody2,
    fontWeight: _weightMedium,
    height: 1.3,
  );

  // النصوص الخاصة بالأرقام
  static const TextStyle number = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody1,
    fontWeight: _weightMedium,
    height: 1.2,
  );

  static const TextStyle currency = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody1,
    fontWeight: _weightSemiBold,
    height: 1.2,
  );

  // النصوص الخاصة بالباركود
  static const TextStyle barcode = TextStyle(
    fontFamily: 'monospace',
    fontSize: _fontSizeCaption,
    fontWeight: _weightMedium,
    height: 1.0,
    letterSpacing: 1.0,
  );

  // النصوص الخاصة بالتاريخ والوقت
  static const TextStyle dateTime = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeCaption,
    fontWeight: _weightRegular,
    height: 1.3,
  );

  // النصوص الخاصة بالعناصر التفاعلية
  static const TextStyle link = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody2,
    fontWeight: _weightMedium,
    height: 1.3,
    decoration: TextDecoration.underline,
  );

  static const TextStyle chip = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeSmall,
    fontWeight: _weightMedium,
    height: 1.2,
  );

  // النصوص الخاصة بالتبويبات
  static const TextStyle tab = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeCaption,
    fontWeight: _weightMedium,
    height: 1.2,
  );

  // النصوص الخاصة بالحوارات
  static const TextStyle dialogTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeH5,
    fontWeight: _weightSemiBold,
    height: 1.3,
  );

  static const TextStyle dialogContent = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody2,
    fontWeight: _weightRegular,
    height: 1.4,
  );

  // النصوص الخاصة بالتنبيهات
  static const TextStyle snackBar = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody2,
    fontWeight: _weightMedium,
    height: 1.3,
  );

  // النصوص الخاصة بالحقول
  static const TextStyle fieldLabel = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeCaption,
    fontWeight: _weightMedium,
    height: 1.3,
  );

  static const TextStyle fieldHint = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody2,
    fontWeight: _weightRegular,
    height: 1.4,
  );

  static const TextStyle fieldError = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeSmall,
    fontWeight: _weightRegular,
    height: 1.3,
  );

  // النصوص الخاصة بالتقارير
  static const TextStyle reportTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeH4,
    fontWeight: _weightBold,
    height: 1.2,
  );

  static const TextStyle reportSubtitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeH6,
    fontWeight: _weightMedium,
    height: 1.3,
  );

  static const TextStyle reportData = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody2,
    fontWeight: _weightRegular,
    height: 1.4,
  );

  // النصوص الخاصة بالجداول
  static const TextStyle tableHeader = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeCaption,
    fontWeight: _weightSemiBold,
    height: 1.3,
  );

  static const TextStyle tableCell = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeCaption,
    fontWeight: _weightRegular,
    height: 1.3,
  );

  // النصوص الخاصة بالبطاقات
  static const TextStyle cardHeader = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeH6,
    fontWeight: _weightSemiBold,
    height: 1.3,
  );

  static const TextStyle cardContent = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody2,
    fontWeight: _weightRegular,
    height: 1.4,
  );

  // النصوص الخاصة بالقوائم
  static const TextStyle menuTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody1,
    fontWeight: _weightMedium,
    height: 1.3,
  );

  static const TextStyle menuSubtitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeCaption,
    fontWeight: _weightRegular,
    height: 1.4,
  );

  // النصوص الخاصة بالشريط الجانبي
  static const TextStyle sidebarTitle = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeH5,
    fontWeight: _weightBold,
    height: 1.2,
  );

  static const TextStyle sidebarItem = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody1,
    fontWeight: _weightMedium,
    height: 1.3,
  );

  // النصوص الخاصة بالحالة
  static const TextStyle statusActive = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeCaption,
    fontWeight: _weightMedium,
    height: 1.3,
  );

  static const TextStyle statusInactive = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeCaption,
    fontWeight: _weightRegular,
    height: 1.3,
  );

  // النصوص الخاصة بالأزرار
  static const TextStyle buttonPrimary = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody2,
    fontWeight: _weightSemiBold,
    height: 1.2,
  );

  static const TextStyle buttonSecondary = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody2,
    fontWeight: _weightMedium,
    height: 1.2,
  );

  // النصوص الخاصة بالعناصر الصغيرة
  static const TextStyle badge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeSmall,
    fontWeight: _weightSemiBold,
    height: 1.0,
  );

  static const TextStyle tooltip = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeSmall,
    fontWeight: _weightRegular,
    height: 1.3,
  );

  // النصوص الخاصة بالعناصر التفاعلية
  static const TextStyle clickable = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody2,
    fontWeight: _weightMedium,
    height: 1.3,
    decoration: TextDecoration.none,
  );

  static const TextStyle disabled = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody2,
    fontWeight: _weightRegular,
    height: 1.3,
  );

  // النصوص الخاصة بالعناصر المميزة
  static const TextStyle highlight = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody1,
    fontWeight: _weightSemiBold,
    height: 1.3,
  );

  static const TextStyle emphasis = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody2,
    fontWeight: _weightMedium,
    height: 1.3,
  );

  // النصوص الخاصة بالعناصر المهمة
  static const TextStyle important = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody1,
    fontWeight: _weightBold,
    height: 1.3,
  );

  static const TextStyle critical = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody2,
    fontWeight: _weightBold,
    height: 1.3,
  );

  // النصوص الخاصة بالعناصر الثانوية
  static const TextStyle secondary = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeCaption,
    fontWeight: _weightRegular,
    height: 1.4,
  );

  static const TextStyle muted = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeSmall,
    fontWeight: _weightRegular,
    height: 1.3,
  );

  // النصوص الخاصة بالعناصر المخصصة
  static const TextStyle custom = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody2,
    fontWeight: _weightRegular,
    height: 1.4,
  );

  // النصوص الخاصة بالعناصر المخصصة المهمة
  static const TextStyle customImportant = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody1,
    fontWeight: _weightSemiBold,
    height: 1.3,
  );

  // النصوص الخاصة بالعناصر المخصصة الثانوية
  static const TextStyle customSecondary = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeCaption,
    fontWeight: _weightMedium,
    height: 1.3,
  );

  // النصوص الخاصة بالعناصر المخصصة الصغيرة
  static const TextStyle customSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeSmall,
    fontWeight: _weightRegular,
    height: 1.3,
  );

  // النصوص الخاصة بالعناصر المخصصة الكبيرة
  static const TextStyle customLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeH5,
    fontWeight: _weightMedium,
    height: 1.3,
  );

  // النصوص الخاصة بالعناصر المخصصة الكبيرة المهمة
  static const TextStyle customLargeImportant = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeH4,
    fontWeight: _weightBold,
    height: 1.2,
  );

  // النصوص الخاصة بالعناصر المخصصة الكبيرة الثانوية
  static const TextStyle customLargeSecondary = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeH6,
    fontWeight: _weightMedium,
    height: 1.3,
  );

  // النصوص الخاصة بالعناصر المخصصة الكبيرة الصغيرة
  static const TextStyle customLargeSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeCaption,
    fontWeight: _weightRegular,
    height: 1.4,
  );

  // النصوص الخاصة بالعناصر المخصصة الكبيرة المهمة
  static const TextStyle customLargeImportantBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeH3,
    fontWeight: _weightExtraBold,
    height: 1.1,
  );

  // النصوص الخاصة بالعناصر المخصصة الكبيرة الثانوية
  static const TextStyle customLargeSecondaryBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeH5,
    fontWeight: _weightBold,
    height: 1.2,
  );

  // النصوص الخاصة بالعناصر المخصصة الكبيرة الصغيرة
  static const TextStyle customLargeSmallBold = TextStyle(
    fontFamily: _fontFamily,
    fontSize: _fontSizeBody2,
    fontWeight: _weightSemiBold,
    height: 1.3,
  );
}
