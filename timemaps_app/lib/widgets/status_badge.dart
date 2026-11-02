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
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        return AppTheme.successBg;
      case StatusVariant.warning:
        return AppTheme.warningBg;
      case StatusVariant.danger:
        return AppTheme.dangerBg;
      case StatusVariant.info:
        return AppTheme.infoBg;
      case StatusVariant.purple:
        return AppTheme.purpleBg;
      case StatusVariant.neutral:
        return AppTheme.surfaceSubtle;
    }
  }

  Color get _border {
    switch (variant) {
      case StatusVariant.success:
        return AppTheme.successBorder;
      case StatusVariant.warning:
        return AppTheme.warningBorder;
      case StatusVariant.danger:
        return AppTheme.dangerBorder;
      case StatusVariant.info:
        return AppTheme.infoBorder;
      case StatusVariant.purple:
        return AppTheme.purpleBorder;
      case StatusVariant.neutral:
        return AppTheme.borderSubtle;
    }
  }

  Color get _text {
    switch (variant) {
      case StatusVariant.success:
        return AppTheme.successText;
      case StatusVariant.warning:
        return AppTheme.warningText;
      case StatusVariant.danger:
        return AppTheme.dangerText;
      case StatusVariant.info:
        return AppTheme.infoText;
      case StatusVariant.purple:
        return AppTheme.purpleText;
      case StatusVariant.neutral:
        return AppTheme.textSecondary;
    }
  }

  Color get _dotColor {
    switch (variant) {
      case StatusVariant.success:
        return AppTheme.success;
      case StatusVariant.warning:
        return AppTheme.warning;
      case StatusVariant.danger:
        return AppTheme.danger;
      case StatusVariant.info:
        return AppTheme.info;
      case StatusVariant.purple:
        return AppTheme.purple;
      case StatusVariant.neutral:
        return AppTheme.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget badge = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: _border.withOpacity(0.9), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: _dotColor.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: _dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _dotColor.withOpacity(0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
          ],
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: _text),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: _text,
                letterSpacing: -0.2,
                height: 1.2,
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
