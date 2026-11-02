import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum StatusVariant {
  success,
  warning,
  danger,
  info,
  purple,
  neutral,
}

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusVariant variant;
  final IconData? icon;
  final bool showDot;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final double? maxWidth;

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = StatusVariant.neutral,
    this.icon,
    this.showDot = false,
    this.fontSize = 10.5,
    this.padding = const EdgeInsets.symmetric(horizontal: 9.0, vertical: 0.0),
    this.maxWidth,
  });

  static String formatStatusLabel(String raw) {
    final s = raw.trim();
    final lower = s.toLowerCase();
    if (lower.contains('ready for collection') || lower == 'documents ready for collection') {
      return 'Docs Ready';
    }
    if (lower.contains('with security') || lower == 'pending with security') {
      return 'Security Check';
    }
    if (lower.contains('with hr') || lower == 'pending with hr') {
      return 'HR Review';
    }
    if (lower.contains('drop-off') || lower.contains('scheduled for')) {
      return 'Scheduled';
    }
    if (lower.contains('delivered') || lower.contains('confirmed')) {
      return 'Delivered';
    }
    if (lower.contains('collected')) {
      return 'Collected';
    }
    if (lower.contains('under review') || lower.contains('in review')) {
      return 'In Review';
    }
    if (lower.contains('on duty') || lower == 'active') {
      return 'Active';
    }
    if (lower.contains('off duty') || lower == 'absent') {
      return 'Off Duty';
    }
    if (lower.contains('missing doc') || lower.contains('docs missing')) {
      return 'Missing Docs';
    }
    return s;
  }

  factory StatusBadge.fromStatus(String status, {double? maxWidth}) {
    final conciseLabel = formatStatusLabel(status);
    final s = status.toLowerCase();
    if (s.contains('on duty') || s.contains('active') || s.contains('approved') || s.contains('delivered') || s.contains('collected') || s.contains('verified')) {
      return StatusBadge(label: conciseLabel, variant: StatusVariant.success, showDot: true, maxWidth: maxWidth);
    } else if (s.contains('pending') || s.contains('due') || s.contains('hr') || s.contains('security')) {
      return StatusBadge(label: conciseLabel, variant: StatusVariant.warning, showDot: true, maxWidth: maxWidth);
    } else if (s.contains('rejected') || s.contains('alert') || s.contains('absent') || s.contains('off duty')) {
      return StatusBadge(label: conciseLabel, variant: StatusVariant.danger, showDot: true, maxWidth: maxWidth);
    } else if (s.contains('ready') || s.contains('shift') || s.contains('scheduled')) {
      return StatusBadge(label: conciseLabel, variant: StatusVariant.info, maxWidth: maxWidth);
    } else if (s.contains('supervisor') || s.contains('campaign')) {
      return StatusBadge(label: conciseLabel, variant: StatusVariant.purple, maxWidth: maxWidth);
    }
    return StatusBadge(label: conciseLabel, variant: StatusVariant.neutral, maxWidth: maxWidth);
  }

  Color get _bg {
    switch (variant) {
      case StatusVariant.success:
        return AppColors.successSoft;
      case StatusVariant.warning:
        return AppColors.warningSoft;
      case StatusVariant.danger:
        return AppColors.dangerSoft;
      case StatusVariant.info:
        return AppColors.accentSoft;
      case StatusVariant.purple:
        return AppColors.purpleSoft;
      case StatusVariant.neutral:
        return AppColors.surfaceMuted;
    }
  }

  Color get _text {
    switch (variant) {
      case StatusVariant.success:
        return AppColors.success;
      case StatusVariant.warning:
        return AppColors.warning;
      case StatusVariant.danger:
        return AppColors.danger;
      case StatusVariant.info:
        return AppColors.accent;
      case StatusVariant.purple:
        return AppColors.purple;
      case StatusVariant.neutral:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget badge = Container(
      height: 24,
      padding: padding,
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.statusBorder(_text), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showDot) ...[
            Container(
              width: 6.0,
              height: 6.0,
              decoration: BoxDecoration(
                color: _text,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _text.withOpacity(0.45),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: _text),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label.toUpperCase(),
              style: AppText.micro.copyWith(
                fontSize: fontSize,
                color: _text,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (maxWidth != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: badge,
      );
    }
    return badge;
  }
}
