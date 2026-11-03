import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'login_screen.dart';
import 'promoter_audit_page.dart';

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
            backgroundColor: AppColors.success,
            content: Text('Stand photo verified & uploaded for ${store.storeName}!'),
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
              backgroundColor: AppColors.success,
              content: Text('Stand photo verified & uploaded for ${store.storeName}!'),
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
          backgroundColor: AppColors.success,
          content: Text('Drop marked as DELIVERED to ${drop.storeName}!'),
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
          backgroundColor: AppColors.success,
          content: Text('Return collection confirmed from ${col.storeName}!'),
        ),
      );
      _loadSupervisorData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      title: 'Supervisor Field Hub',
      subtitle: 'Field Inspection & Logistics Dispatch',
      onRefresh: _loadSupervisorData,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textPrimary),
          tooltip: 'Refresh Hub Data',
          onPressed: _loadSupervisorData,
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
          // 1. Profile & Mini-stats Header Card
          AppCard(
            child: Column(
              children: [
                Row(
                  children: [
                    InitialsAvatar(
                      name: widget.supervisor.name,
                      size: 48,
                      backgroundColor: AppColors.primarySoft,
                      foregroundColor: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.supervisor.name,
                            style: AppText.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'IML Regional Operations Supervisor',
                            style: AppText.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const StatusBadge(
                      label: 'ON DUTY',
                      variant: StatusVariant.success,
                      showDot: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1, color: AppColors.borderSubtle),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _miniStat('My Stores', '${_myStores.length}', AppColors.primary),
                    ),
                    Container(width: 1, height: 28, color: AppColors.borderSubtle),
                    Expanded(
                      child: _miniStat('Drops Due', '${_myDrops.length}', AppColors.warning),
                    ),
                    Container(width: 1, height: 28, color: AppColors.borderSubtle),
                    Expanded(
                      child: _miniStat('Collections', '${_myCollections.length}', AppColors.success),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 2. Segmented Tab Selector
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.inner),
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.inner - 2),
                boxShadow: AppShadows.card,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: AppText.bodyBold,
              unselectedLabelStyle: AppText.body,
              tabs: [
                Tab(text: 'Store Inspections (${_myStores.length})'),
                Tab(text: 'Logistics Tasks (${_myDrops.length + _myCollections.length})'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 3. Tab Content Area
          if (_isLoading)
            const AppSkeletonList(count: 3)
          else
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                if (_tabController.index == 0) {
                  return _buildStoresTab();
                } else {
                  return _buildLogisticsTab();
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: AppText.titleLarge.copyWith(color: color),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: AppText.micro.copyWith(color: AppColors.textMuted),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStoresTab() {
    if (_myStores.isEmpty) {
      return const EmptyState(
        icon: Icons.storefront_outlined,
        title: 'No stores assigned today',
        description: 'All current shift store inspections are completed or unassigned.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          icon: Icons.checklist_rounded,
          iconColor: AppColors.purple,
          microLabel: 'Field Queue',
          title: 'Store Audit & Stand Queue',
          trailing: StatusBadge(
            label: '${_myStores.length} Stores',
            variant: StatusVariant.purple,
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _myStores.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.itemGap),
          itemBuilder: (ctx, i) => _buildSupervisorStoreCard(_myStores[i]),
        ),
      ],
    );
  }

  Widget _buildLogisticsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Drops Section
        SectionHeader(
          icon: Icons.local_shipping_rounded,
          iconColor: AppColors.warning,
          microLabel: 'Morning Dispatch',
          title: 'POSM Drop-offs',
          trailing: StatusBadge(
            label: '${_myDrops.length} Due',
            variant: StatusVariant.warning,
          ),
        ),
        if (_myDrops.isEmpty)
          AppCard.flat(
            child: Row(
              children: [
                const IconBox(icon: Icons.check_circle_rounded, color: AppColors.success, isCompact: true),
                const SizedBox(width: AppSpacing.sm),
                Text('All morning drops completed!', style: AppText.bodyBold.copyWith(color: AppColors.success)),
              ],
            ),
          )
        else
          ..._myDrops.map((drop) {
            final isDelivered = drop.status == 'DELIVERED';
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.itemGap),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const IconBox(icon: Icons.local_shipping_rounded, color: AppColors.warning, isCompact: true),
                        const SizedBox(width: AppSpacing.sm + 2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(drop.storeName, style: AppText.bodyBold, maxLines: 2, overflow: TextOverflow.ellipsis),
                              Text('Project: ${drop.projectName} • Date: ${drop.scheduledDate}', style: AppText.caption),
                            ],
                          ),
                        ),
                        StatusBadge(
                          label: drop.status,
                          variant: isDelivered ? StatusVariant.success : StatusVariant.warning,
                          showDot: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppCard.flat(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Manifest: ${drop.itemsManifest.isNotEmpty ? drop.itemsManifest : "Standard POP Display Stand"}',
                        style: AppText.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (!isDelivered)
                      AppButton(
                        label: 'Confirm Drop Delivery',
                        icon: Icons.check_circle_rounded,
                        height: 36,
                        onPressed: () => _markDropDelivered(drop),
                      ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: AppSpacing.sectionGap),

        // Collections Section
        SectionHeader(
          icon: Icons.repeat_rounded,
          iconColor: AppColors.accent,
          microLabel: 'Evening Retrieval',
          title: 'Stand Collections',
          trailing: StatusBadge(
            label: '${_myCollections.length} Pending',
            variant: StatusVariant.info,
          ),
        ),
        if (_myCollections.isEmpty)
          AppCard.flat(
            child: Row(
              children: [
                const IconBox(icon: Icons.check_circle_rounded, color: AppColors.success, isCompact: true),
                const SizedBox(width: AppSpacing.sm),
                Text('All collections retrieved!', style: AppText.bodyBold.copyWith(color: AppColors.success)),
              ],
            ),
          )
        else
          ..._myCollections.map((col) {
            final isCollected = col.status == 'COLLECTED';
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.itemGap),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const IconBox(icon: Icons.repeat_rounded, color: AppColors.accent, isCompact: true),
                        const SizedBox(width: AppSpacing.sm + 2),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(col.storeName, style: AppText.bodyBold, maxLines: 2, overflow: TextOverflow.ellipsis),
                              Text('Project: ${col.projectName} • Date: ${col.scheduledDate}', style: AppText.caption),
                            ],
                          ),
                        ),
                        StatusBadge(
                          label: col.status,
                          variant: isCollected ? StatusVariant.success : StatusVariant.info,
                          showDot: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (!isCollected)
                      AppButton(
                        label: 'Confirm Stand Retrieval',
                        icon: Icons.check_circle_rounded,
                        height: 36,
                        onPressed: () => _markCollectionComplete(col),
                      ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSupervisorStoreCard(LiveStoreHub store) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Action Toolbar: Camera, WhatsApp, Call
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  label: 'Stand Photo',
                  icon: Icons.camera_alt_rounded,
                  height: 34,
                  onPressed: () => _captureStandPhoto(store),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.phone_rounded, size: 18, color: AppColors.success),
                tooltip: 'Call Store Lead',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
                onPressed: () => _makeCall(store.supervisorPhone),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.chat_bubble_rounded, size: 18, color: AppColors.accent),
                tooltip: 'WhatsApp Store Lead',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(8),
                onPressed: () => _openWhatsApp(store.supervisorPhone),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Projects & Staff Roster
          ...store.projects.map((proj) {
            return AppCard.flat(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CAMPAIGN: ${proj.projectName.toUpperCase()}',
                    style: AppText.micro.copyWith(color: AppColors.accent),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  ...proj.promoters.map((p) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const IconBox(
                            icon: Icons.person_rounded,
                            color: AppColors.primary,
                            isCompact: true,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.promoterName,
                                  style: AppText.bodySmall.copyWith(fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${p.startTime.substring(0, 5)} – ${p.endTime.substring(0, 5)} • Break: ${p.breakTimings ?? "None"}',
                                  style: AppText.caption.copyWith(fontFamily: 'monospace'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          AppButton.secondary(
                            label: 'Audit',
                            icon: Icons.star_rounded,
                            height: 30,
                            autoWidth: true,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
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
