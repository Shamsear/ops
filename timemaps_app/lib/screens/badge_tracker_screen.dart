import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
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
          backgroundColor: AppTheme.success,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('${badge.promoterName} permit updated to "$newStatus"'),
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isEmbedded,
        titleSpacing: 16,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Store Badge Tracker',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textMain, letterSpacing: -0.2),
            ),
            Text(
              'Hypermarket Gate Passes & Mall Permits',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'Refresh Badges',
            onPressed: _loadBadges,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: const Size(0, 38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Apply Badge', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateBadgePage()),
                );
                if (result == true) _loadBadges();
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search & Filter Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
              ),
              child: Column(
                children: [
                  // Search Input
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMain),
                    decoration: InputDecoration(
                      hintText: 'Search by promoter, store, or project...',
                      hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                      prefixIcon: const Icon(Icons.search_rounded, size: 19, color: AppTheme.purple),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 17),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                _loadBadges();
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      isDense: true,
                      filled: true,
                      fillColor: AppTheme.surfaceSubtle,
                    ),
                    onSubmitted: (query) {
                      setState(() => _searchQuery = query.trim());
                      _loadBadges();
                    },
                  ),
                  const SizedBox(height: 10),

                  // Filter Tabs (Horizontal Scroll)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filterTabs.map((tab) {
                        final isSelected = _selectedFilter == tab;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(tab),
                            selected: isSelected,
                            onSelected: (_) => _onFilterChanged(tab),
                            selectedColor: AppTheme.primaryDark,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textMain,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 11,
                            ),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                              side: BorderSide(color: isSelected ? AppTheme.primaryDark : AppTheme.borderSubtle),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Badges List View
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _badges.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: const BoxDecoration(
                                  color: AppTheme.surfaceSubtle,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.badge_outlined, size: 40, color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No Badge Applications Found',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textMain),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Submit a new store permit application to get started',
                                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryDark,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                                ),
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Apply Store Badge'),
                                onPressed: () async {
                                  final res = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CreateBadgePage()),
                                  );
                                  if (res == true) _loadBadges();
                                },
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadBadges,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                            itemCount: _badges.length,
                            itemBuilder: (ctx, index) {
                              final badge = _badges[index];
                              return _buildBadgeCard(badge);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeCard(BadgeModel badge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.1),
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Promoter Name + Avatar + Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: AppTheme.purpleBg,
                child: Text(
                  badge.promoterName.isNotEmpty ? badge.promoterName[0] : 'P',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.purple),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badge.promoterName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textMain, letterSpacing: -0.2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      badge.projectName.toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.accent, letterSpacing: 0.3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge.fromStatus(badge.status),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.borderSubtle),
          const SizedBox(height: 10),

          // Store Info Row
          Row(
            children: [
              const Icon(Icons.storefront_rounded, size: 16, color: AppTheme.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${badge.storeName} • ${badge.emirate}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMain),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Submitter & Pass Number
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Submitted by: ${badge.submittedBy}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
              ),
              if (badge.badgeNumber != null)
                Text(
                  'Pass #: ${badge.badgeNumber}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMain, fontFamily: 'monospace'),
                ),
            ],
          ),

          if (badge.notes != null && badge.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSubtle,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 15, color: AppTheme.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      badge.notes!,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Action Row: Advance Lifecycle Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Permit Stage:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
              ),
              PopupMenuButton<String>(
                tooltip: 'Change Status',
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: const Row(
                    children: [
                      Text('Update Stage', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primaryDark)),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppTheme.primaryDark),
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
          Icon(icon, size: 16, color: AppTheme.primaryDark),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
