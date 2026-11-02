import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/liquid_glass.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/searchable_select_field.dart';
import '../widgets/status_badge.dart';

class CreateSchedulePage extends StatefulWidget {
  final int? preselectedStoreId;
  final int? preselectedProjectId;

  const CreateSchedulePage({
    super.key,
    this.preselectedStoreId,
    this.preselectedProjectId,
  });

  @override
  State<CreateSchedulePage> createState() => _CreateSchedulePageState();
}

class _CreateSchedulePageState extends State<CreateSchedulePage> {
  List<ProjectModel> _projects = [];
  List<StoreModel> _stores = [];
  List<PromoterModel> _promoters = [];

  ProjectModel? _selectedProject;
  StoreModel? _selectedStore;
  PromoterModel? _selectedPromoter;
  final String _staffRole = 'PROMOTER';
  bool _isLoading = true;
  bool _isSaving = false;

  TimeOfDay _startTime = const TimeOfDay(hour: 14, minute: 0); // 2:00 PM
  TimeOfDay _endTime = const TimeOfDay(hour: 22, minute: 0);   // 10:00 PM
  final _breakTimingsController = TextEditingController(text: '5:00 PM - 5:45 PM');
  final _notesController = TextEditingController();

  // Multi-date selection (Set of YYYY-MM-DD strings)
  final Set<String> _selectedDates = {};
  DateTime _currentCalendarMonth = DateTime(2026, 10, 1);
  String _selectedShiftPreset = 'Evening Shift (14:00 - 22:00)';

  @override
  void initState() {
    super.initState();
    // Default demo selection
    _selectedDates.addAll(['2026-10-15', '2026-10-16', '2026-10-17', '2026-10-18']);
    _loadFormData();
  }

  @override
  void dispose() {
    _breakTimingsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    setState(() => _isLoading = true);
    final projects = await ApiService.getProjects();
    final stores = await ApiService.getStores();
    final promoters = await ApiService.getPromoters();

    if (mounted) {
      setState(() {
        _projects = projects;
        _stores = stores;
        _promoters = promoters;

        if (widget.preselectedProjectId != null) {
          _selectedProject = _projects.where((p) => p.id == widget.preselectedProjectId).firstOrNull;
        }
        _selectedProject ??= _projects.isNotEmpty ? _projects.first : null;

        if (widget.preselectedStoreId != null) {
          _selectedStore = _stores.where((s) => s.id == widget.preselectedStoreId).firstOrNull;
        }
        _selectedStore ??= _stores.isNotEmpty ? _stores.first : null;

        _isLoading = false;
      });
    }
  }

  void _applyShiftPreset(String preset) {
    setState(() {
      _selectedShiftPreset = preset;
      if (preset == 'Morning Shift (10:00 - 18:00)') {
        _startTime = const TimeOfDay(hour: 10, minute: 0);
        _endTime = const TimeOfDay(hour: 18, minute: 0);
        _breakTimingsController.text = '1:30 PM - 2:15 PM';
      } else if (preset == 'Evening Shift (14:00 - 22:00)') {
        _startTime = const TimeOfDay(hour: 14, minute: 0);
        _endTime = const TimeOfDay(hour: 22, minute: 0);
        _breakTimingsController.text = '5:00 PM - 5:45 PM';
      } else if (preset == 'Full Day / Split (10:00 - 22:00)') {
        _startTime = const TimeOfDay(hour: 10, minute: 0);
        _endTime = const TimeOfDay(hour: 22, minute: 0);
        _breakTimingsController.text = '2:00 PM - 3:00 PM (Lunch) & 6:00 PM - 6:30 PM';
      } else if (preset == 'Weekend Split Shift') {
        _startTime = const TimeOfDay(hour: 11, minute: 0);
        _endTime = const TimeOfDay(hour: 21, minute: 0);
        _breakTimingsController.text = '3:00 PM - 4:00 PM (Prayer/Lunch)';
      }
    });
  }

  double _calculateTotalHours() {
    final startMin = _startTime.hour * 60 + _startTime.minute;
    final endMin = _endTime.hour * 60 + _endTime.minute;
    double diff = (endMin - startMin) / 60.0;
    if (diff <= 0) diff += 24.0;
    return double.parse(diff.toStringAsFixed(1));
  }

