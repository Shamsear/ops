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

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = StatusVariant.neutral,
    this.icon,
    this.showDot = false,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
  });

  factory StatusBadge.fromStatus(String status) {
    final s = status.toLowerCase();
    if (s.contains('on duty') || s.contains('active') || s.contains('approved') || s.contains('delivered') || s.contains('collected')) {
      return StatusBadge(label: status, variant: StatusVariant.success, showDot: true);
    } else if (s.contains('pending') || s.contains('due') || s.contains('hr') || s.contains('security')) {
      return StatusBadge(label: status, variant: StatusVariant.warning, showDot: true);
    } else if (s.contains('rejected') || s.contains('alert') || s.contains('absent') || s.contains('off duty')) {
      return StatusBadge(label: status, variant: StatusVariant.danger, showDot: true);
    } else if (s.contains('ready') || s.contains('shift') || s.contains('scheduled')) {
      return StatusBadge(label: status, variant: StatusVariant.info);
    }
    return StatusBadge(label: status, variant: StatusVariant.neutral);
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
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _dotColor,
                shape: BoxShape.circle,
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
                letterSpacing: -0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
