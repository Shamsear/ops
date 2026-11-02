import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'create_badge_page.dart';

class BadgeTrackerScreen extends StatefulWidget {
  final bool isEmbedded;
  const BadgeTrackerScreen({super.key, this.isEmbedded = false});

  @override
  State<BadgeTrackerScreen> createState() => _BadgeTrackerScreenState();
}

class _BadgeTrackerScreenState extends State<BadgeTrackerScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isLoading = true;
  List<BadgeModel> _badges = [];
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filterTabs = [
    'All',
    'Approved',
    'Pending with security',
    'Pending with HR',
    'Documents ready for collection',
    'Rejected',
  ];

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBadges() async {
    setState(() => _isLoading = true);
    final badges = await ApiService.getBadges(
      status: _selectedFilter == 'All' ? null : _selectedFilter,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
    if (mounted) {
      setState(() {
        _badges = badges;
        _isLoading = false;
      });
    }
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    _loadBadges();
  }

  Future<void> _updateStatus(BadgeModel badge, String newStatus) async {
    final success = await ApiService.updateBadgeStatus(badge.id, newStatus);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${badge.promoterName} permit updated to "$newStatus"',
                  style: AppText.bodyBold.copyWith(color: Colors.white),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
      _loadBadges();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final hrCount = _badges.where((b) => b.status.toLowerCase().contains('hr')).length;
    final securityCount = _badges.where((b) => b.status.toLowerCase().contains('security')).length;
    final approvedCount = _badges.where((b) => b.status.toLowerCase().contains('approved')).length;

    return AppScreenScaffold(
      title: 'Store Badge Tracker',
      subtitle: 'Hypermarket Gate Passes & Mall Permits',
      leading: widget.isEmbedded ? null : const BackButton(color: AppColors.textPrimary),
      bottomClearance: widget.isEmbedded,
      onRefresh: _loadBadges,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textPrimary),
          tooltip: 'Refresh Badges',
          onPressed: _loadBadges,
        ),
        AppButton(
          label: 'New Pass',
          icon: Icons.add_rounded,
          height: 36,
          width: 110,
          onPressed: () async {
            final res = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateBadgePage()),
            );
            if (res == true) _loadBadges();
          },
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Stage KPI Summary Strip
          Row(
            children: [
              Expanded(
                child: KpiTile(
                  label: 'HR Review',
                  value: '$hrCount',
                  icon: Icons.business_outlined,
                  iconColor: AppColors.warning,
                  isSelected: _selectedFilter == 'Pending with HR',
                  onTap: () => _onFilterChanged(_selectedFilter == 'Pending with HR' ? 'All' : 'Pending with HR'),
                ),
              ),
              const SizedBox(width: AppSpacing.itemGap),
              Expanded(
                child: KpiTile(
                  label: 'Security Check',
                  value: '$securityCount',
                  icon: Icons.security_outlined,
                  iconColor: AppColors.accent,
                  isSelected: _selectedFilter == 'Pending with security',
                  onTap: () => _onFilterChanged(_selectedFilter == 'Pending with security' ? 'All' : 'Pending with security'),
                ),
              ),
              const SizedBox(width: AppSpacing.itemGap),
              Expanded(
                child: KpiTile(
                  label: 'Approved',
                  value: '$approvedCount',
                  icon: Icons.verified_user_rounded,
                  iconColor: AppColors.success,
                  isSelected: _selectedFilter == 'Approved',
                  onTap: () => _onFilterChanged(_selectedFilter == 'Approved' ? 'All' : 'Approved'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 2. Search & Filter Bar
          AppCard.compact(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _searchController,
                  hint: 'Search promoter, store, or pass #...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.accent),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _loadBadges();
                          },
                        )
                      : null,
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim());
                    _loadBadges();
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filterTabs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (ctx, i) {
                      final tab = _filterTabs[i];
                      return FilterPill(
                        label: StatusBadge.formatStatusLabel(tab),
                        isSelected: _selectedFilter == tab,
                        onTap: () => _onFilterChanged(tab),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 3. Section Header
          SectionHeader(
            icon: Icons.badge_outlined,
            iconColor: AppColors.primary,
            microLabel: 'Active Pipeline',
            title: 'Permit Applications',
            trailing: StatusBadge(
              label: '${_badges.length} Applications',
              variant: StatusVariant.info,
            ),
          ),

          // 4. Badges List
          if (_isLoading)
            const AppSkeletonList(count: 4)
          else if (_badges.isEmpty)
            EmptyState(
              icon: Icons.badge_outlined,
              title: 'No badge applications found',
              description: 'Try adjusting your filter criteria or apply for a new store permit.',
              actionLabel: 'Apply Store Badge',
              onAction: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateBadgePage()),
                );
                if (res == true) _loadBadges();
              },
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _badges.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.itemGap),
              itemBuilder: (ctx, index) => _buildBadgeCard(_badges[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(BadgeModel badge) {
    final statusLower = badge.status.toLowerCase();
    int currentStage = 1;
    if (statusLower.contains('security') || statusLower.contains('collection')) {
      currentStage = 2;
    } else if (statusLower.contains('approved')) {
      currentStage = 3;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Campaign, Status Badge
          Row(
            children: [
              InitialsAvatar(name: badge.promoterName, size: 36),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badge.promoterName,
                      style: AppText.bodyBold,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      badge.projectName.toUpperCase(),
                      style: AppText.micro.copyWith(color: AppColors.accent),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusBadge.fromStatus(badge.status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Store Venue & Submitter Info
          Row(
            children: [
              const Icon(Icons.storefront_rounded, size: 15, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${badge.storeName} • ${badge.emirate}',
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Submitted by: ${badge.submittedBy}',
                style: AppText.caption,
              ),
              if (badge.badgeNumber != null)
                Text(
                  'Pass #: ${badge.badgeNumber}',
                  style: AppText.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'monospace',
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // 3-Segment Stage Progress Bar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: currentStage >= 1 ? AppColors.warning : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: currentStage >= 2 ? AppColors.accent : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: currentStage >= 3 ? AppColors.success : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1. HR Review', style: AppText.micro.copyWith(fontSize: 9.5, color: currentStage >= 1 ? AppColors.textPrimary : AppColors.textMuted)),
              Text('2. Security Check', style: AppText.micro.copyWith(fontSize: 9.5, color: currentStage >= 2 ? AppColors.textPrimary : AppColors.textMuted)),
              Text('3. Gate Pass', style: AppText.micro.copyWith(fontSize: 9.5, color: currentStage >= 3 ? AppColors.textPrimary : AppColors.textMuted)),
            ],
          ),

          if (badge.notes != null && badge.notes!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            AppCard.flat(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      badge.notes!,
                      style: AppText.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: AppSpacing.sm),

          // Stage Advancement Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current: ${StatusBadge.formatStatusLabel(badge.status)}',
                style: AppText.caption.copyWith(fontWeight: FontWeight.w700),
              ),
              PopupMenuButton<String>(
                tooltip: 'Change Stage',
                onSelected: (newStatus) => _updateStatus(badge, newStatus),
                itemBuilder: (ctx) => [
                  _popupItem('Documents ready for collection', 'Ready for collection', Icons.inventory_2_outlined),
                  _popupItem('Submitted', 'Mark as Submitted', Icons.send_outlined),
                  _popupItem('Pending with HR', 'Pending with HR', Icons.business_outlined),
                  _popupItem('Pending with security', 'Pending with Security', Icons.security_outlined),
                  _popupItem('Approved', 'Approve Badge (Gate Pass)', Icons.check_circle_outline_rounded),
                  _popupItem('Rejected', 'Reject Application', Icons.cancel_outlined),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Advance Stage',
                        style: AppText.micro.copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _popupItem(String value, String label, IconData icon) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(label, style: AppText.bodyBold.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}
