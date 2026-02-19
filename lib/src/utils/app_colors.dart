import 'package:flutter/material.dart';

/// نظام الألوان الموحد للتطبيق
class AppColors {
  // منع إنشاء مثيل من الكلاس
  AppColors._();

  // الألوان الأساسية
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color secondaryGreen = Color(0xFF10B981);
  static const Color accentPurple = Color(0xFF7C3AED);

  // ألوان الحالة
  static const Color successGreen = Color(0xFF059669);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFDC2626);
  static const Color infoBlue = Color(0xFF3B82F6);

  // الألوان المحايدة
  static const Color neutralGray = Color(0xFF64748B);
  static const Color lightGray = Color(0xFF94A3B8);
  static const Color darkGray = Color(0xFF374151);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // ألوان الخلفية
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E293B);

  // ألوان النصوص
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textInverse = Color(0xFFFFFFFF);

  // ألوان الحدود
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);
  static const Color borderFocus = Color(0xFF1976D2);

  // ألوان الظلال
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowDark = Color(0x4D000000);
  static const Color shadowMedium = Color(0x33000000);
}
