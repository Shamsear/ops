import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/liquid_glass.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import 'create_drop_page.dart';
import 'create_collection_page.dart';
import 'create_schedule_page.dart';
import 'create_badge_page.dart';
import 'create_project_page.dart';
import 'create_store_page.dart';
import 'create_promoter_page.dart';
import 'promoter_audit_page.dart';

class OperationsMenuPage extends StatelessWidget {
  const OperationsMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        titleSpacing: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.76),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.50),
                    width: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Operations Action Center',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMain,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Launch field logistics, scheduling & master data workflows',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section 1: Logistics & Field Dispatch
              _buildSectionHeader(
                icon: Icons.local_shipping_rounded,
                color: AppTheme.warning,
                title: 'FIELD LOGISTICS & DISPATCH',
                subtitle: 'Deliver stands and retrieve promotional materials',
              ),
              const SizedBox(height: 10),
              _buildActionCard(
                context: context,
                icon: Icons.local_shipping_outlined,
                iconBg: AppTheme.warningBg,
                iconColor: AppTheme.warning,
                title: 'Assign Morning Drop-off',
                subtitle: 'Schedule stand, rollup & stock delivery to store',
                tag: 'Logistics Drop',
                tagVariant: StatusVariant.warning,
                pageBuilder: () => const CreateDropPage(),
              ),
              const SizedBox(height: 10),
              _buildActionCard(
                context: context,
                icon: Icons.repeat_rounded,
                iconBg: AppTheme.successBg,
                iconColor: AppTheme.success,
                title: 'Assign Return Collection',
                subtitle: 'Retrieve promotional fixtures & excess stock after campaign',
                tag: 'Collection',
                tagVariant: StatusVariant.success,
                pageBuilder: () => const CreateCollectionPage(),
              ),
              const SizedBox(height: 20),

              // Section 2: Scheduling & Compliance
              _buildSectionHeader(
                icon: Icons.event_note_rounded,
                color: AppTheme.accent,
                title: 'SCHEDULING & STORE ACCESS',
                subtitle: 'Batch assign promoter shifts and manage gate passes',
              ),
              const SizedBox(height: 10),
              _buildActionCard(
                context: context,
                icon: Icons.calendar_month_rounded,
                iconBg: AppTheme.infoBg,
                iconColor: AppTheme.accent,
                title: 'Batch Shift Scheduler',
                subtitle: 'Generate multi-day shifts across UAE stores in 1 tap',
                tag: 'Staff Matrix',
                tagVariant: StatusVariant.info,
                pageBuilder: () => const CreateSchedulePage(),
              ),
              const SizedBox(height: 10),
              _buildActionCard(
                context: context,
                icon: Icons.badge_outlined,
                iconBg: const Color(0xFFF3E8FF),
                iconColor: AppTheme.purple,
                title: 'Security Badge & Gate Pass',
                subtitle: 'Apply for Hypermarket security entry permits',
                tag: 'Mall Pass',
                tagVariant: StatusVariant.neutral,
                pageBuilder: () => const CreateBadgePage(),
              ),
              const SizedBox(height: 10),
              _buildActionCard(
                context: context,
                icon: Icons.rate_review_outlined,
                iconBg: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFF59E0B),
                title: 'Promoter Audit Scorecard',
                subtitle: 'On-site supervisor evaluation for grooming, pitch & hygiene',
                tag: 'Field Audit',
                tagVariant: StatusVariant.warning,
                pageBuilder: () => const PromoterAuditPage(),
              ),
              const SizedBox(height: 20),

              // Section 3: Master Data Onboarding
              _buildSectionHeader(
                icon: Icons.hub_rounded,
                color: AppTheme.primary,
                title: 'MASTER DATA ONBOARDING',
                subtitle: 'Add new clients, brands, store branches and field staff',
              ),
              const SizedBox(height: 10),
              _buildActionCard(
                context: context,
                icon: Icons.campaign_outlined,
                iconBg: const Color(0xFFFFE4E6),
                iconColor: AppTheme.accentRose,
                title: 'New Campaign Project',
                subtitle: 'Onboard a brand roadshow (Sadia, L\'Oreal, Nestle, etc.)',
                tag: 'Roadshow',
                tagVariant: StatusVariant.neutral,
                pageBuilder: () => const CreateProjectPage(),
              ),
              const SizedBox(height: 10),
              _buildActionCard(
                context: context,
                icon: Icons.storefront_outlined,
                iconBg: const Color(0xFFCCFBF1),
                iconColor: AppTheme.accentTeal,
                title: 'New Store Location',
                subtitle: 'Onboard hypermarket branch with customer code & leads',
                tag: 'UAE Store',
                tagVariant: StatusVariant.neutral,
                pageBuilder: () => const CreateStorePage(),
              ),
              const SizedBox(height: 10),
              _buildActionCard(
                context: context,
                icon: Icons.person_add_alt_1_outlined,
                iconBg: const Color(0xFFFEF3C7),
                iconColor: AppTheme.accentAmber,
                title: 'Register Field Promoter',
                subtitle: 'Create promoter identity with phone and nationality',
                tag: 'Promoter',
                tagVariant: StatusVariant.neutral,
                pageBuilder: () => const CreatePromoterPage(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMuted,
                letterSpacing: 0.6,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String tag,
    required StatusVariant tagVariant,
    required Widget Function() pageBuilder,
  }) {
    return InkWell(
      onTap: () async {
        final res = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => pageBuilder()),
        );
        if (res == true && context.mounted) {
          Navigator.pop(context, true);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: LiquidGlassContainer(
        radius: 18.0,
        blur: 16.0,
        opacity: 0.82,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMain,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceSubtle,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.borderStrong,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
