import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

class SectionHeader extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String? microLabel;
  final String title;
  final Widget? trailing;
  final double bottomGap;

  const SectionHeader({
    super.key,
    this.icon,
    this.iconColor,
    this.microLabel,
    required this.title,
    this.trailing,
    this.bottomGap = AppSpacing.md,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              IconBox(
                icon: icon!,
                color: iconColor ?? AppColors.primary,
                isCompact: true,
              ),
              const SizedBox(width: AppSpacing.sm + 2),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (microLabel != null) ...[
                    Text(
                      microLabel!.toUpperCase(),
                      style: AppText.micro.copyWith(color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    title,
                    style: AppText.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
        if (bottomGap > 0) SizedBox(height: bottomGap),
      ],
    );
  }
}
