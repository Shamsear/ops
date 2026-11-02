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

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.width,
    this.height = 48.0,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.width,
    this.height = 48.0,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.width,
    this.height = 48.0,
  }) : variant = AppButtonVariant.destructive;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.width,
    this.height = 48.0,
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

    Widget content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              color: fg,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            label,
            style: AppText.bodyBold.copyWith(color: fg),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return SizedBox(
      width: width ?? (variant == AppButtonVariant.text ? null : double.infinity),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: content,
          ),
        ),
      ),
    );
  }
}
