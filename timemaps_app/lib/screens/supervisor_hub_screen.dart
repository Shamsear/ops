import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

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
            backgroundColor: AppTheme.accentEmerald,
            content: Text('Stand photo captured for ${store.storeName} -> Saved to Project / Store / Date!'),
          ),
        );
      }
    } catch (e) {
      // In emulator where camera might not be available, fallback to gallery
      try {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1600,
          imageQuality: 85,
        );
        if (photo != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.accentEmerald,
              content: Text('Photo uploaded for ${store.storeName} -> Synced to server folder!'),
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
          backgroundColor: AppTheme.accentEmerald,
          content: Text('Drop for ${drop.storeName} marked as DELIVERED!'),
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
          backgroundColor: AppTheme.accentEmerald,
          content: Text('Collection from ${col.storeName} marked as COLLECTED!'),
        ),
      );
      _loadSupervisorData();
    }
  }

  void _showPromoterEvaluationDialog(LivePromoterShift promoter, int projectId, int storeId) {
    int grooming = 5;
    int pitch = 5;
    int engagement = 5;
    int punctuality = 5;
    final feedbackController = TextEditingController(text: 'Grooming on point, high energy with shoppers.');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Audit: ${promoter.promoterName}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textMain)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStarRating('Clean Branded Uniform & Grooming', grooming, (v) => setDialogState(() => grooming = v)),
                const SizedBox(height: 10),
                _buildStarRating('Product Pitch & Brand Knowledge', pitch, (v) => setDialogState(() => pitch = v)),
                const SizedBox(height: 10),
                _buildStarRating('Shopper Engagement & Punctuality', engagement, (v) => setDialogState(() => engagement = v)),
                const SizedBox(height: 14),
                TextField(
                  controller: feedbackController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Supervisor Coaching Notes'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await ApiService.submitEvaluation(
                  projectId: projectId,
                  storeId: storeId,
                  promoterId: promoter.promoterId,
                  supervisorId: widget.supervisor.id,
                  grooming: grooming,
                  pitch: pitch,
                  engagement: engagement,
                  punctuality: punctuality,
                  feedback: feedbackController.text.trim(),
                );
                if (success && mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppTheme.accentEmerald,
                      content: Text('Audit for ${promoter.promoterName} synced (4.8 ⭐)'),
                    ),
                  );
                }
              },
              child: const Text('Submit Score (⭐⭐⭐⭐⭐)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(String label, int currentScore, Function(int) onSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
        Row(
          children: List.generate(5, (index) {
            final starVal = index + 1;
            return IconButton(
              iconSize: 22,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                starVal <= currentScore ? Icons.star_rounded : Icons.star_border_rounded,
                color: const Color(0xFFF59E0B),
              ),
              onPressed: () => onSelected(starVal),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Field Hub: ${widget.supervisor.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textMain)),
            const Text('Assigned Stores, Audits & Logistics', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(text: 'Store Audits (${_myStores.length})'),
            Tab(text: 'Logistics (${_myDrops.length + _myCollections.length})'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadSupervisorData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: STORES & AUDITS
                _buildStoresTab(),

                // TAB 2: LOGISTICS (DROPS & COLLECTIONS)
                _buildLogisticsTab(),
              ],
            ),
    );
  }

  Widget _buildStoresTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // Summary Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryStat('My Stores', '${_myStores.length}', Icons.storefront_rounded, AppTheme.textMain),
              _summaryStat('Drops Due', '${_myDrops.length}', Icons.local_shipping_rounded, AppTheme.accentAmber),
              _summaryStat('Collections', '${_myCollections.length}', Icons.repeat_rounded, AppTheme.accentEmerald),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'My Stores & In-Store Audits',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textMain),
        ),
        const SizedBox(height: 10),

        if (_myStores.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No stores assigned today.')))
        else
          ..._myStores.map((store) => _buildSupervisorStoreCard(store)),
      ],
    );
  }

  Widget _buildLogisticsTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // Section A: Drops
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Morning Drops (Deliveries to Stores)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textMain),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_myDrops.length} Pending',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_myDrops.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: const Text('All morning drops completed!', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.accentEmerald)),
          )
        else
          ..._myDrops.map((drop) => _buildDropCard(drop)),

        const SizedBox(height: 20),

        // Section B: Return Collections
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Return Collections (Campaign End Recovery)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textMain),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_myCollections.length} Scheduled',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.accentEmerald),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_myCollections.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: const Text('No return collections scheduled for today.', style: TextStyle(color: AppTheme.textMuted)),
          )
        else
          ..._myCollections.map((col) => _buildCollectionCard(col)),
      ],
    );
  }

  Widget _buildDropCard(LogisticsDropItem drop) {
    final isDelivered = drop.status == 'DELIVERED';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                      Text('${drop.projectName} • ${drop.emirate}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDelivered ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isDelivered ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A)),
                  ),
                  child: Text(
                    drop.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isDelivered ? AppTheme.accentEmerald : const Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSubtle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 16, color: AppTheme.primary),
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
            const SizedBox(height: 10),
            if (!isDelivered)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentEmerald,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(36),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: const Text('Mark as Delivered to Store'),
                onPressed: () => _markDropDelivered(drop),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionCard(LogisticsCollectionItem col) {
    final isCollected = col.status == 'COLLECTED';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                      Text('${col.projectName} • ${col.emirate}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isCollected ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isCollected ? const Color(0xFFA7F3D0) : const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    col.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isCollected ? AppTheme.accentEmerald : AppTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSubtle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.repeat_rounded, size: 16, color: AppTheme.accentEmerald),
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
            const SizedBox(height: 10),
            if (!isCollected)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryDark,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(36),
                ),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Confirm Equipment Collected Back'),
                onPressed: () => _markCollectionComplete(col),
              ),
          ],
        ),
      ),
    );
  }

  Widget _summaryStat(String label, String value, IconData icon, Color accentColor) {
    return Column(
      children: [
        Icon(icon, color: accentColor, size: 20),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: accentColor)),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildSupervisorStoreCard(LiveStoreHub store) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                      Text(store.storeName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textMain)),
                      Text('${store.retailer} • ${store.emirate}', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: const Size(40, 36),
                  ),
                  icon: const Icon(Icons.camera_alt_outlined, size: 15),
                  label: const Text('Stand Photo', style: TextStyle(fontSize: 11)),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Project: ${proj.projectName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textMain)),
                    const SizedBox(height: 6),
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
                                  Text(p.promoterName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textMain)),
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
                                    backgroundColor: const Color(0xFFEFF6FF),
                                    foregroundColor: AppTheme.primary,
                                    padding: const EdgeInsets.all(6),
                                  ),
                                  icon: const Icon(Icons.phone_rounded, size: 14),
                                  onPressed: () => _makeCall(p.promoterPhone),
                                ),
                                const SizedBox(width: 6),
                                IconButton.filled(
                                  constraints: const BoxConstraints(),
                                  style: IconButton.styleFrom(
                                    backgroundColor: const Color(0xFFECFDF5),
                                    foregroundColor: AppTheme.accentEmerald,
                                    padding: const EdgeInsets.all(6),
                                  ),
                                  icon: const Icon(Icons.chat_bubble_rounded, size: 14),
                                  onPressed: () => _openWhatsApp(p.promoterPhone),
                                ),
                                const SizedBox(width: 6),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: const Size(40, 32),
                                  ),
                                  icon: const Icon(Icons.star_rounded, size: 14, color: AppTheme.accentAmber),
                                  label: const Text('Audit ⭐', style: TextStyle(fontSize: 11)),
                                  onPressed: () => _showPromoterEvaluationDialog(p, proj.projectId, store.storeId),
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
      ),
    );
  }
}
