import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'timemap_calendar_screen.dart';
import 'login_screen.dart';
import 'create_schedule_page.dart';
import 'create_store_page.dart';
import 'create_promoter_page.dart';
import 'create_project_page.dart';
import 'create_drop_page.dart';
import 'create_collection_page.dart';
import 'promoter_audit_page.dart';
import 'operations_menu_page.dart';
import 'badge_tracker_screen.dart';
import 'store_management_screen.dart';

class OpsDashboardScreen extends StatefulWidget {
  final int initialTab;
  const OpsDashboardScreen({super.key, this.initialTab = 0});

  @override
  State<OpsDashboardScreen> createState() => _OpsDashboardScreenState();
}

class _OpsDashboardScreenState extends State<OpsDashboardScreen> {
  late int _currentNavIndex;
  late PageController _pageController;
  String _selectedEmirate = 'All';
  DateTime _selectedDate = DateTime(2026, 10, 14);
  bool _isLoading = true;
  Map<String, dynamic> _kpis = {};
  List<LiveStoreHub> _allLiveStores = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _emirates = [
    'All',
    'Dubai',
    'Abu Dhabi',
    'Sharjah',
    'Ajman',
    'Al Ain',
    'Ras Al Khaimah',
    'Fujairah',
  ];

  @override
  void initState() {
    super.initState();
    _currentNavIndex = widget.initialTab;
    _pageController = PageController(initialPage: _currentNavIndex);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData({bool isUserPull = false}) async {
    if (!isUserPull && _allLiveStores.isEmpty) {
      setState(() => _isLoading = true);
    }
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final data = await ApiService.getLiveDashboard(
      date: dateStr,
      emirate: 'All', // Always load national data so emirate filtering is instant
    );

    if (mounted) {
      setState(() {
        _kpis = data['kpis'] ?? {};
        _allLiveStores = data['live_stores'] ?? [];
        _isLoading = false;
      });
    }
  }

  void _onEmirateSelected(String emirate) {
    setState(() {
      _selectedEmirate = emirate;
    });
  }

  void _openActionCenter() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OperationsMenuPage()),
    );
    if (res == true) _loadDashboardData(isUserPull: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (idx) {
          setState(() {
            _currentNavIndex = idx;
          });
        },
        children: [
          _buildDashboardView(context),
          const TimeMapCalendarScreen(isEmbedded: true),
          const BadgeTrackerScreen(isEmbedded: true),
          const StoreManagementScreen(isEmbedded: true),
        ],
      ),
      bottomNavigationBar: LiquidGlassNavBar(
        currentIndex: _currentNavIndex,
        pageController: _pageController,
        items: const [
          LiquidGlassNavItem(
            icon: Icons.dashboard_outlined,
            activeIcon: Icons.dashboard_rounded,
            label: 'Dashboard',
          ),
          LiquidGlassNavItem(
            icon: Icons.calendar_month_outlined,
            activeIcon: Icons.calendar_month_rounded,
            label: 'Calendar',
          ),
          LiquidGlassNavItem(
            icon: Icons.badge_outlined,
            activeIcon: Icons.badge_rounded,
            label: 'Badges',
          ),
          LiquidGlassNavItem(
            icon: Icons.storefront_outlined,
            activeIcon: Icons.storefront_rounded,
            label: 'Stores',
          ),
        ],
        onTap: (idx) {
          setState(() {
            _currentNavIndex = idx;
          });
          _pageController.animateToPage(
            idx,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
          );
        },
      ),
    );
  }

  Widget _buildDashboardView(BuildContext context) {
    final dateDisplay = DateFormat('EEE, dd MMM yyyy').format(_selectedDate);
    final query = _searchQuery.toLowerCase().trim();
    final filteredStores = _allLiveStores.where((s) {
      if (_selectedEmirate != 'All' &&
          !s.emirate.toLowerCase().contains(_selectedEmirate.toLowerCase())) {
        return false;
      }
      if (query.isEmpty) return true;
      final matchStore = s.storeName.toLowerCase().contains(query);
      final matchRetailer = s.retailer.toLowerCase().contains(query);
      final matchSupervisor = s.supervisorName.toLowerCase().contains(query);
      final matchPromoter = s.projects.any((p) =>
          p.promoters.any((shift) => shift.promoterName.toLowerCase().contains(query)));
      return matchStore || matchRetailer || matchSupervisor || matchPromoter;
    }).toList();

    return AppScreenScaffold(
      title: 'Command Dashboard',
      subtitle: '$dateDisplay • UAE Operations',
      bottomClearance: true,
      onRefresh: _loadDashboardData,
      actions: [
        const StatusBadge(
          label: 'LIVE',
          variant: StatusVariant.success,
          showDot: true,
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton(
          icon: const Icon(Icons.grid_view_rounded, size: 20, color: AppColors.primary),
          tooltip: 'Operations Menu',
          onPressed: _openActionCenter,
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textPrimary),
          tooltip: 'Refresh Operations',
          onPressed: _loadDashboardData,
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, size: 20, color: AppColors.textMuted),
          tooltip: 'Sign Out',
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Date Switcher Card
          AppCard.compact(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 22, color: AppColors.textPrimary),
                  tooltip: 'Previous Day',
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                    });
                    _loadDashboardData();
                  },
                ),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                      _loadDashboardData();
                    }
                  },
                  borderRadius: BorderRadius.circular(AppRadius.inner),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const IconBox(
                          icon: Icons.calendar_today_rounded,
                          color: AppColors.primary,
                          isCompact: true,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dateDisplay, style: AppText.bodyBold),
                            Text('Tap to change date', style: AppText.caption),
                          ],
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.textPrimary),
                  tooltip: 'Next Day',
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.add(const Duration(days: 1));
                    });
                    _loadDashboardData();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 2. KPI Section (2x2 Grid)
          _buildKpiGrid(filteredStores),
          const SizedBox(height: AppSpacing.md),

          // 3. Quick Action Shortcuts Carousel
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                AppButton(
                  label: 'Batch Schedule',
                  icon: Icons.bolt_rounded,
                  height: 36,
                  width: 140,
                  onPressed: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateSchedulePage()),
                    );
                    if (res == true) _loadDashboardData();
                  },
                ),
                const SizedBox(width: 8),
                AppButton.secondary(
                  label: '+ Campaign',
                  icon: Icons.campaign_outlined,
                  height: 36,
                  width: 125,
                  onPressed: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateProjectPage()),
                    );
                    if (res == true) _loadDashboardData();
                  },
                ),
                const SizedBox(width: 8),
                AppButton.secondary(
                  label: '+ Store',
                  icon: Icons.storefront_outlined,
                  height: 36,
                  width: 105,
                  onPressed: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateStorePage()),
                    );
                    if (res == true) _loadDashboardData();
                  },
                ),
                const SizedBox(width: 8),
                AppButton.secondary(
                  label: '+ Promoter',
                  icon: Icons.person_add_alt_outlined,
                  height: 36,
                  width: 120,
                  onPressed: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreatePromoterPage()),
                    );
                    if (res == true) _loadDashboardData();
                  },
                ),
                const SizedBox(width: 8),
                AppButton.secondary(
                  label: 'Drop',
                  icon: Icons.local_shipping_outlined,
                  height: 36,
                  width: 90,
                  onPressed: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateDropPage()),
                    );
                    if (res == true) _loadDashboardData();
                  },
                ),
                const SizedBox(width: 8),
                AppButton.secondary(
                  label: 'Collection',
                  icon: Icons.repeat_rounded,
                  height: 36,
                  width: 120,
                  onPressed: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateCollectionPage()),
                    );
                    if (res == true) _loadDashboardData();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 4. Search & Filter Bar
          AppCard.compact(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _searchController,
                  hint: 'Search stores, promoters, chains, or supervisors...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.accent),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _emirates.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (ctx, i) {
                      final em = _emirates[i];
                      return FilterPill(
                        label: em,
                        isSelected: _selectedEmirate == em,
                        onTap: () => _onEmirateSelected(em),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 5. Section Header
          SectionHeader(
            icon: Icons.storefront_rounded,
            iconColor: AppColors.primary,
            microLabel: _selectedEmirate == 'All' ? 'UAE National Deployment' : '$_selectedEmirate Region',
            title: 'Live Store Deployment',
            trailing: StatusBadge(
              label: '${filteredStores.length} Stores',
              variant: StatusVariant.info,
            ),
          ),

          // 6. Store Cards Roster
          if (_isLoading)
            const AppSkeletonList(count: 4)
          else if (filteredStores.isEmpty)
            EmptyState(
              icon: Icons.storefront_outlined,
              title: 'No active stores matching filter',
              description: 'Try adjusting your region or search filters, or schedule shifts now.',
              actionLabel: 'Schedule Shifts',
              onAction: () async {
                final res = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateSchedulePage()),
                );
                if (res == true) _loadDashboardData();
              },
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredStores.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.itemGap),
              itemBuilder: (ctx, idx) => _buildLiveStoreCard(filteredStores[idx]),
            ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(List<LiveStoreHub> currentStores) {
    final liveStoresCount = currentStores.length;
    final distinctStaff = <int>{};
    for (final s in currentStores) {
      for (final p in s.projects) {
        for (final shift in p.promoters) {
          if (shift.promoterId > 0) distinctStaff.add(shift.promoterId);
        }
      }
    }
    final activePromotersCount = distinctStaff.length;
    final pendingDrops = _kpis['pending_drops'] ?? 0;
    final pendingCollections = _kpis['pending_collections'] ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.itemGap,
      crossAxisSpacing: AppSpacing.itemGap,
      childAspectRatio: 1.45,
      children: [
        KpiTile(
          label: 'Live Stores',
          value: '$liveStoresCount',
          icon: Icons.storefront_rounded,
          iconColor: AppColors.accent,
        ),
        KpiTile(
          label: 'Active Staff',
          value: '$activePromotersCount',
          icon: Icons.people_alt_rounded,
          iconColor: AppColors.success,
        ),
        KpiTile(
          label: 'Drops Due',
          value: '$pendingDrops',
          icon: Icons.local_shipping_rounded,
          iconColor: AppColors.warning,
        ),
        KpiTile(
          label: 'Collections',
          value: '$pendingCollections',
          icon: Icons.repeat_rounded,
          iconColor: AppColors.purple,
        ),
      ],
    );
  }

  Widget _buildLiveStoreCard(LiveStoreHub store) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Chain Emblem + Store Name + Emirate Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InitialsAvatar(name: store.retailer, size: 36),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.storeName,
                      style: AppText.bodyBold,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            store.retailer,
                            style: AppText.caption.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('•', style: AppText.caption),
                        const SizedBox(width: 4),
                        Text(store.emirate, style: AppText.caption),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusBadge(
                label: store.emirate,
                variant: StatusVariant.neutral,
                maxWidth: 90,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Supervisor Pill Row
          AppCard.flat(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                const IconBox(
                  icon: Icons.supervisor_account_rounded,
                  color: AppColors.purple,
                  isCompact: true,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('FIELD SUPERVISOR', style: AppText.micro.copyWith(color: AppColors.textMuted)),
                      Text(
                        store.supervisorName,
                        style: AppText.bodySmall.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: AppSpacing.md),

          // Projects & Promoters Under This Store
          ...store.projects.map((project) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        project.projectName.toUpperCase(),
                        style: AppText.micro.copyWith(color: AppColors.accent),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StatusBadge(
                      label: '${project.promoters.length} Staff',
                      variant: StatusVariant.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ...project.promoters.map((p) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AppCard.flat(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const IconBox(
                                icon: Icons.person_rounded,
                                color: AppColors.primary,
                                isCompact: true,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p.promoterName,
                                  style: AppText.bodyBold,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const StatusBadge(
                                label: 'ON DUTY',
                                variant: StatusVariant.success,
                                showDot: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                '${_formatTime(p.startTime)} – ${_formatTime(p.endTime)}',
                                style: AppText.caption.copyWith(fontFamily: 'monospace'),
                              ),
                              const SizedBox(width: 6),
                              Text('•', style: AppText.caption),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Break: ${p.breakTimings ?? "None"}',
                                  style: AppText.caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: AppButton.secondary(
                                  label: 'Call',
                                  icon: Icons.phone_rounded,
                                  height: 32,
                                  onPressed: () => _makeCall(p.promoterPhone),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: AppButton.secondary(
                                  label: 'WhatsApp',
                                  icon: Icons.chat_bubble_rounded,
                                  height: 32,
                                  onPressed: () => _openWhatsApp(p.promoterPhone),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: AppButton.secondary(
                                  label: 'Audit',
                                  icon: Icons.star_rounded,
                                  height: 32,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PromoterAuditPage(
                                          promoterId: p.promoterId,
                                          promoterName: p.promoterName,
                                          promoterPhone: p.promoterPhone,
                                          storeId: store.storeId,
                                          storeName: store.storeName,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            );
          }),
        ],
      ),
    );
  }

  String _formatTime(String time) {
    if (time.length >= 5) return time.substring(0, 5);
    return time;
  }

  Future<void> _makeCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Calling $phone...')));
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening WhatsApp for $phone...')));
    }
  }
}
