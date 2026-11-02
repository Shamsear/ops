import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, destructive, text }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final double? width;
  final double height;
  final bool autoWidth;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.width,
    this.height = 48.0,
    this.autoWidth = false,
    this.padding,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.width,
    this.height = 48.0,
    this.autoWidth = false,
    this.padding,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.width,
    this.height = 48.0,
    this.autoWidth = false,
    this.padding,
  }) : variant = AppButtonVariant.destructive;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.width,
    this.height = 48.0,
    this.autoWidth = false,
    this.padding,
  }) : variant = AppButtonVariant.text;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = AppColors.primary;
        fg = Colors.white;
        break;
      case AppButtonVariant.secondary:
        bg = AppColors.surface;
        fg = AppColors.textPrimary;
        border = const BorderSide(color: AppColors.borderSubtle, width: 1.0);
        break;
      case AppButtonVariant.destructive:
        bg = AppColors.dangerSoft;
        fg = AppColors.danger;
        border = BorderSide(color: AppColors.statusBorder(AppColors.danger), width: 1.0);
        break;
      case AppButtonVariant.text:
        bg = Colors.transparent;
        fg = AppColors.accent;
        break;
    }

    if (onPressed == null) {
      bg = AppColors.surfaceMuted;
      fg = AppColors.textMuted;
      border = BorderSide.none;
    }

    final isCompact = height <= 36.0;
    final effectivePadding = padding ??
        (isCompact
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 0)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 0));
    final iconSize = isCompact ? 15.0 : 18.0;
    final iconGap = isCompact ? 5.0 : AppSpacing.sm;
    final textStyle = (isCompact
            ? AppText.bodySmall.copyWith(fontWeight: FontWeight.w600, fontSize: 12.0)
            : AppText.bodyBold)
        .copyWith(color: fg);

    Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading) ...[
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              color: fg,
            ),
          ),
          SizedBox(width: iconGap),
        ] else if (icon != null) ...[
          Icon(icon, size: iconSize, color: fg),
          SizedBox(width: iconGap),
        ],
        if (autoWidth)
          Text(
            label,
            style: textStyle,
            maxLines: 1,
          )
        else
          Flexible(
            child: Text(
              label,
              style: textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );

    final effectiveWidth = autoWidth
        ? null
        : (width ?? (variant == AppButtonVariant.text ? null : double.infinity));

    return SizedBox(
      width: effectiveWidth,
      height: height,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.input),
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppRadius.input),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.input),
              border: border != BorderSide.none ? Border.fromBorderSide(border) : null,
            ),
            padding: effectivePadding,
            alignment: Alignment.center,
            child: content,
          ),
        ),
      ),
    );
  }
}
