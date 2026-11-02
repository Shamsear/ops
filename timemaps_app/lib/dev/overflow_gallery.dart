import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

/// Development & verification gallery for stress-testing components against text overflow
/// at 320px, 360px, 390px, and 430px widths at 1.0 and 1.3 text scales.
class OverflowGalleryScreen extends StatelessWidget {
  const OverflowGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(body: Center(child: Text('Debug Only')));
    }

    return AppScreenScaffold(
      title: 'UI Component Gallery',
      subtitle: '320px - 430px Responsive Overflow Tests',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1: Typography & Badges
          const SectionHeader(
            icon: Icons.text_fields_rounded,
            microLabel: 'Typography & Badges',
            title: 'Badge Variations & Ellipsis',
          ),
          AppCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                const StatusBadge(label: 'Active On Duty', variant: StatusVariant.success, showDot: true),
                const StatusBadge(label: 'Pending Security Clearance at Dubai Mall', variant: StatusVariant.warning, showDot: true, maxWidth: 180),
                const StatusBadge(label: 'Expired', variant: StatusVariant.danger, showDot: true),
                const StatusBadge(label: 'Shift Scheduled', variant: StatusVariant.info),
                const StatusBadge(label: 'Field Lead', variant: StatusVariant.purple),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),

          // Section 2: KPI Tiles in Responsive Grid
          const SectionHeader(
            icon: Icons.grid_view_rounded,
            microLabel: 'Metrics',
            title: 'Responsive KPI Tiles',
          ),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.itemGap,
            crossAxisSpacing: AppSpacing.itemGap,
            childAspectRatio: 1.35,
            children: const [
              KpiTile(
                label: 'Active Promoters',
                value: '42',
                icon: Icons.people_outline_rounded,
                iconColor: AppColors.accent,
                delta: '+12%',
                isPositive: true,
              ),
              KpiTile(
                label: 'Supermarket Stores Covered Across Emirates',
                value: '74',
                icon: Icons.storefront_rounded,
                iconColor: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionGap),

          // Section 3: Long String Cards
          const SectionHeader(
            icon: Icons.business_rounded,
            microLabel: 'Extreme Strings',
            title: '40+ Character Store Names',
          ),
          AppCard(
            child: Row(
              children: [
                const InitialsAvatar(name: 'MARKANDSAVE HYPERMARKET SPS LLC-BR3 AL TALAH', size: 40),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MARKANDSAVE HYPERMARKET SPS LLC-BR3 AL TALAH AJMAN INDUSTRIAL AREA',
                        style: AppText.bodyBold,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Retailer Chain: MarkAndSave • Emirate: Ajman • Zone: North Hub',
                        style: AppText.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const StatusBadge(label: 'Approved', variant: StatusVariant.success, showDot: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),

          // Section 4: Form System
          const SectionHeader(
            icon: Icons.edit_note_rounded,
            microLabel: 'Input Fields',
            title: 'Standard Form Inputs',
          ),
          AppCard(
            child: Column(
              children: [
                const AppTextField(
                  label: 'Store Location Name',
                  hint: 'e.g. Lulu Hypermarket Al Barsha',
                  prefixIcon: Icon(Icons.storefront_rounded, size: 18),
                ),
                const SizedBox(height: AppSpacing.md),
                AppDateField(
                  label: 'Scheduled Shift Date',
                  value: DateTime(2026, 10, 14),
                  onChanged: (_) {},
                ),
                const SizedBox(height: AppSpacing.md),
                SearchableSelectField<String>(
                  label: 'Promoter Staff',
                  value: 'Sony Mathew',
                  options: const [
                    SearchableOption(value: 'Sony Mathew', label: 'Sony Mathew', subtitle: '+971 50 111 2233 • Promoter'),
                    SearchableOption(value: 'Prachi Sharma', label: 'Prachi Sharma', subtitle: '+971 50 222 3344 • Promoter'),
                  ],
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),

          // Section 5: Buttons
          const SectionHeader(
            icon: Icons.touch_app_rounded,
            microLabel: 'Action Triggers',
            title: 'Buttons & Skeletons',
          ),
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  label: 'Cancel Action',
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppButton(
                  label: 'Save Changes to UAE Database',
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const AppSkeletonList(count: 2),
        ],
      ),
    );
  }
}
