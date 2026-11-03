import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'create_drop_page.dart';
import 'create_collection_page.dart';
import 'create_schedule_page.dart';
import 'create_badge_page.dart';
import 'create_project_page.dart';
import 'create_store_page.dart';
import 'create_promoter_page.dart';
import 'promoter_audit_page.dart';
import 'login_screen.dart';

class OperationsMenuPage extends StatelessWidget {
  const OperationsMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      bottomClearance: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: 'IML Operations Hub',
      subtitle: 'Warehouse dispatch, scheduling & master data',
      actions: const [
        OperatorHeaderButton(),
        SizedBox(width: AppSpacing.sm),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1: Field Logistics & Dispatch
          const SectionHeader(
            icon: Icons.local_shipping_rounded,
            iconColor: AppColors.warning,
            microLabel: 'FIELD LOGISTICS & DISPATCH',
            title: 'Equipment & Stock Transfers',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildActionItem(
            context: context,
            icon: Icons.local_shipping_outlined,
            iconColor: AppColors.warning,
            title: 'Assign Morning Drop-off',
            subtitle: 'Schedule stand, rollup & stock delivery to venue',
            tag: 'Drop',
            tagVariant: StatusVariant.warning,
            pageBuilder: () => const CreateDropPage(),
          ),
          const SizedBox(height: AppSpacing.itemGap),
          _buildActionItem(
            context: context,
            icon: Icons.repeat_rounded,
            iconColor: AppColors.accent,
            title: 'Assign Return Collection',
            subtitle: 'Retrieve promotional fixtures & excess stock post-campaign',
            tag: 'Collection',
            tagVariant: StatusVariant.info,
            pageBuilder: () => const CreateCollectionPage(),
          ),
          const SizedBox(height: AppSpacing.sectionGap),

          // Section 2: Scheduling & Compliance
          const SectionHeader(
            icon: Icons.event_note_rounded,
            iconColor: AppColors.accent,
            microLabel: 'SCHEDULING & STORE ACCESS',
            title: 'Roster & Gate Passes',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildActionItem(
            context: context,
            icon: Icons.calendar_month_rounded,
            iconColor: AppColors.accent,
            title: 'Batch Shift Scheduler',
            subtitle: 'Generate multi-day shifts across UAE stores in 1 tap',
            tag: 'Staff Matrix',
            tagVariant: StatusVariant.info,
            pageBuilder: () => const CreateSchedulePage(),
          ),
          const SizedBox(height: AppSpacing.itemGap),
          _buildActionItem(
            context: context,
            icon: Icons.badge_outlined,
            iconColor: AppColors.purple,
            title: 'Security Badge & Gate Pass',
            subtitle: 'Apply for Hypermarket security entry permits',
            tag: 'Permit',
            tagVariant: StatusVariant.neutral,
            pageBuilder: () => const CreateBadgePage(),
          ),
          const SizedBox(height: AppSpacing.itemGap),
          _buildActionItem(
            context: context,
            icon: Icons.rate_review_outlined,
            iconColor: AppColors.warning,
            title: 'Promoter Audit Scorecard',
            subtitle: 'On-site supervisor evaluation for grooming, pitch & hygiene',
            tag: 'Audit',
            tagVariant: StatusVariant.warning,
            pageBuilder: () => const PromoterAuditPage(),
          ),
          const SizedBox(height: AppSpacing.sectionGap),

          // Section 3: Master Data Onboarding
          const SectionHeader(
            icon: Icons.hub_rounded,
            iconColor: AppColors.primary,
            microLabel: 'MASTER DATA ONBOARDING',
            title: 'Campaigns, Stores & Staff',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildActionItem(
            context: context,
            icon: Icons.campaign_outlined,
            iconColor: AppColors.danger,
            title: 'New Campaign Project',
            subtitle: 'Onboard a brand roadshow (Sadia, L\'Oreal, Nestle, etc.)',
            tag: 'Roadshow',
            tagVariant: StatusVariant.neutral,
            pageBuilder: () => const CreateProjectPage(),
          ),
          const SizedBox(height: AppSpacing.itemGap),
          _buildActionItem(
            context: context,
            icon: Icons.storefront_outlined,
            iconColor: AppColors.success,
            title: 'New Store Location',
            subtitle: 'Onboard hypermarket branch with customer code & leads',
            tag: 'Store',
            tagVariant: StatusVariant.neutral,
            pageBuilder: () => const CreateStorePage(),
          ),
          const SizedBox(height: AppSpacing.itemGap),
          _buildActionItem(
            context: context,
            icon: Icons.person_add_alt_1_outlined,
            iconColor: AppColors.primary,
            title: 'Register Field Promoter',
            subtitle: 'Create promoter identity with phone and nationality',
            tag: 'Promoter',
            tagVariant: StatusVariant.neutral,
            pageBuilder: () => const CreatePromoterPage(),
          ),
          const SizedBox(height: AppSpacing.sectionGap),

          // Section 4: Operator Authentication & Session
          const SectionHeader(
            icon: Icons.account_circle_rounded,
            iconColor: AppColors.primary,
            microLabel: 'OPERATOR SESSION',
            title: 'Account & Authentication',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildActionItem(
            context: context,
            icon: Icons.switch_account_rounded,
            iconColor: AppColors.primary,
            title: 'Operator Login / Switch Role',
            subtitle: 'Log in as a different operator or switch active session',
            tag: 'Session',
            tagVariant: StatusVariant.info,
            pageBuilder: () => const LoginScreen(),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String tag,
    required StatusVariant tagVariant,
    required Widget Function() pageBuilder,
  }) {
    return AppCard(
      onTap: () async {
        final res = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => pageBuilder()),
        );
        if (res == true && context.mounted) {
          Navigator.pop(context, true);
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBox(icon: icon, color: iconColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusBadge(
                  label: tag,
                  variant: tagVariant,
                  showDot: false,
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  style: AppText.bodyBold,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Padding(
            padding: EdgeInsets.only(top: 6.0),
            child: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.borderStrong,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