  void _toggleDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    setState(() {
      if (_selectedDates.contains(dateStr)) {
        _selectedDates.remove(dateStr);
      } else {
        _selectedDates.add(dateStr);
      }
    });
  }

  void _selectWeekendDays() {
    final daysInMonth = DateTime(_currentCalendarMonth.year, _currentCalendarMonth.month + 1, 0).day;
    setState(() {
      for (int d = 1; d <= daysInMonth; d++) {
        final date = DateTime(_currentCalendarMonth.year, _currentCalendarMonth.month, d);
        // Thu (4), Fri (5), Sat (6), Sun (7) are UAE retail promotional peak days
        if (date.weekday == DateTime.thursday ||
            date.weekday == DateTime.friday ||
            date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday) {
          _selectedDates.add(DateFormat('yyyy-MM-dd').format(date));
        }
      }
    });
  }

  void _selectAllMonthDays() {
    final daysInMonth = DateTime(_currentCalendarMonth.year, _currentCalendarMonth.month + 1, 0).day;
    setState(() {
      for (int d = 1; d <= daysInMonth; d++) {
        final date = DateTime(_currentCalendarMonth.year, _currentCalendarMonth.month, d);
        _selectedDates.add(DateFormat('yyyy-MM-dd').format(date));
      }
    });
  }

  Future<void> _handleBatchSave() async {
    if (_selectedProject == null) {
      _showWarningSnackBar('Please select a Campaign Project');
      return;
    }
    if (_selectedStore == null) {
      _showWarningSnackBar('Please select Store Location');
      return;
    }
    if (_selectedDates.isEmpty) {
      _showWarningSnackBar('Please select at least 1 shift date on the calendar matrix');
      return;
    }

    setState(() => _isSaving = true);

    final startStr = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}:00';
    final endStr = '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}:00';

    final createdCount = await ApiService.createBatchSchedules(
      projectId: _selectedProject!.id,
      storeIds: [_selectedStore!.id],
      dates: _selectedDates.toList()..sort(),
      promoterId: _selectedPromoter?.id,
      startTime: startStr,
      endTime: endStr,
      breakTimings: _breakTimingsController.text.trim().isEmpty ? null : _breakTimingsController.text.trim(),
      totalHours: _calculateTotalHours(),
      staffRole: _staffRole,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (createdCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Successfully scheduled $createdCount shifts for ${_selectedStore!.storeName}!',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
      Navigator.pop(context, true);
    } else {
      _showWarningSnackBar('Failed to save shifts. Please check parameters and try again.');
    }
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalHoursPerShift = _calculateTotalHours();
    final cumulativeHours = (totalHoursPerShift * _selectedDates.length).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      extendBody: true,
      appBar: AppBar(
        titleSpacing: 0,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Batch Shift Scheduler',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMain,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '${_selectedDates.length} shifts selected • $cumulativeHours total hrs',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: StatusBadge(
              label: '${_selectedDates.length} Shifts',
              variant: _selectedDates.isNotEmpty ? StatusVariant.info : StatusVariant.neutral,
              showDot: _selectedDates.isNotEmpty,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: LiquidGlassContainer(
            radius: 22.0,
            blur: 24.0,
            opacity: 0.85,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_selectedDates.length}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primary,
                              ),
                            ),
                            const Text(
                              ' shifts • ',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
                            ),
                            Text(
                              '${cumulativeHours}h total',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _selectedStore != null ? _selectedStore!.storeName : 'Select store & dates',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  onPressed: _isSaving ? null : _handleBatchSave,
                  icon: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.event_available_rounded, size: 18),
                  label: Text(
                    _isSaving ? 'Scheduling...' : 'Confirm Shifts (${_selectedDates.length})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Modern Guide Banner
                    _buildGuideBanner(),
                    const SizedBox(height: 16),

                    // Section 1: Campaign & Store Assignment
                    _buildVenueCard(),
                    const SizedBox(height: 16),

                    // Section 2: Shift Date Matrix (Calendar)
                    _buildCalendarMatrixCard(),
                    const SizedBox(height: 16),

                    // Section 3: Shift Timings & Break Rotation
                    _buildTimingsCard(totalHoursPerShift),
                    const SizedBox(height: 16),

                    // Section 4: Brief & Special Instructions
                    _buildBriefCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGuideBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.infoBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.infoBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Multi-Date Batch Generator',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMain,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Select venue and tap one or more dates. All ${_selectedDates.length} shifts will be created simultaneously in Supabase with synced break rotations.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.store_mall_directory_rounded, size: 18, color: AppTheme.primary),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VENUE & STAFF ASSIGNMENT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      'Where and who will execute this shift',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Campaign Project Selector
            SearchableSelectField<ProjectModel>(
              label: 'Campaign Roadshow *',
              value: _selectedProject,
              options: _projects.map((p) => SearchableOption<ProjectModel>(
                value: p,
                label: p.name,
                subtitle: p.clientName.isNotEmpty ? p.clientName : 'Direct Client',
              )).toList(),
              prefixIcon: const Icon(Icons.campaign_outlined, size: 20),
              onChanged: (p) => setState(() => _selectedProject = p),
            ),
            const SizedBox(height: 12),

            // Store Location Selector
            SearchableSelectField<StoreModel>(
              label: 'Store Location *',
              value: _selectedStore,
              options: _stores.map((s) => SearchableOption<StoreModel>(
                value: s,
                label: s.storeName,
                subtitle: '${s.retailer} • ${s.emirate} • Code: ${s.customerCode ?? 'N/A'}',
              )).toList(),
              prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
              onChanged: (s) => setState(() => _selectedStore = s),
            ),

            if (_selectedStore != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _selectedStore!.retailer,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_selectedStore!.emirate} • SMN: ${_selectedStore!.smnContact ?? 'Operations Desk'}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Assigned Promoter Selector
            SearchableSelectField<PromoterModel?>(
              label: 'Assigned Promoter (Optional)',
              value: _selectedPromoter,
              options: [
                const SearchableOption<PromoterModel?>(
                  value: null,
                  label: 'Open Shift (Unassigned Staff)',
                  subtitle: 'Leave open for on-demand supervisor dispatch',
                ),
                ..._promoters.map((p) => SearchableOption<PromoterModel?>(
                  value: p,
                  label: p.name,
                  subtitle: '${p.phone}${p.nationality != null ? ' • ${p.nationality}' : ''}',
                )),
              ],
              prefixIcon: const Icon(Icons.person_pin_circle_outlined, size: 20),
              onChanged: (p) => setState(() => _selectedPromoter = p),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarMatrixCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calendar_month_rounded, size: 18, color: AppTheme.accent),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SHIFT DATES MATRIX',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMuted,
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          'Tap dates to toggle shift days',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                StatusBadge(
                  label: '${_selectedDates.length} Days Active',
                  variant: _selectedDates.isNotEmpty ? StatusVariant.success : StatusVariant.neutral,
                  showDot: _selectedDates.isNotEmpty,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Month navigation bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 22, color: AppTheme.textMain),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () {
                      setState(() {
                        _currentCalendarMonth = DateTime(
                          _currentCalendarMonth.year,
                          _currentCalendarMonth.month - 1,
                        );
                      });
                    },
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(_currentCalendarMonth),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMain,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 22, color: AppTheme.textMain),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    onPressed: () {
                      setState(() {
                        _currentCalendarMonth = DateTime(
                          _currentCalendarMonth.year,
                          _currentCalendarMonth.month + 1,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Day of week headers
            Row(
              children: [
                _buildWeekdayHeader('Mon'),
                _buildWeekdayHeader('Tue'),
                _buildWeekdayHeader('Wed'),
                _buildWeekdayHeader('Thu', isPeak: true),
                _buildWeekdayHeader('Fri', isPeak: true),
                _buildWeekdayHeader('Sat', isPeak: true),
                _buildWeekdayHeader('Sun', isPeak: true),
              ],
            ),
            const SizedBox(height: 8),

            // Grid of days
            _buildResponsiveCalendarGrid(),
            const SizedBox(height: 14),

            // Quick Select Actions
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _selectWeekendDays,
                  icon: const Icon(Icons.bolt_rounded, size: 15, color: AppTheme.accent),
                  label: const Text(
                    'Peak Retail (Thu–Sun)',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _selectAllMonthDays,
                  icon: const Icon(Icons.calendar_view_month_rounded, size: 15),
                  label: const Text(
                    'All Days This Month',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(0, 36),
                    side: BorderSide(color: AppTheme.danger.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => setState(() => _selectedDates.clear()),
                  icon: const Icon(Icons.close_rounded, size: 15, color: AppTheme.danger),
                  label: const Text(
                    'Clear',
                    style: TextStyle(fontSize: 11, color: AppTheme.danger, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayHeader(String label, {bool isPeak = false}) {
    return Expanded(
      child: Center(
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isPeak ? FontWeight.w800 : FontWeight.w600,
                color: isPeak ? AppTheme.accent : AppTheme.textMuted,
              ),
            ),
            if (isPeak)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentCalendarMonth.year, _currentCalendarMonth.month, 1);
    final daysInMonth = DateTime(_currentCalendarMonth.year, _currentCalendarMonth.month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun

    final totalCells = ((startingWeekday - 1) + daysInMonth <= 35) ? 35 : 42;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.05,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final dayOffset = index - (startingWeekday - 1);
        if (dayOffset < 0 || dayOffset >= daysInMonth) {
          return const SizedBox.shrink();
        }

        final day = dayOffset + 1;
        final date = DateTime(_currentCalendarMonth.year, _currentCalendarMonth.month, day);
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final isSelected = _selectedDates.contains(dateStr);
        final isWeekend = date.weekday == DateTime.thursday ||
            date.weekday == DateTime.friday ||
            date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday;

        return InkWell(
          onTap: () => _toggleDate(date),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primary
                  : (isWeekend ? AppTheme.surfaceSubtle : Colors.white),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppTheme.primary : AppTheme.borderSubtle,
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.28),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w900 : (isWeekend ? FontWeight.w700 : FontWeight.w500),
                  color: isSelected ? Colors.white : AppTheme.textMain,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimingsCard(double totalHoursPerShift) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.schedule_rounded, size: 18, color: AppTheme.warning),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SHIFT TIMING & ROTATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMuted,
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          'Hours per shift and break schedules',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                StatusBadge(
                  label: '${totalHoursPerShift}h / shift',
                  variant: StatusVariant.info,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quick Shift Presets
            const Text(
              'Preset Timing Templates:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'Morning Shift (10:00 - 18:00)',
                  'Evening Shift (14:00 - 22:00)',
                  'Full Day / Split (10:00 - 22:00)',
                  'Weekend Split Shift',
                  'Custom Shift',
                ].map((preset) {
                  final isSelected = _selectedShiftPreset == preset;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        preset,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.white : AppTheme.textMain,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppTheme.primary,
                      backgroundColor: AppTheme.surfaceSubtle,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onSelected: (val) {
                        if (val) _applyShiftPreset(preset);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Start & End Time Pickers (Dual tactile cards)
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: _startTime);
                      if (picked != null) {
                        setState(() {
                          _startTime = picked;
                          _selectedShiftPreset = 'Custom Shift';
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.login_rounded, size: 14, color: AppTheme.accent),
                              SizedBox(width: 4),
                              Text(
                                'START TIME',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _startTime.format(context),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textMain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: _endTime);
                      if (picked != null) {
                        setState(() {
                          _endTime = picked;
                          _selectedShiftPreset = 'Custom Shift';
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceSubtle,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.logout_rounded, size: 14, color: AppTheme.warning),
                              SizedBox(width: 4),
                              Text(
                                'END TIME',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _endTime.format(context),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textMain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Break Presets
            const Text(
              'Break Rotation Presets (Tap to Apply):',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  '5:00 PM - 5:45 PM (Standard)',
                  '1:30 PM - 2:15 PM (Morning)',
                  '4:00 PM - 4:45 PM (Early)',
                  '6:00 PM - 6:45 PM (Late)',
                  'Split: 2x 30 mins',
                  'No Scheduled Break',
                ].map((bPreset) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      backgroundColor: AppTheme.surfaceSubtle,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      label: Text(
                        bPreset,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMain),
                      ),
                      onPressed: () {
                        setState(() {
                          _breakTimingsController.text = bPreset == 'No Scheduled Break' ? 'No Break' : bPreset;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _breakTimingsController,
              decoration: const InputDecoration(
                labelText: 'Break Rotation Window *',
                hintText: 'e.g. 5:00 PM - 5:45 PM',
                prefixIcon: Icon(Icons.coffee_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBriefCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notes_rounded, size: 18, color: AppTheme.success),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IN-STORE BRIEF & INSTRUCTIONS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      'Promoter task notes & entrance location',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Shift Brief / Execution Instructions',
                hintText: 'e.g. Stand near entrance carousel; check POSM hygiene; distribute sample kits',
                prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
