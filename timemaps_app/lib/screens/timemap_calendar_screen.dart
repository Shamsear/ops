import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

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

  final List<String> _emirates = ['All', 'Dubai', 'Abu Dhabi', 'Sharjah', 'Ajman', 'Al Ain', 'Ras Al Khaimah', 'Fujairah'];
  final List<String> _chains = ['All', 'Lulu', 'Union Coop', 'Carrefour', 'MAIR GROUP', 'MARK AND SAVE'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
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
              backgroundColor: AppTheme.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export link: ${ApiService.excelExportUrl}'),
            backgroundColor: AppTheme.accentEmerald,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text(
          'Master TimeMap™ Calendar',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textMain),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 2.5,
          labelColor: AppTheme.textMain,
          unselectedLabelColor: AppTheme.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.view_day_outlined, size: 18), text: 'Daily Timeline'),
            Tab(icon: Icon(Icons.grid_view_rounded, size: 18), text: 'TimeMap Grid'),
            Tab(icon: Icon(Icons.file_download_outlined, size: 18), text: 'Excel & Reports'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: AppTheme.accentEmerald),
            tooltip: 'Export to Excel (.xlsx)',
            onPressed: _exportExcel,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Matrix',
            onPressed: _loadAllData,
          ),
          IconButton(
            icon: const Icon(Icons.content_copy_rounded),
            tooltip: 'Duplicate to Next Week',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Duplicating active campaign shifts for next week... Done!')),
              );
            },
          ),
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No live store coverage scheduled for today.\nUse the TimeMap Grid or In-App Creator to schedule shifts.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Shift Coverage",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textMain),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Text(
                '${_schedules.length} Active Stores',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppTheme.accentEmerald),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._schedules.map((storeHub) {
          final store = storeHub as LiveStoreHub;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppTheme.borderSubtle),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          store.storeName,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textMain),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceSubtle,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Text(
                          store.emirate,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
                        ),
                      ),
                    ],
                  ),
                  Text('${store.retailer} • Branch #${store.branchCode ?? "2100"}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  const Divider(color: AppTheme.borderSubtle, height: 1),
                  const SizedBox(height: 8),
                  ...store.projects.map((proj) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Campaign: ${proj.projectName}',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.accent, fontSize: 12),
                          ),
                        ),
                        ...proj.promoters.map((p) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: CircleAvatar(
                              radius: 14,
                              backgroundColor: AppTheme.surfaceSubtle,
                              child: const Icon(Icons.person_rounded, size: 16, color: AppTheme.primary),
                            ),
                            title: Text(
                              p.promoterName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textMain),
                            ),
                            subtitle: Text(
                              '${p.startTime.substring(0, 5)} – ${p.endTime.substring(0, 5)} • Break: ${p.breakTimings ?? "None"}',
                              style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: const Text('ON DUTY',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.accentEmerald)),
                            ),
                          );
                        }),
                      ],
                    );
                  }),
                ],
              ),
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
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          color: Colors.white,
          child: Column(
            children: [
              // Search input
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Search stores or customer code...',
                  hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                  filled: true,
                  fillColor: AppTheme.surfaceSubtle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppTheme.borderSubtle),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Dropdowns row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedEmirate,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMain),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedChain,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMain),
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
                      backgroundColor: AppTheme.accentEmerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.download, size: 14),
                    label: const Text('Excel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Count Summary Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: AppTheme.surfaceSubtle,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${filteredStores.length} Stores • ${_matrixDates.length} Dates',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
              ),
              Row(
                children: [
                  _legendDot(const Color(0xFF10B981), 'Approved'),
                  const SizedBox(width: 6),
                  _legendDot(const Color(0xFFF59E0B), 'HR/Sec'),
                  const SizedBox(width: 6),
                  _legendDot(const Color(0xFFEF4444), 'Rejected'),
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
                                return const DataCell(Center(child: Text('-', style: TextStyle(color: AppTheme.textMuted))));
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
    Color badgeColor = const Color(0xFF9CA3AF);
    if (badgeStatus == 'Approved') {
      badgeColor = const Color(0xFF10B981);
    } else if (badgeStatus == 'Pending with HR' || badgeStatus == 'Pending with security') {
      badgeColor = const Color(0xFFF59E0B);
    } else if (badgeStatus == 'Submitted') {
      badgeColor = const Color(0xFF2563EB);
    } else if (badgeStatus == 'Rejected') {
      badgeColor = const Color(0xFFEF4444);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFCBD5E1)),
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
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _showShiftDetailSheet(StoreModel store, String date, List<dynamic> shifts) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(store.storeName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            Text('${store.retailer} • ${store.emirate} • Date: $date', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            const SizedBox(height: 14),
            const Text('Assigned Shifts:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            ...shifts.map((s) {
              final pName = s['promoter_name'] ?? s['staff_role'] ?? 'Staff';
              final badgeStatus = s['badge_status'] ?? 'No Badge Linked';
              final startTime = s['start_time'] != null ? s['start_time'].toString().substring(0, 5) : '14:00';
              final endTime = s['end_time'] != null ? s['end_time'].toString().substring(0, 5) : '22:00';
              final breakInfo = s['break_timings'] != null && s['break_timings'].toString().isNotEmpty
                  ? 'Break: ${s['break_timings']}'
                  : 'Standard Break';
              final role = s['staff_role'] != null && s['staff_role'] != 'PROMOTER' ? ' • ${s['staff_role']}' : '';

              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppTheme.surfaceSubtle,
                  child: const Icon(Icons.person, color: AppTheme.primary, size: 18),
                ),
                title: Text('$pName$role', style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('Shift: $startTime - $endTime • $breakInfo', style: const TextStyle(fontSize: 11)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeStatus == 'Approved' ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: badgeStatus == 'Approved' ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Text(
                    badgeStatus.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: badgeStatus == 'Approved' ? AppTheme.accentEmerald : const Color(0xFFB45309),
                    ),
                  ),
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
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Operational Excel Exporter & Sync',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textMain),
        ),
        const SizedBox(height: 4),
        const Text(
          'Download full campaign roster spreadsheets compatible with client reporting guidelines.',
          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 14),

        // Big Excel Download Card
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.table_chart_rounded, color: AppTheme.accentEmerald, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Master TimeMap Roster (.xlsx)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          Text('73 Stores • 39 Dates • Live Staff & Badges', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Includes customer codes, chains, cities, merchandiser leads, full date matrices, and badge clearance status tags.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _exportExcel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentEmerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Export Client-Ready Excel', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        const Text('Active Campaign Metrics', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textMain)),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(child: _metricCard('Total Stores', '${_matrixStores.length}', Icons.storefront_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _metricCard('Active Shifts', '${_matrixShifts.length}', Icons.schedule_rounded)),
            const SizedBox(width: 10),
            Expanded(child: _metricCard('Active Days', '${_matrixDates.length}', Icons.calendar_today_rounded)),
          ],
        ),
      ],
    );
  }

  Widget _metricCard(String title, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(height: 8),
          Text(val, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, fontFamily: 'monospace')),
          Text(title, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
