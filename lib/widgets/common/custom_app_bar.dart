import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final VoidCallback? onLeadingPressed;
  final Widget? leading;
  final bool centerTitle;
  final double elevation;
  final Color? backgroundColor;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.onLeadingPressed,
    this.leading,
    this.centerTitle = true,
    this.elevation = AppTheme.mediumElevation,
    this.backgroundColor,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      elevation: elevation,
      centerTitle: centerTitle,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: SvgPicture.asset(
              'lib/assets/images/app_logo.svg',
              fit: BoxFit.contain,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
              placeholderBuilder: (BuildContext context) => Container(
                padding: const EdgeInsets.all(8.0),
                child: const CircularProgressIndicator(strokeWidth: 2.0),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.white,
              shadows: isDarkMode
                  ? [
                      Shadow(
                        color: AppTheme.secondaryColor.withOpacity(0.5),
                        offset: const Offset(0, 1),
                        blurRadius: 3,
                      )
                    ]
                  : [],
            ),
          ),
        ],
      ),
      actions: actions,
      leading: leading,
      bottom: bottom,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [
                    backgroundColor ?? const Color(0xFF1A2236),
                    backgroundColor ?? const Color(0xFF263450),
                  ]
                : [
                    backgroundColor ?? AppTheme.primaryColor,
                    backgroundColor != null
                        ? backgroundColor!.withOpacity(0.8)
                        : AppTheme.primaryColor.withOpacity(0.85),
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: isDarkMode
              ? [
                  BoxShadow(
                    color: AppTheme.secondaryColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}
