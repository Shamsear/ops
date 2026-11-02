import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';

class AppDateField extends StatelessWidget {
  final String? label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String hint;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const AppDateField({
    super.key,
    this.label,
    required this.value,
    required this.onChanged,
    this.hint = 'Select date',
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    final display = value != null ? DateFormat('EEE, dd MMM yyyy').format(value!) : hint;
    final hasValue = value != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!.toUpperCase(),
            style: AppText.micro.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
        ],
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? now,
              firstDate: firstDate ?? now.subtract(const Duration(days: 365)),
              lastDate: lastDate ?? now.add(const Duration(days: 365 * 2)),
            );
            if (picked != null) {
              onChanged(picked);
            }
          },
          borderRadius: BorderRadius.circular(AppRadius.input),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.input),
              border: Border.all(color: AppColors.borderSubtle, width: 1.0),
            ),
            child: Row(
              children: [
                const IconBox(
                  icon: Icons.calendar_today_rounded,
                  color: AppColors.primary,
                  isCompact: true,
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                Expanded(
                  child: Text(
                    display,
                    style: AppText.body.copyWith(
                      color: hasValue ? AppColors.textPrimary : AppColors.textMuted,
                      fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.arrow_drop_down_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
