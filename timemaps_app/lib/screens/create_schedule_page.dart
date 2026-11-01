import 'package:flutter/material.dart';
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
        // Thu (4), Fri (5), Sat (6), Sun (7) are common UAE retail promotional peak days
        if (date.weekday == DateTime.thursday ||
            date.weekday == DateTime.friday ||
            date.weekday == DateTime.saturday ||
            date.weekday == DateTime.sunday) {
          _selectedDates.add(DateFormat('yyyy-MM-dd').format(date));
        }
      }
    });
  }

  Future<void> _handleBatchSave() async {
    if (_selectedProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Campaign Project')),
      );
      return;
    }
    if (_selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Store Location')),
      );
      return;
    }
    if (_selectedDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 1 shift date on the calendar')),
      );
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

    setState(() => _isSaving = false);

    if (createdCount > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.success,
          content: Text('Successfully scheduled $createdCount shifts!'),
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.danger,
          content: Text('Failed to save shifts. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Batch Shift Scheduler',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textMain),
            ),
            Text(
              '${_selectedDates.length} shifts selected',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: const Size(0, 36),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: _isSaving ? null : _handleBatchSave,
              icon: _isSaving
                  ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_rounded, size: 16),
              label: Text(
                'Save (${_selectedDates.length})',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Modern Guide Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.infoBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.infoBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.bolt_rounded, color: AppTheme.accent, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Select your store and tap dates on the calendar. All ${_selectedDates.length} shifts will be generated simultaneously.',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Section 1: Campaign & Store
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.hub_outlined, size: 16, color: AppTheme.accent),
                                const SizedBox(width: 6),
                                Text(
                                  'CAMPAIGN & VENUE',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textMuted,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Project Dropdown with Ellipsis protection
                            DropdownButtonFormField<ProjectModel>(
                              isExpanded: true,
                              value: _selectedProject,
                              decoration: const InputDecoration(
                                labelText: 'Campaign Project *',
                                prefixIcon: Icon(Icons.campaign_outlined, size: 20),
                              ),
                              items: _projects.map((p) {
                                return DropdownMenuItem(
                                  value: p,
                                  child: Text(
                                    p.name,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedProject = val),
                            ),
                            const SizedBox(height: 12),

                            // Store Searchable Dropdown
                            SearchableSelectField<StoreModel>(
                              label: 'Store Location *',
                              value: _selectedStore,
                              options: _stores.map((s) => SearchableOption<StoreModel>(
                                value: s,
                                label: s.storeName,
                                subtitle: '${s.retailer} • ${s.emirate}',
                              )).toList(),
                              prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
                              onChanged: (s) => setState(() => _selectedStore = s),
                            ),
                            const SizedBox(height: 12),

                            // Assigned Promoter (Protected against overflow)
                            DropdownButtonFormField<PromoterModel?>(
                              isExpanded: true,
                              value: _selectedPromoter,
                              decoration: const InputDecoration(
                                labelText: 'Assign Promoter (Optional)',
                                prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                              ),
                              items: [
                                const DropdownMenuItem<PromoterModel?>(
                                  value: null,
                                  child: Text(
                                    'Open Shift (Unassigned)',
                                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                ..._promoters.map((p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(
                                        '${p.name} (${p.phone})',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )),
                              ],
                              onChanged: (val) => setState(() => _selectedPromoter = val),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Section 2: Multi-Date Calendar Selection
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_month_outlined, size: 16, color: AppTheme.accent),
                                    const SizedBox(width: 6),
                                    Text(
                                      'SHIFT DATES',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textMuted,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                StatusBadge(
                                  label: '${_selectedDates.length} Days Selected',
                                  variant: _selectedDates.isNotEmpty ? StatusVariant.success : StatusVariant.neutral,
                                  showDot: _selectedDates.isNotEmpty,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Month navigation
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceSubtle,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
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
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textMain),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
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
                            const SizedBox(height: 10),

                            // Day of week headers
                            Row(
                              children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) {
                                final isWeekend = d == 'Sat' || d == 'Sun' || d == 'Fri';
                                return Expanded(
                                  child: Center(
                                    child: Text(
                                      d,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isWeekend ? FontWeight.w700 : FontWeight.w600,
                                        color: isWeekend ? AppTheme.accent : AppTheme.textMuted,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 8),

                            // Grid of days
                            _buildResponsiveCalendarGrid(),

                            const SizedBox(height: 12),

                            // Quick Select Actions
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      minimumSize: const Size(0, 36),
                                    ),
                                    onPressed: _selectWeekendDays,
                                    icon: const Icon(Icons.star_outline_rounded, size: 14),
                                    label: const Text('Thu-Sun Peak', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    minimumSize: const Size(0, 36),
                                  ),
                                  onPressed: () => setState(() => _selectedDates.clear()),
                                  icon: const Icon(Icons.clear_all_rounded, size: 14, color: AppTheme.danger),
                                  label: const Text('Clear All', style: TextStyle(fontSize: 11, color: AppTheme.danger, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Section 3: Shift Timings & Break Rotation
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.timer_outlined, size: 16, color: AppTheme.accent),
                                    const SizedBox(width: 6),
                                    Text(
                                      'SHIFT TIMINGS',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textMuted,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                StatusBadge(
                                  label: '${_calculateTotalHours()} hrs duration',
                                  variant: StatusVariant.info,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Quick Shift Templates
                            const Text('Preset Timing Templates:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
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
                                    padding: const EdgeInsets.only(right: 6),
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
                                      onSelected: (val) {
                                        if (val) _applyShiftPreset(preset);
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Start & End Time Pickers (Responsive)
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
                                    borderRadius: BorderRadius.circular(12),
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Start Time *',
                                        prefixIcon: Icon(Icons.schedule_outlined, size: 18),
                                      ),
                                      child: Text(
                                        _startTime.format(context),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
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
                                    borderRadius: BorderRadius.circular(12),
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'End Time *',
                                        prefixIcon: Icon(Icons.timer_off_outlined, size: 18),
                                      ),
                                      child: Text(
                                        _endTime.format(context),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Break presets
                            const Text('Break Rotation Presets (Tap to Apply):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                            const SizedBox(height: 6),
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
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ActionChip(
                                      label: Text(bPreset, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
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
                            const SizedBox(height: 10),

                            TextField(
                              controller: _breakTimingsController,
                              decoration: const InputDecoration(
                                labelText: 'Break Rotation Window *',
                                hintText: 'e.g. 5:00 PM - 5:45 PM',
                                prefixIcon: Icon(Icons.coffee_outlined, size: 18),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Shift Notes
                            TextField(
                              controller: _notesController,
                              decoration: const InputDecoration(
                                labelText: 'Shift Brief / In-Store Instructions',
                                hintText: 'e.g. Sampling setup at entrance, POSM hygiene check',
                                prefixIcon: Icon(Icons.note_alt_outlined, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bottom Action Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isSaving ? null : _handleBatchSave,
                      child: _isSaving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(
                              'Create ${_selectedDates.length} Shifts Simultaneously',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
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
        childAspectRatio: 1.0,
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
        final isWeekend = date.weekday == DateTime.friday || date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

        return InkWell(
          onTap: () => _toggleDate(date),
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : (isWeekend ? AppTheme.surfaceSubtle : Colors.white),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppTheme.primary : AppTheme.borderSubtle,
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.25),
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
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : (isWeekend ? FontWeight.w700 : FontWeight.w500),
                  color: isSelected ? Colors.white : AppTheme.textMain,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
