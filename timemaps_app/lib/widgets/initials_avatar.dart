import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? foregroundColor;
  final Color? backgroundColor;

  const InitialsAvatar({
    super.key,
    required this.name,
    this.size = 36.0,
    this.foregroundColor,
    this.backgroundColor,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'IML';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final (retailerBg, retailerFg) = AppColors.retailerColors(name);
    final bg = backgroundColor ?? retailerBg;
    final fg = foregroundColor ?? retailerFg;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.iconBox),
        border: Border.all(color: fg.withOpacity(0.15), width: 1.0),
      ),
      child: Center(
        child: Text(
          _initials,
          style: AppText.bodyBold.copyWith(
            fontSize: size * 0.38,
            color: fg,
          ),
        ),
      ),
    );
  }
}
