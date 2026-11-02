import 'dart:ui';
import '../widgets/liquid_glass.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
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
import '../widgets/status_badge.dart';


class OpsDashboardScreen extends StatefulWidget {
  final int initialTab;
  const OpsDashboardScreen({super.key, this.initialTab = 0});

  @override
  State<OpsDashboardScreen> createState() => _OpsDashboardScreenState();
}

class _OpsDashboardScreenState extends State<OpsDashboardScreen> {
  late int _currentNavIndex;
  String _selectedEmirate = 'All';
  DateTime _selectedDate = DateTime(2026, 10, 14);
  bool _isLoading = true;
  Map<String, dynamic> _kpis = {};
  List<LiveStoreHub> _liveStores = [];
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
    _loadDashboardData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final data = await ApiService.getLiveDashboard(
      date: dateStr,
      emirate: _selectedEmirate,
    );

    if (mounted) {
      setState(() {
        _kpis = data['kpis'] ?? {};
        _liveStores = data['live_stores'] ?? [];
        _isLoading = false;
      });
    }
  }

  void _onEmirateSelected(String emirate) {
    setState(() {
      _selectedEmirate = emirate;
    });
    _loadDashboardData();
  }

  void _openActionCenter() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OperationsMenuPage()),
    );
    if (res == true) _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return AmbientMeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: IndexedStack(
          index: _currentNavIndex,
          children: [
            _buildDashboardView(context),
            const TimeMapCalendarScreen(isEmbedded: true),
            const BadgeTrackerScreen(isEmbedded: true),
            const StoreManagementScreen(isEmbedded: true),
          ],
        ),
        bottomNavigationBar: LiquidGlassNavBar(
          currentIndex: _currentNavIndex,
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
            if (idx == 0) _loadDashboardData();
          },
        ),
      ),
    );
  }

  Widget _buildDashboardView(BuildContext context) {
    final dateDisplay = DateFormat('EEE, dd MMM yyyy').format(_selectedDate);
    final query = _searchQuery.toLowerCase().trim();
    final filteredStores = query.isEmpty
        ? _liveStores
        : _liveStores.where((s) {
            final matchStore = s.storeName.toLowerCase().contains(query);
            final matchRetailer = s.retailer.toLowerCase().contains(query);
            final matchSupervisor = s.supervisorName.toLowerCase().contains(query);
            final matchPromoter = s.projects.any((p) =>
                p.promoters.any((shift) => shift.promoterName.toLowerCase().contains(query)));
            return matchStore || matchRetailer || matchSupervisor || matchPromoter;
          }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      appBar: AppBar(
        titleSpacing: 16,
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryDark, AppTheme.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accent.withOpacity(0.20),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.explore_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'TimeMaps™',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textMain,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.successBg,
                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                          border: Border.all(color: AppTheme.successBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppTheme.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.successText,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
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
                    borderRadius: BorderRadius.circular(6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dateDisplay,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: AppTheme.accent),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                minimumSize: const Size(0, 34),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
                elevation: 0,
              ),
              icon: const Icon(Icons.add_rounded, size: 15),
              label: const Text('Action', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
              onPressed: _openActionCenter,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 21),
            tooltip: 'Refresh Operations',
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20, color: AppTheme.textMuted),
            tooltip: 'Sign Out',
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Positioned.fill(
                  child: SafeArea(
                    child: RefreshIndicator(
                      onRefresh: _loadDashboardData,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 160),
                        children: [
                          // Liquid Glass Search Bar
                    LiquidGlassContainer(
                      radius: 14.0,
                      blur: 16.0,
                      opacity: 0.85,
                      padding: EdgeInsets.zero,
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMain),
                        decoration: InputDecoration(
                          hintText: 'Search stores, promoters, chains, or supervisors...',
                          hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                          prefixIcon: const Icon(Icons.search_rounded, size: 19, color: AppTheme.accent),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          fillColor: Colors.transparent,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Bento Grid KPI Section
                    _buildKpiSection(),
                    const SizedBox(height: 14),

                    // Quick Action Shortcuts Bar
                    _buildQuickActionButtons(),
                    const SizedBox(height: 14),

                    // Emirate Filter Chips
                    _buildEmirateFilter(),
                    const SizedBox(height: 16),

                    // Section Title Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Live Deployment Roster',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textMain,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(
                              label: '${filteredStores.length} Active',
                              variant: StatusVariant.info,
                              fontSize: 11,
                            ),
                          ],
                        ),
                        Text(
                          _selectedEmirate == 'All' ? 'UAE National' : _selectedEmirate,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Store List
                    if (filteredStores.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                          border: Border.all(color: AppTheme.borderSubtle),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: const BoxDecoration(
                                color: AppTheme.surfaceSubtle,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.storefront_outlined, size: 38, color: AppTheme.textMuted),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Active Stores Matching Filter',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textMain),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Clear search terms or change region filter to view operations',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Schedule Shifts Now'),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateSchedulePage()))
                                    .then((_) => _loadDashboardData());
                              },
                            ),
                          ],
                        ),
                      )
                    else
                      ...filteredStores.map((store) => _buildStoreCard(store)),
                  ],
                ),
              ),
            ),
          ),

          // Floating Action Pill dynamically positioned cleanly above the Liquid Glass Nav Bar
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 84,
            child: LiquidGlassButton(
              blur: 24.0,
              radius: 22.0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              tintColor: AppTheme.primaryDark.withOpacity(0.92),
              borderGradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.55),
                  Colors.white.withOpacity(0.20),
                  Colors.white.withOpacity(0.06),
                ],
              ),
              onPressed: _openActionCenter,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 20, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'New Action',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white, letterSpacing: -0.1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiSection() {
    final liveStoresCount = _kpis['live_stores_count'] ?? 0;
    final activePromotersCount = _kpis['active_promoters_count'] ?? 0;
    final pendingDrops = _kpis['pending_drops'] ?? 0;
    final pendingCollections = _kpis['pending_collections'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _kpiTile(
                title: 'Live Stores',
                subtitle: 'Active hypermarkets',
                count: '$liveStoresCount',
                icon: Icons.storefront_rounded,
                color: AppTheme.accentTeal,
                bgTint: const Color(0xFFCCFBF1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiTile(
                title: 'Active Staff',
                subtitle: 'Promoters on duty',
                count: '$activePromotersCount',
                icon: Icons.people_alt_rounded,
                color: AppTheme.accent,
                bgTint: AppTheme.infoBg,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _kpiTile(
                title: 'Drops Due',
                subtitle: 'Stand deliveries',
                count: '$pendingDrops',
                icon: Icons.local_shipping_rounded,
                color: AppTheme.warning,
                bgTint: AppTheme.warningBg,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _kpiTile(
                title: 'Collections',
                subtitle: 'Teardowns pending',
                count: '$pendingCollections',
                icon: Icons.repeat_rounded,
                color: AppTheme.success,
                bgTint: AppTheme.successBg,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _kpiTile({
    required String title,
    required String subtitle,
    required String count,
    required IconData icon,
    required Color color,
    required Color bgTint,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: 16.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: bgTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              Text(
                count,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textMain,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.textMain,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.bolt_rounded, size: 16),
            label: const Text('Batch Schedule', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateSchedulePage()),
              );
              if (res == true) _loadDashboardData();
            },
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.badge_outlined, size: 16, color: AppTheme.purple),
            label: const Text('Badges', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            onPressed: () {
              setState(() => _currentNavIndex = 2);
            },
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.campaign_outlined, size: 16, color: AppTheme.accentRose),
            label: const Text('+ Campaign', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateProjectPage()),
              );
              if (res == true) _loadDashboardData();
            },
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.storefront_outlined, size: 16, color: AppTheme.accentTeal),
            label: const Text('+ Store', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateStorePage()),
              );
              if (res == true) _loadDashboardData();
            },
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.person_add_alt_outlined, size: 16, color: AppTheme.accentAmber),
            label: const Text('+ Promoter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePromoterPage()),
              );
              if (res == true) _loadDashboardData();
            },
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.local_shipping_outlined, size: 16, color: AppTheme.warning),
            label: const Text('Drop', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateDropPage()),
              );
              if (res == true) _loadDashboardData();
            },
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.repeat_rounded, size: 16, color: AppTheme.success),
            label: const Text('Collection', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
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
    );
  }

  Widget _buildEmirateFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _emirates.map((emirate) {
          final isSelected = _selectedEmirate == emirate;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(emirate),
              selected: isSelected,
              onSelected: (_) => _onEmirateSelected(emirate),
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textMain,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 11,
              ),
              backgroundColor: AppTheme.surfaceSubtle,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.borderSubtle),
              ),
            ),
          );
        }).toList(),
      ),
    );
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

  Color _getRetailerColor(String retailer) {
    final r = retailer.toLowerCase();
    if (r.contains('lulu')) return AppTheme.success;
    if (r.contains('carrefour')) return AppTheme.accent;
    if (r.contains('coop')) return AppTheme.warning;
    if (r.contains('spinneys')) return AppTheme.accentTeal;
    return AppTheme.primaryDark;
  }

  Widget _buildStoreCard(LiveStoreHub store) {
    final retailerColor = _getRetailerColor(store.retailer);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      radius: AppTheme.radiusLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Header: Full-Width Title Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Retailer Avatar Emblem
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: retailerColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: retailerColor.withOpacity(0.25)),
                ),
                child: Center(
                  child: Text(
                    store.retailer.isNotEmpty ? store.retailer[0] : 'S',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: retailerColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Full Width Store Name
              Expanded(
                child: Text(
                  store.storeName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMain,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Metadata Row: Retailer Chip, Emirate Badge, and Field Lead Pill
          Row(
            children: [
              StatusBadge(
                label: store.emirate,
                variant: StatusVariant.neutral,
                fontSize: 10,
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: retailerColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(color: retailerColor.withOpacity(0.20)),
                ),
                child: Text(
                  store.retailer,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: retailerColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              // Field Lead / Supervisor Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 8,
                      backgroundColor: AppTheme.primaryDark,
                      child: Text(
                        store.supervisorName.isNotEmpty ? store.supervisorName[0] : 'S',
                        style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      store.supervisorName,
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppTheme.textMain),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.borderSubtle),
          const SizedBox(height: 12),

          // Concurrent Projects & Promoters Roster
          ...store.projects.map((project) {
            final isSadia = project.projectName.toLowerCase().contains('sadia');
            final accentColor = isSadia ? AppTheme.accentRose : AppTheme.accent;
            final bgColor = isSadia ? AppTheme.dangerBg : AppTheme.infoBg;
            final borderColor = isSadia ? AppTheme.dangerBorder : AppTheme.infoBorder;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor.withOpacity(0.4),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 14,
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            project.projectName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                      StatusBadge(
                        label: '${project.promoters.length} Staff On Duty',
                        variant: StatusVariant.neutral,
                        fontSize: 10,
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Promoters roster under this project
                  ...project.promoters.map((p) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(color: AppTheme.borderSubtle),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 13,
                                    backgroundColor: AppTheme.infoBg,
                                    child: const Icon(Icons.person, size: 15, color: AppTheme.accent),
                                  ),
                                  const SizedBox(width: 9),
                                  Text(
                                    p.promoterName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textMain,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                              StatusBadge.fromStatus('ON DUTY'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 13, color: AppTheme.textMuted),
                              const SizedBox(width: 5),
                              Text(
                                '${_formatTime(p.startTime)} – ${_formatTime(p.endTime)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textSecondary,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('•', style: TextStyle(color: AppTheme.textMuted)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Break: ${p.breakTimings ?? "None"}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Thumb-zone action pills (Call, WhatsApp, Audit) - Single-line guaranteed
                          Row(
                            children: [
                              Expanded(
                                child: _promoterActionButton(
                                  icon: Icons.phone_rounded,
                                  iconColor: AppTheme.success,
                                  label: 'Call',
                                  onPressed: () => _makeCall(p.promoterPhone),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _promoterActionButton(
                                  icon: Icons.chat_bubble_rounded,
                                  iconColor: AppTheme.accent,
                                  label: 'WhatsApp',
                                  onPressed: () => _openWhatsApp(p.promoterPhone),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: _promoterActionButton(
                                  icon: Icons.star_rounded,
                                  iconColor: AppTheme.warning,
                                  label: 'Audit',
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
                    );
                  }),
                ],
              ),
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

  Widget _promoterActionButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
        side: const BorderSide(color: AppTheme.borderSubtle, width: 1.0),
        backgroundColor: Colors.white,
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 4),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
