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
  const OpsDashboardScreen({super.key});

  @override
  State<OpsDashboardScreen> createState() => _OpsDashboardScreenState();
}

class _OpsDashboardScreenState extends State<OpsDashboardScreen> {
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
      backgroundColor: AppTheme.canvasBg,
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
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'Refresh Operations',
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 21, color: AppTheme.textMuted),
            tooltip: 'Sign Out',
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: LiquidGlassButton(
        blur: 24.0,
        radius: 22.0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        tintColor: AppTheme.primaryDark.withOpacity(0.90),
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
      bottomNavigationBar: LiquidGlassNavBar(
        currentIndex: 0,
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
          if (idx == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TimeMapCalendarScreen()));
          } else if (idx == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BadgeTrackerScreen()))
                .then((_) => _loadDashboardData());
          } else if (idx == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreManagementScreen()))
                .then((_) => _loadDashboardData());
          }
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  children: [
                    // Search Bar
                    TextField(
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
                        fillColor: Colors.white,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
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
    );
  }

  Widget _buildKpiSection() {
    final liveStoresCount = _kpis['live_stores_count'] ?? 0;
    final activePromotersCount = _kpis['active_promoters_count'] ?? 0;
    final pendingDrops = _kpis['pending_drops'] ?? 0;
    final pendingCollections = _kpis['pending_collections'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _kpiTile('Live Stores', '$liveStoresCount', Icons.storefront_rounded, AppTheme.accentTeal, AppTheme.surfaceSubtle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _kpiTile('Promoters', '$activePromotersCount', Icons.people_alt_rounded, AppTheme.accent, AppTheme.infoBg),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _kpiTile('Drops Due', '$pendingDrops', Icons.local_shipping_rounded, AppTheme.warning, AppTheme.warningBg),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _kpiTile('Collections', '$pendingCollections', Icons.repeat_rounded, AppTheme.success, AppTheme.successBg),
        ),
      ],
    );
  }

  Widget _kpiTile(String title, String count, IconData icon, Color color, Color bgTint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textMain,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: bgTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
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
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BadgeTrackerScreen()),
              );
              _loadDashboardData();
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

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
          // Store Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Retailer Avatar Emblem
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: retailerColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: retailerColor.withOpacity(0.25)),
                ),
                child: Center(
                  child: Text(
                    store.retailer.isNotEmpty ? store.retailer[0] : 'S',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: retailerColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.storeName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMain,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        StatusBadge(
                          label: store.emirate,
                          variant: StatusVariant.neutral,
                          fontSize: 10,
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          store.retailer,
                          style: TextStyle(
                            fontSize: 11,
                            color: retailerColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Field Lead / Supervisor Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 9,
                      backgroundColor: AppTheme.primaryDark,
                      child: Text(
                        store.supervisorName.isNotEmpty ? store.supervisorName[0] : 'S',
                        style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      store.supervisorName,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMain),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
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
                                '${p.startTime.substring(0, 5)} – ${p.endTime.substring(0, 5)}',
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

                          // Thumb-zone action pills (Call, WhatsApp, Audit)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 34),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                                  ),
                                  icon: const Icon(Icons.phone_rounded, size: 14, color: AppTheme.success),
                                  label: const Text('Call', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                  onPressed: () => _makeCall(p.promoterPhone),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 34),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                                  ),
                                  icon: const Icon(Icons.chat_bubble_rounded, size: 14, color: AppTheme.accent),
                                  label: const Text('WhatsApp', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                  onPressed: () => _openWhatsApp(p.promoterPhone),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 34),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                                  ),
                                  icon: const Icon(Icons.star_rounded, size: 14, color: AppTheme.warning),
                                  label: const Text('Audit ⭐', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
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
}
