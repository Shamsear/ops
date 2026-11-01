import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';

class TimeMapCalendarScreen extends StatefulWidget {
  const TimeMapCalendarScreen({super.key});

  @override
  State<TimeMapCalendarScreen> createState() => _TimeMapCalendarScreenState();
}

class _TimeMapCalendarScreenState extends State<TimeMapCalendarScreen> with SingleTickerProviderStateMixin {
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
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.dispose();
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
              backgroundColor: AppTheme.primaryDark,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export link: ${ApiService.excelExportUrl}'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Master TimeMap™ Calendar',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textMain, letterSpacing: -0.2),
            ),
            Text(
              'Multi-Store Roster, Coverage & Matrix Grid',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accent,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: AppTheme.primaryDark,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.view_day_rounded, size: 18), text: 'Today Timeline'),
            Tab(icon: Icon(Icons.grid_view_rounded, size: 18), text: 'TimeMap Grid'),
            Tab(icon: Icon(Icons.table_view_rounded, size: 18), text: 'Export & Reports'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: AppTheme.success),
            tooltip: 'Export to Excel (.xlsx)',
            onPressed: _exportExcel,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            tooltip: 'Refresh Matrix',
            onPressed: _loadAllData,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDailyTimeline(),
                _buildMatrixGrid(),
                _buildReportsView(),
              ],
            ),
    );
  }

  Widget _buildDailyTimeline() {
    if (_schedules.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceSubtle,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.calendar_today_rounded, size: 36, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Store Coverage Today',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textMain),
              ),
              const SizedBox(height: 6),
              const Text(
                'Use the TimeMap Grid or Batch Scheduler to plan shifts.',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Shift Coverage Breakdown",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textMain),
            ),
            StatusBadge(
              label: '${_schedules.length} Stores Active',
              variant: StatusVariant.success,
              fontSize: 10,
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._schedules.map((storeHub) {
          final store = storeHub as LiveStoreHub;
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
                      child: Text(
                        store.storeName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textMain, letterSpacing: -0.2),
                      ),
                    ),
                    StatusBadge(
                      label: store.emirate,
                      variant: StatusVariant.neutral,
                      fontSize: 10,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${store.retailer} • Branch #${store.branchCode ?? "2100"}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                const Divider(color: AppTheme.borderSubtle, height: 1),
                const SizedBox(height: 10),
                ...store.projects.map((proj) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'Campaign: ${proj.projectName.toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.accent, fontSize: 11, letterSpacing: 0.3),
                        ),
                      ),
                      ...proj.promoters.map((p) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceSubtle,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: AppTheme.infoBg,
                                child: const Icon(Icons.person, size: 14, color: AppTheme.accent),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.promoterName,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.textMain),
                                    ),
                                    Text(
                                      '${p.startTime.substring(0, 5)} – ${p.endTime.substring(0, 5)} • Break: ${p.breakTimings ?? "None"}',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge.fromStatus('ON DUTY'),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMatrixGrid() {
    final filteredStores = _matrixStores.where((s) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = s.storeName.toLowerCase().contains(q);
        final matchCode = (s.customerCode ?? '').toLowerCase().contains(q);
        if (!matchName && !matchCode) return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Filter Controls Bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
          ),
          child: Column(
            children: [
              // Search input
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMain),
                decoration: InputDecoration(
                  hintText: 'Filter stores or customer code...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.accent),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                  filled: true,
                  fillColor: AppTheme.surfaceSubtle,
                ),
              ),
              const SizedBox(height: 8),
              // Filter selectors
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedEmirate,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMain),
                          items: _emirates.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedEmirate = val);
                              _loadMatrixData().then((_) => setState(() {}));
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedChain,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMain),
                          items: _chains.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedChain = val);
                              _loadMatrixData().then((_) => setState(() {}));
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _exportExcel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.download_rounded, size: 15),
                    label: const Text('Excel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Count Summary Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppTheme.surfaceSubtle,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${filteredStores.length} Stores • ${_matrixDates.length} Dates',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted),
              ),
              Row(
                children: [
                  _legendDot(AppTheme.success, 'Approved'),
                  const SizedBox(width: 8),
                  _legendDot(AppTheme.warning, 'HR/Security'),
                  const SizedBox(width: 8),
                  _legendDot(AppTheme.danger, 'Rejected'),
                ],
              ),
            ],
          ),
        ),

        // Scrollable Matrix Table
        Expanded(
          child: filteredStores.isEmpty
              ? const Center(
                  child: Text(
                    'No stores found for selected filters.',
                    style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(AppTheme.surfaceSubtle),
                      headingTextStyle: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textMain, fontSize: 11),
                      dataTextStyle: const TextStyle(fontSize: 11, color: AppTheme.textMain),
                      columnSpacing: 12,
                      horizontalMargin: 12,
                      border: TableBorder.all(color: AppTheme.borderSubtle, width: 0.8),
                      columns: [
                        const DataColumn(label: Text('#')),
                        const DataColumn(label: Text('Code')),
                        const DataColumn(label: Text('Store Name')),
                        const DataColumn(label: Text('Chain')),
                        const DataColumn(label: Text('Emirate')),
                        const DataColumn(label: Text('Lead')),
                        ..._matrixDates.map((d) {
                          DateTime? dt;
                          try {
                            dt = DateTime.parse(d);
                          } catch (_) {}
                          final dayStr = dt != null ? DateFormat('d MMM').format(dt) : d;
                          final weekDayStr = dt != null ? DateFormat('E').format(dt) : '';
                          return DataColumn(
                            label: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(dayStr, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                                Text(weekDayStr, style: const TextStyle(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          );
                        }),
                      ],
                      rows: filteredStores.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final store = entry.value;

                        return DataRow(
                          cells: [
                            DataCell(Text('${idx + 1}', style: const TextStyle(fontFamily: 'monospace', color: AppTheme.textMuted))),
                            DataCell(Text(store.customerCode ?? '—', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700))),
                            DataCell(
                              SizedBox(
                                width: 160,
                                child: Text(
                                  store.storeName,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(Text(store.chain ?? store.retailer)),
                            DataCell(Text(store.emirate)),
                            DataCell(Text(store.merchandiserLead ?? 'Supervisor Babar', style: const TextStyle(fontSize: 10))),
                            ..._matrixDates.map((d) {
                              final key = '${store.id}_$d';
                              final shifts = _shiftLookup[key] ?? [];

                              if (shifts.isEmpty) {
                                return const DataCell(Center(child: Text('—', style: TextStyle(color: AppTheme.textLight))));
                              }

                              return DataCell(
                                InkWell(
                                  onTap: () => _showShiftDetailSheet(store, d, shifts),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: shifts.map((s) {
                                      final pName = s['promoter_name'] ?? s['staff_role'] ?? 'Staff';
                                      final badgeStatus = s['badge_status'] as String?;
                                      return _staffChip(pName.toString(), badgeStatus);
                                    }).toList(),
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _staffChip(String name, String? badgeStatus) {
    Color badgeColor = AppTheme.textLight;
    if (badgeStatus == 'Approved') {
      badgeColor = AppTheme.success;
    } else if (badgeStatus == 'Pending with HR' || badgeStatus == 'Pending with security') {
      badgeColor = AppTheme.warning;
    } else if (badgeStatus == 'Submitted') {
      badgeColor = AppTheme.accent;
    } else if (badgeStatus == 'Rejected') {
      badgeColor = AppTheme.danger;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              name,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMain),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.w700)),
      ],
    );
  }

  void _showShiftDetailSheet(StoreModel store, String date, List<dynamic> shifts) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusExtraLarge))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppTheme.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(store.storeName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textMain)),
            Text('${store.retailer} • ${store.emirate} • Shift Date: $date', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            const SizedBox(height: 16),
            const Text('Assigned Shifts:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textMain)),
            const SizedBox(height: 10),
            ...shifts.map((s) {
              final pName = s['promoter_name'] ?? s['staff_role'] ?? 'Staff';
              final badgeStatus = s['badge_status'] ?? 'No Badge Linked';
              final startTime = s['start_time'] != null ? s['start_time'].toString().substring(0, 5) : '14:00';
              final endTime = s['end_time'] != null ? s['end_time'].toString().substring(0, 5) : '22:00';
              final breakInfo = s['break_timings'] != null && s['break_timings'].toString().isNotEmpty
                  ? 'Break: ${s['break_timings']}'
                  : 'Standard Break';
              final role = s['staff_role'] != null && s['staff_role'] != 'PROMOTER' ? ' • ${s['staff_role']}' : '';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppTheme.infoBg,
                      child: const Icon(Icons.person, color: AppTheme.accent, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$pName$role', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textMain)),
                          Text('Shift: $startTime - $endTime • $breakInfo', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                    StatusBadge.fromStatus(badgeStatus.toString()),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const Text(
          'Operational Excel Exporter & Sync',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textMain, letterSpacing: -0.2),
        ),
        const SizedBox(height: 4),
        const Text(
          'Download full campaign roster spreadsheets compatible with client reporting guidelines.',
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 16),

        // Big Excel Download Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusExtraLarge),
            border: Border.all(color: AppTheme.borderSubtle, width: 1.1),
            boxShadow: AppTheme.elevatedShadow,
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.successBorder),
                    ),
                    child: const Icon(Icons.table_chart_rounded, color: AppTheme.success, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Master TimeMap Roster (.xlsx)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textMain)),
                        Text('${_matrixStores.length} Stores • ${_matrixDates.length} Dates • Live Staff & Badges', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Includes customer codes, retail chains, cities, merchandiser leads, full date matrices, and badge clearance status tags.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _exportExcel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.download_rounded, size: 19),
                  label: const Text('Export Client-Ready Excel', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const Text('Active Campaign Metrics', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textMain)),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(child: _metricCard('Total Stores', '${_matrixStores.length}', Icons.storefront_rounded, AppTheme.accentTeal)),
            const SizedBox(width: 10),
            Expanded(child: _metricCard('Active Shifts', '${_matrixShifts.length}', Icons.schedule_rounded, AppTheme.accent)),
            const SizedBox(width: 10),
            Expanded(child: _metricCard('Active Days', '${_matrixDates.length}', Icons.calendar_today_rounded, AppTheme.purple)),
          ],
        ),
      ],
    );
  }

  Widget _metricCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borderSubtle, width: 1.1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19, fontFamily: 'monospace', color: AppTheme.textMain)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
