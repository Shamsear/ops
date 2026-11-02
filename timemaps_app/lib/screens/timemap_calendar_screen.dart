import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class TimeMapCalendarScreen extends StatefulWidget {
  final bool isEmbedded;
  const TimeMapCalendarScreen({super.key, this.isEmbedded = false});

  @override
  State<TimeMapCalendarScreen> createState() => _TimeMapCalendarScreenState();
}

class _TimeMapCalendarScreenState extends State<TimeMapCalendarScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _schedules = [];

  // Dynamic Master Matrix Data
  List<StoreModel> _matrixStores = [];
  List<dynamic> _matrixShifts = [];
  List<String> _matrixDates = [];
  final Map<String, List<dynamic>> _shiftLookup = {};

  String _selectedEmirate = 'All';
  String _selectedChain = 'All';

  final List<String> _emirates = ['All', 'Dubai', 'Abu Dhabi', 'Sharjah', 'Ajman', 'Al Ain', 'Ras Al Khaimah', 'Fujairah'];
  final List<String> _chains = ['All', 'Lulu', 'Union Coop', 'Carrefour', 'MAIR GROUP', 'MARK AND SAVE'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadTimelineData(),
      _loadMatrixData(),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTimelineData() async {
    try {
      final res = await ApiService.getLiveDashboard();
      _schedules = (res['live_stores'] as List<LiveStoreHub>?) ?? [];
    } catch (e) {
      debugPrint('Error loading timeline: $e');
    }
  }

  Future<void> _loadMatrixData() async {
    try {
      final data = await ApiService.getMatrix(
        emirate: _selectedEmirate == 'All' ? null : _selectedEmirate,
        chain: _selectedChain == 'All' ? null : _selectedChain,
      );

      final rawStores = (data['stores'] as List<dynamic>?) ?? [];
      final rawShifts = (data['shifts'] as List<dynamic>?) ?? [];

      _matrixStores = rawStores.map((s) => StoreModel.fromJson(s as Map<String, dynamic>)).toList();
      _matrixShifts = rawShifts;

      // Extract unique sorted dates
      final dateSet = <String>{};
      _shiftLookup.clear();

      for (final s in _matrixShifts) {
        final shiftDateRaw = s['shift_date'];
        if (shiftDateRaw == null) continue;
        final dStr = DateTime.parse(shiftDateRaw.toString()).toIso8601String().split('T')[0];
        dateSet.add(dStr);

        final key = '${s['store_id']}_$dStr';
        _shiftLookup.putIfAbsent(key, () => []).add(s);
      }

      _matrixDates = dateSet.toList()..sort();
    } catch (e) {
      debugPrint('Error loading matrix: $e');
    }
  }

  Future<void> _exportExcel() async {
    final url = Uri.parse(ApiService.excelExportUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloading Excel: ${ApiService.excelExportUrl}'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return AppScreenScaffold(
      title: 'Schedule & Matrix Calendar',
      subtitle: 'National Timeline & Shift Matrix',
      leading: widget.isEmbedded ? null : const BackButton(color: AppColors.textPrimary),
      bottomClearance: widget.isEmbedded,
      onRefresh: _loadAllData,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textPrimary),
          tooltip: 'Refresh Matrix Data',
          onPressed: _loadAllData,
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Segmented Tab Selector
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
              tabs: const [
                Tab(text: 'Store Timeline'),
                Tab(text: 'Matrix Grid'),
                Tab(text: 'Excel Export'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Tab Content
          if (_isLoading)
            const AppSkeletonList(count: 4)
          else
            AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                switch (_tabController.index) {
                  case 0:
                    return _buildTimelineView();
                  case 1:
                    return _buildMatrixView();
                  case 2:
                  default:
                    return _buildExcelExportView();
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineView() {
    if (_schedules.isEmpty) {
      return const EmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'No shifts scheduled',
        description: 'No store shifts are scheduled for today.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          icon: Icons.view_timeline_rounded,
          iconColor: AppColors.primary,
          microLabel: 'Active Shift Queue',
          title: 'Store Deployment Timeline',
          trailing: StatusBadge(
            label: '${_schedules.length} Stores',
            variant: StatusVariant.info,
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _schedules.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.itemGap),
          itemBuilder: (ctx, idx) {
            final store = _schedules[idx] as LiveStoreHub;

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
                            Text(
                              '${store.retailer} • ${store.emirate}',
                              style: AppText.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                  ...store.projects.map((proj) {
                    return AppCard.flat(
                      padding: const EdgeInsets.all(10),
                      child: Column(
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
                                  proj.projectName.toUpperCase(),
                                  style: AppText.micro.copyWith(color: AppColors.accent),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              StatusBadge(
                                label: '${proj.promoters.length} Staff',
                                variant: StatusVariant.neutral,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ...proj.promoters.map((p) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textMuted),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      p.promoterName,
                                      style: AppText.body.copyWith(fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${p.startTime.substring(0, 5)} – ${p.endTime.substring(0, 5)}',
                                    style: AppText.caption.copyWith(fontFamily: 'monospace'),
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
          },
        ),
      ],
    );
  }

  Widget _buildMatrixView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter Controls
        AppCard.compact(
          child: Column(
            children: [
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _chains.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (ctx, i) {
                    final chain = _chains[i];
                    return FilterPill(
                      label: chain,
                      isSelected: _selectedChain == chain,
                      onTap: () {
                        setState(() => _selectedChain = chain);
                        _loadMatrixData();
                      },
                    );
                  },
                ),
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
                      onTap: () {
                        setState(() => _selectedEmirate = em);
                        _loadMatrixData();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Matrix Grid Card
        AppCard(
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.surfaceMuted),
              columnSpacing: 18,
              horizontalMargin: 16,
              columns: [
                const DataColumn(
                  label: Text('STORE VENUE', style: AppText.micro),
                ),
                ..._matrixDates.map(
                  (d) => DataColumn(
                    label: Text(
                      d.substring(5),
                      style: AppText.micro,
                    ),
                  ),
                ),
              ],
              rows: _matrixStores.map((store) {
                return DataRow(
                  cells: [
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          store.storeName,
                          style: AppText.bodyBold.copyWith(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    ..._matrixDates.map((dateStr) {
                      final key = '${store.id}_$dateStr';
                      final shifts = _shiftLookup[key] ?? [];
                      if (shifts.isEmpty) {
                        return const DataCell(Text('—', style: AppText.caption));
                      }
                      return DataCell(
                        StatusBadge(
                          label: '${shifts.length} Shift',
                          variant: StatusVariant.success,
                          fontSize: 9.5,
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExcelExportView() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBox(
                icon: Icons.table_chart_rounded,
                color: AppColors.success,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Master Operations Roster (.xlsx)', style: AppText.title),
                    const SizedBox(height: 2),
                    Text(
                      '${_matrixStores.length} Stores • ${_matrixDates.length} Dates • Active Staff & Permits',
                      style: AppText.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Generates a comprehensive live schedule workbook formatted with store locations, chains, promoter shifts, assigned supervisors, and security permit clearance stages.',
            style: AppText.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Download Excel Workbook',
            icon: Icons.file_download_outlined,
            onPressed: _exportExcel,
          ),
        ],
      ),
    );
  }
}
