import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppScreenScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? body;
  final List<Widget>? slivers;
  final Widget? floatingBottom;
  final bool bottomClearance;
  final Future<void> Function()? onRefresh;

  const AppScreenScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.body,
    this.slivers,
    this.floatingBottom,
    this.bottomClearance = false,
    this.onRefresh,
  }) : assert(body != null || slivers != null, 'Either body or slivers must be provided');

  @override
  Widget build(BuildContext context) {
    final bottomPadding = (bottomClearance ? AppSpacing.navClearance : AppSpacing.lg) +
        MediaQuery.of(context).viewPadding.bottom;

    Widget scrollView = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: [
        if (slivers != null) ...slivers!,
        if (body != null)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.md,
              AppSpacing.screenH,
              bottomPadding,
            ),
            sliver: SliverToBoxAdapter(child: body!),
          )
        else
          SliverPadding(
            padding: EdgeInsets.only(bottom: bottomPadding),
          ),
      ],
    );

    if (onRefresh != null) {
      scrollView = RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: onRefresh!,
        child: scrollView,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        leading: leading,
        titleSpacing: leading != null ? 0 : AppSpacing.screenH,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: AppText.titleLarge,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 1),
              Text(
                subtitle!,
                style: AppText.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        actions: actions != null
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.screenH),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!,
                  ),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        bottom: false,
        child: scrollView,
      ),
      bottomNavigationBar: floatingBottom,
    );
  }
}
