import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

class KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String? delta;
  final bool? isPositive;
  final VoidCallback? onTap;
  final bool isSelected;

  const KpiTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor = AppColors.primary,
    this.delta,
    this.isPositive,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      border: isSelected
          ? const BorderSide(color: AppColors.primary, width: 1.5)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconBox(
                icon: icon,
                color: iconColor,
                isCompact: true,
                size: 24,
                iconSize: 13,
              ),
              if (delta != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: (isPositive ?? true) ? AppColors.successSoft : AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    delta!,
                    style: AppText.micro.copyWith(
                      fontSize: 9.5,
                      color: (isPositive ?? true) ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppText.display,
            ),
          ),
          const SizedBox(height: 1),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label.toUpperCase(),
              style: AppText.micro.copyWith(color: AppColors.textMuted, letterSpacing: 0.2),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
