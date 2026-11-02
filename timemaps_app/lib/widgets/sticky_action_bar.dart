import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

class StickyActionBar extends StatelessWidget {
  final String? summaryText;
  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;
  final bool primaryLoading;
  final IconData? primaryIcon;

  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;
  final IconData? secondaryIcon;

  const StickyActionBar({
    super.key,
    this.summaryText,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.primaryLoading = false,
    this.primaryIcon,
    this.secondaryLabel,
    this.onSecondaryPressed,
    this.secondaryIcon,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 1.0)),
        boxShadow: AppShadows.raised,
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.md,
        AppSpacing.screenH,
        AppSpacing.md + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (summaryText != null) ...[
            Text(
              summaryText!,
              style: AppText.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (secondaryLabel != null)
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: AppButton.secondary(
                    label: secondaryLabel!,
                    onPressed: onSecondaryPressed,
                    icon: secondaryIcon,
                  ),
                ),
                const SizedBox(width: AppSpacing.itemGap),
                Expanded(
                  flex: 3,
                  child: AppButton(
                    label: primaryLabel,
                    onPressed: onPrimaryPressed,
                    loading: primaryLoading,
                    icon: primaryIcon,
                  ),
                ),
              ],
            )
          else
            AppButton(
              label: primaryLabel,
              onPressed: onPrimaryPressed,
              loading: primaryLoading,
              icon: primaryIcon,
            ),
        ],
      ),
    );
  }
}
