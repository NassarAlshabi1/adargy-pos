import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final Color? textColor;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool showArrow;
  final Widget? trailing;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.textColor,
    this.iconColor,
    this.onTap,
    this.showArrow = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = color ?? (isDark ? AppTheme.darkCardColor : Colors.white);
    final valueTextColor = textColor ?? AppTheme.primaryColor;
    final valueIconColor = iconColor ?? AppTheme.secondaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.mediumRadius,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.mediumPadding),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: AppTheme.mediumRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: valueIconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: valueIconColor,
                      size: 24,
                    ),
                  ),
                  if (showArrow)
                    Icon(
                      Icons.arrow_forward_ios,
                      color: isDark
                          ? AppTheme.darkSecondaryTextColor
                          : AppTheme.lightSecondaryTextColor,
                      size: 16,
                    )
                  else if (trailing != null)
                    trailing!,
                ],
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: valueTextColor,
                  fontFamily: 'Arial',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppTheme.darkSecondaryTextColor
                      : AppTheme.lightSecondaryTextColor,
                  fontFamily: 'Arial',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
