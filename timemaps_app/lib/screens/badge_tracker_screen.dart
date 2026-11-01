import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'create_badge_page.dart';

class BadgeTrackerScreen extends StatefulWidget {
  const BadgeTrackerScreen({super.key});

  @override
  State<BadgeTrackerScreen> createState() => _BadgeTrackerScreenState();
}

class _BadgeTrackerScreenState extends State<BadgeTrackerScreen> {
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
        SnackBar(content: Text('${badge.promoterName} moved to "$newStatus"')),
      );
      _loadBadges();
    }
  }

  Color _getStatusBg(String status) {
    switch (status) {
      case 'Approved':
        return const Color(0xFFECFDF5);
      case 'Pending with security':
        return const Color(0xFFFFF7ED);
      case 'Pending with HR':
        return const Color(0xFFFEF3C7);
      case 'Documents ready for collection':
        return const Color(0xFFF1F5F9);
      case 'Rejected':
        return const Color(0xFFFEF2F2);
      default:
        return const Color(0xFFEFF6FF);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'Approved':
        return AppTheme.accentEmerald;
      case 'Pending with security':
        return const Color(0xFFC2410C);
      case 'Pending with HR':
        return const Color(0xFFB45309);
      case 'Documents ready for collection':
        return const Color(0xFF475569);
      case 'Rejected':
        return AppTheme.danger;
      default:
        return AppTheme.primary;
    }
  }

  Color _getStatusBorder(String status) {
    switch (status) {
      case 'Approved':
        return const Color(0xFFA7F3D0);
      case 'Pending with security':
        return const Color(0xFFFED7AA);
      case 'Pending with HR':
        return const Color(0xFFFDE68A);
      case 'Documents ready for collection':
        return const Color(0xFFCBD5E1);
      case 'Rejected':
        return const Color(0xFFFECACA);
      default:
        return const Color(0xFFBFDBFE);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Store Badge Tracker', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textMain)),
            Text('UAE Hypermarket Security & Gate Permits', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Badges',
            onPressed: _loadBadges,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Submit Badge',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateBadgePage()),
              );
              if (result == true) _loadBadges();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Submit Badge', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateBadgePage()),
          );
          if (result == true) _loadBadges();
        },
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by promoter, store, or project...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.textMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _loadBadges();
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
                          selectedColor: AppTheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.textMain,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 11,
                          ),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.borderSubtle),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderSubtle),

          // Badges List View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _badges.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.badge_outlined, size: 48, color: AppTheme.textMuted),
                            const SizedBox(height: 12),
                            const Text(
                              'No badge applications found',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textMain),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Submit a new store permit to get started',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Submit Store Badge'),
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
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 80),
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
    );
  }

  Widget _buildBadgeCard(BadgeModel badge) {
    final bg = _getStatusBg(badge.status);
    final textCol = _getStatusTextColor(badge.status);
    final borderCol = _getStatusBorder(badge.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Promoter Name & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        badge.promoterName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textMain),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        badge.projectName,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: borderCol),
                  ),
                  child: Text(
                    badge.status.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: textCol),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppTheme.borderSubtle),
            const SizedBox(height: 10),

            // Store Info Row
            Row(
              children: [
                const Icon(Icons.storefront_outlined, size: 16, color: AppTheme.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${badge.storeName} • ${badge.emirate}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMain),
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
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                if (badge.badgeNumber != null)
                  Text(
                    'Pass #: ${badge.badgeNumber}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'monospace', color: AppTheme.textMain),
                  ),
              ],
            ),

            if (badge.notes != null && badge.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        badge.notes!,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Action Row: Advance Lifecycle Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Advance Status:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: const Row(
                      children: [
                        Text('Update Stage', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down_rounded, size: 16, color: AppTheme.primary),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _popupItem(String value, String label, IconData icon) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
