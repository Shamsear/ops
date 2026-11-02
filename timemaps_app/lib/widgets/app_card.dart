import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 36x36 (or 28x28 compact) tinted container for icons
class IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final bool isCompact;
  final double? size;
  final double? iconSize;

  const IconBox({
    super.key,
    required this.icon,
    required this.color,
    this.backgroundColor,
    this.isCompact = false,
    this.size,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final boxSize = size ?? (isCompact ? 28.0 : 36.0);
    final iSize = iconSize ?? (isCompact ? 15.0 : 18.0);
    final radius = isCompact ? 8.0 : AppRadius.iconBox;
    final bg = backgroundColor ?? color.withOpacity(0.12);

    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: Icon(icon, size: iSize, color: color),
      ),
    );
  }
}

/// MyWisdom elevated white card with subtle border and dual ambient shadow
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool isFlat;
  final Color? color;
  final BorderSide? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPad),
    this.onTap,
    this.isFlat = false,
    this.color,
    this.border,
  });

  const AppCard.compact({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadCompact),
    this.onTap,
    this.isFlat = false,
    this.color,
    this.border,
  });

  const AppCard.flat({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadCompact),
    this.onTap,
    this.color,
    this.border,
  }) : isFlat = true;

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? (isFlat ? AppColors.surfaceMuted : AppColors.surface);
    final borderRadius = BorderRadius.circular(isFlat ? AppRadius.inner : AppRadius.card);
    final cardBorder = border ?? (isFlat ? BorderSide.none : const BorderSide(color: AppColors.borderSubtle, width: 1.0));
    final shadows = isFlat ? const <BoxShadow>[] : AppShadows.card;

    Widget current = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: borderRadius,
        border: cardBorder != BorderSide.none ? Border.fromBorderSide(cardBorder) : null,
        boxShadow: shadows,
      ),
      child: child,
    );

    if (onTap != null) {
      current = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: current,
        ),
      );
    }

    return current;
  }
}
