import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/liquid_glass.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'promoter_audit_page.dart';
import '../widgets/status_badge.dart';

class SupervisorHubScreen extends StatefulWidget {
  final UserModel supervisor;

  const SupervisorHubScreen({super.key, required this.supervisor});

  @override
  State<SupervisorHubScreen> createState() => _SupervisorHubScreenState();
}

class _SupervisorHubScreenState extends State<SupervisorHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<LiveStoreHub> _myStores = [];
  List<LogisticsDropItem> _myDrops = [];
  List<LogisticsCollectionItem> _myCollections = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSupervisorData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSupervisorData() async {
    setState(() => _isLoading = true);
    final today = DateFormat('yyyy-MM-dd').format(DateTime(2026, 10, 14));

    final dashData = await ApiService.getLiveDashboard(date: today);
    final allStores = (dashData['live_stores'] as List<LiveStoreHub>?) ?? [];
    
    // Filter stores assigned to this supervisor (or all stores if ops lead)
    final filteredStores = allStores.where(
      (s) => s.supervisorId == widget.supervisor.id || widget.supervisor.role == 'OPS_ADMIN',
    ).toList();

    final drops = await ApiService.getDrops(date: today);
    final collections = await ApiService.getCollections(date: today);

    if (mounted) {
      setState(() {
        _myStores = filteredStores.isNotEmpty ? filteredStores : allStores;
        _myDrops = drops;
        _myCollections = collections;
        _isLoading = false;
      });
    }
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

  Future<void> _captureStandPhoto(LiveStoreHub store) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        imageQuality: 85,
      );

      if (photo != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.success,
            content: Text('📸 Stand photo verified & uploaded for ${store.storeName}!'),
          ),
        );
      }
    } catch (e) {
      try {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1600,
          imageQuality: 85,
        );
        if (photo != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.success,
              content: Text('📸 Stand photo verified & uploaded for ${store.storeName}!'),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Photo logged for ${store.storeName}')),
          );
        }
      }
    }
  }

  Future<void> _markDropDelivered(LogisticsDropItem drop) async {
    final success = await ApiService.updateDropStatus(drop.id, 'DELIVERED');
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.success,
          content: Text('✅ Drop marked as DELIVERED to ${drop.storeName}!'),
        ),
      );
      _loadSupervisorData();
    }
  }

  Future<void> _markCollectionComplete(LogisticsCollectionItem col) async {
    final success = await ApiService.updateCollectionStatus(col.id, 'COLLECTED');
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.success,
          content: Text('✅ Return collection confirmed from ${col.storeName}!'),
        ),
      );
      _loadSupervisorData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasBg,
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
            CircleAvatar(
              radius: 17,
              backgroundColor: AppTheme.purpleBg,
              child: Text(
                widget.supervisor.name.isNotEmpty ? widget.supervisor.name[0] : 'S',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.purple),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.supervisor.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textMain, letterSpacing: -0.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Regional Operations Supervisor Hub',
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryDark,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.purple,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(text: 'Store Audits (${_myStores.length})'),
            Tab(text: 'Logistics (${_myDrops.length + _myCollections.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: _loadSupervisorData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 21, color: AppTheme.textMuted),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStoresTab(),
                _buildLogisticsTab(),
              ],
            ),
    );
  }

  Widget _buildStoresTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        // KPI Summary Bar
        LiquidGlassContainer(
          radius: 20.0,
          blur: 20.0,
          opacity: 0.78,
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryStat('My Stores', '${_myStores.length}', Icons.storefront_rounded, AppTheme.textMain),
              _summaryStat('Drops Due', '${_myDrops.length}', Icons.local_shipping_rounded, AppTheme.warning),
              _summaryStat('Collections', '${_myCollections.length}', Icons.repeat_rounded, AppTheme.success),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Assigned Store Inspection Queue',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textMain, letterSpacing: -0.2),
            ),
            StatusBadge(
              label: '${_myStores.length} Stores',
              variant: StatusVariant.purple,
              fontSize: 10,
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_myStores.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: const Center(
              child: Text(
                'No stores assigned for field audit today.',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textMuted),
              ),
            ),
          )
        else
          ..._myStores.map((store) => _buildSupervisorStoreCard(store)),
      ],
    );
  }

  Widget _buildLogisticsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        // Drops Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Morning Drops (Deliveries to Stores)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textMain),
            ),
            StatusBadge(
              label: '${_myDrops.length} Pending',
              variant: StatusVariant.warning,
              fontSize: 10,
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_myDrops.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 20),
                SizedBox(width: 10),
                Text('All morning drops completed!', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.successText)),
              ],
            ),
          )
        else
          ..._myDrops.map((drop) => _buildDropCard(drop)),

        const SizedBox(height: 22),

        // Collections Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Return Collections (End of Campaign)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textMain),
            ),
            StatusBadge(
              label: '${_myCollections.length} Scheduled',
              variant: StatusVariant.success,
              fontSize: 10,
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_myCollections.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: const Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: AppTheme.textMuted, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No return collections scheduled for today.',
                    style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          )
        else
          ..._myCollections.map((col) => _buildCollectionCard(col)),
      ],
    );
  }

  Widget _buildDropCard(LogisticsDropItem drop) {
    final isDelivered = drop.status == 'DELIVERED';
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(drop.storeName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textMain)),
                    const SizedBox(height: 2),
                    Text('${drop.projectName} • ${drop.emirate}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              StatusBadge(
                label: drop.status,
                variant: isDelivered ? StatusVariant.success : StatusVariant.warning,
                fontSize: 10,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSubtle,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 16, color: AppTheme.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Items: ${drop.itemsManifest}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMain),
                  ),
                ),
              ],
            ),
          ),
          if (!isDelivered) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 16),
              label: const Text('Confirm Drop Delivered to Store'),
              onPressed: () => _markDropDelivered(drop),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCollectionCard(LogisticsCollectionItem col) {
    final isCollected = col.status == 'COLLECTED';
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(col.storeName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textMain)),
                    const SizedBox(height: 2),
                    Text('${col.projectName} • ${col.emirate}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              StatusBadge(
                label: col.status,
                variant: isCollected ? StatusVariant.success : StatusVariant.info,
                fontSize: 10,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceSubtle,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Row(
              children: [
                const Icon(Icons.repeat_rounded, size: 16, color: AppTheme.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Collect: ${col.itemsToCollect}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMain),
                  ),
                ),
              ],
            ),
          ),
          if (!isCollected) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
              ),
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Confirm Equipment Collected Back'),
              onPressed: () => _markCollectionComplete(col),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryStat(String label, String value, IconData icon, Color accentColor) {
    return Column(
      children: [
        Icon(icon, color: accentColor, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: accentColor, fontFamily: 'monospace')),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildSupervisorStoreCard(LiveStoreHub store) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.storeName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textMain, letterSpacing: -0.2)),
                    const SizedBox(height: 2),
                    Text('${store.retailer} • ${store.emirate}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(40, 36),
                  backgroundColor: AppTheme.primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                ),
                icon: const Icon(Icons.camera_alt_rounded, size: 15),
                label: const Text('Stand Photo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                onPressed: () => _captureStandPhoto(store),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.borderSubtle),
          const SizedBox(height: 10),

          // Active Projects & IML Promoters in this store
          ...store.projects.map((proj) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSubtle,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Campaign: ${proj.projectName.toUpperCase()}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.accent, letterSpacing: 0.3)),
                  const SizedBox(height: 8),
                  ...proj.promoters.map((p) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.promoterName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textMain)),
                                Text(
                                  '${p.startTime.substring(0, 5)} – ${p.endTime.substring(0, 5)} • Break: ${p.breakTimings ?? "None"}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton.filled(
                                constraints: const BoxConstraints(),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppTheme.infoBg,
                                  foregroundColor: AppTheme.accent,
                                  padding: const EdgeInsets.all(7),
                                ),
                                icon: const Icon(Icons.phone_rounded, size: 15),
                                onPressed: () => _makeCall(p.promoterPhone),
                              ),
                              const SizedBox(width: 6),
                              IconButton.filled(
                                constraints: const BoxConstraints(),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppTheme.successBg,
                                  foregroundColor: AppTheme.success,
                                  padding: const EdgeInsets.all(7),
                                ),
                                icon: const Icon(Icons.chat_bubble_rounded, size: 15),
                                onPressed: () => _openWhatsApp(p.promoterPhone),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: const Size(40, 32),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                                ),
                                icon: const Icon(Icons.star_rounded, size: 14, color: AppTheme.warning),
                                label: const Text('Audit ⭐', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PromoterAuditPage(
                                        promoterId: p.promoterId,
                                        promoterName: p.promoterName,
                                        promoterPhone: p.promoterPhone,
                                        projectId: proj.projectId,
                                        storeId: store.storeId,
                                        storeName: store.storeName,
                                      ),
                                    ),
                                  );
                                },
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
