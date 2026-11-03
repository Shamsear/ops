import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../screens/login_screen.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'initials_avatar.dart';
import 'status_badge.dart';

void showOperatorProfileSheet(BuildContext context) {
  final user = ApiService.currentUser;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screenH, 12, AppSpacing.screenH, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.borderStrong,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              Row(
                children: [
                  InitialsAvatar(
                    name: user?.name ?? 'Operations Director',
                    size: 48,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Operations Director',
                          style: AppText.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'ops@imlme.com',
                          style: AppText.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        StatusBadge(
                          label: user?.role ?? 'OPS_ADMIN',
                          variant: StatusVariant.info,
                          showDot: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(color: AppColors.borderSubtle),
              const SizedBox(height: AppSpacing.md),
              AppCard.flat(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const IconBox(
                      icon: Icons.shield_outlined,
                      color: AppColors.success,
                      isCompact: true,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Active Operator Session', style: AppText.bodyBold),
                          const SizedBox(height: 2),
                          Text(
                            'Full control over rosters, shift matrix, logistics & security badges.',
                            style: AppText.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Switch Account / Operator Login',
                icon: Icons.switch_account_rounded,
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton.destructive(
                label: 'Log Out Session',
                icon: Icons.logout_rounded,
                onPressed: () {
                  ApiService.currentUser = null;
                  Navigator.pop(ctx);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class OperatorHeaderButton extends StatelessWidget {
  const OperatorHeaderButton({super.key});

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;
    final isLoggedIn = user != null;
    final displayName = isLoggedIn ? (user.name.split(' ').first) : 'Operator Login';

    return InkWell(
      onTap: () {
        if (isLoggedIn) {
          showOperatorProfileSheet(context);
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      },
      borderRadius: BorderRadius.circular(AppRadius.inner),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isLoggedIn ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.inner),
          border: Border.all(
            color: isLoggedIn ? AppColors.primary.withOpacity(0.25) : AppColors.borderStrong,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLoggedIn ? Icons.account_circle_rounded : Icons.login_rounded,
              size: 16,
              color: isLoggedIn ? AppColors.primary : AppColors.textPrimary,
            ),
            const SizedBox(width: 5),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Text(
                displayName,
                style: AppText.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isLoggedIn ? AppColors.primary : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
