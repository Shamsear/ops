import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? count;

  const FilterPill({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderSubtle,
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppText.micro.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                letterSpacing: 0.2,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.25) : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$count',
                  style: AppText.micro.copyWith(
                    fontSize: 9.5,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
