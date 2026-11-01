import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/searchable_select_field.dart';

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
  String _staffRole = 'PROMOTER';
  bool _isLoading = true;
  bool _isSaving = false;

  TimeOfDay _startTime = const TimeOfDay(hour: 14, minute: 0); // 2:00 PM
  TimeOfDay _endTime = const TimeOfDay(hour: 22, minute: 0); // 10:00 PM
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
    // Pre-select October 15, 16, 17, 18 as initial demo selection
    _selectedDates.addAll(['2026-10-15', '2026-10-16', '2026-10-17', '2026-10-18']);
    _loadFormData();
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

  Future<void> _handleBatchSave() async {
    if (_selectedProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Campaign Project')));
      return;
    }
    if (_selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select Store Location')));
      return;
    }
    if (_selectedDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least 1 shift date on the calendar')));
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
        SnackBar(content: Text('Successfully scheduled $createdCount shifts simultaneously!')),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save shifts. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Batch Shift Scheduler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textMain)),
            Text('Schedule Multiple Shifts in 1 Tap', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _isSaving ? null : _handleBatchSave,
              icon: _isSaving
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text('Save (${_selectedDates.length})', style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Fast Guide Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt_rounded, color: AppTheme.primary, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Select your store and tap multiple dates on the calendar below. All ${_selectedDates.length} shifts will be generated in 1 second.',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMain, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section 1: Store & Project Selectors
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CAMPAIGN & VENUE',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 14),

                          // Project Dropdown
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
                                child: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedProject = val),
                          ),
                          const SizedBox(height: 14),

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
                          const SizedBox(height: 14),

                          // Assigned Promoter (Optional)
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
                                child: Text('Open Shift (Unassigned)', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                              ),
                              ..._promoters.map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Text('${p.name} (${p.phone})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  )),
                            ],
                            onChanged: (val) => setState(() => _selectedPromoter = val),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Section 2: Multi-Date Interactive Calendar Tap
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'SHIFT DATES (TAP TO SELECT)',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.5),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryDark,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_selectedDates.length} Days Selected',
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Month navigation
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left_rounded),
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
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textMain),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right_rounded),
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
                          const SizedBox(height: 6),

                          // Day of week headers
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                                .map((d) => SizedBox(
                                      width: 38,
                                      child: Center(
                                        child: Text(
                                          d,
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                          const SizedBox(height: 8),

                          // Calendar Grid
                          _buildCalendarDaysGrid(),

                          const SizedBox(height: 12),
                          // Quick batch shortcuts
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              ActionChip(
                                label: const Text('Thu - Sun (Weekend)', style: TextStyle(fontSize: 11)),
                                onPressed: () {
                                  setState(() {
                                    for (int d = 1; d <= 31; d++) {
                                      final date = DateTime(2026, 10, d);
                                      if (date.weekday >= 4) { // Thu, Fri, Sat, Sun
                                        _selectedDates.add(DateFormat('yyyy-MM-dd').format(date));
                                      }
                                    }
                                  });
                                },
                              ),
                              ActionChip(
                                label: const Text('Clear All', style: TextStyle(fontSize: 11, color: AppTheme.danger)),
                                onPressed: () => setState(() => _selectedDates.clear()),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Section 3: Shift Hours & Break Timings (Fully Customizable & Zero Hardcoded)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'SHIFT TIMINGS & BREAK SCHEDULE',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.5),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Text(
                                  '${_calculateTotalHours()} hrs duration',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Quick Shift Templates
                          const Text('Quick Shift Preset:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                          const SizedBox(height: 6),
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
                                    label: Text(preset, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600)),
                                    selected: isSelected,
                                    selectedColor: AppTheme.primaryDark,
                                    labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textMain),
                                    onSelected: (val) {
                                      if (val) _applyShiftPreset(preset);
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Interactive Time Pickers for Exact Start & End Time
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
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Start Time *',
                                      prefixIcon: Icon(Icons.schedule_outlined, size: 18),
                                      helperText: 'Tap to change time',
                                    ),
                                    child: Text(_startTime.format(context), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
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
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'End Time *',
                                      prefixIcon: Icon(Icons.timer_off_outlined, size: 18),
                                      helperText: 'Tap to change time',
                                    ),
                                    child: Text(_endTime.format(context), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Break timings with Quick Preset Chips & Free Custom Text
                          const Text('Break Rotation Presets (Tap to Apply):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                          const SizedBox(height: 6),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                '5:00 PM - 5:45 PM (Standard)',
                                '1:30 PM - 2:15 PM (Morning)',
                                '4:00 PM - 4:45 PM (Early Break)',
                                '6:00 PM - 6:45 PM (Late Break)',
                                'Split: 2x 30 mins',
                                'No Scheduled Break',
                              ].map((bPreset) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ActionChip(
                                    label: Text(bPreset, style: const TextStyle(fontSize: 10)),
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
                              labelText: 'Break Rotation Window (Fully Customizable) *',
                              hintText: 'e.g. 5:00 PM - 5:45 PM, or Split: 1-1:30 & 6-6:30',
                              prefixIcon: Icon(Icons.coffee_outlined, size: 18),
                              helperText: 'Displays directly on promoter mobile screen to avoid store disputes',
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Shift Notes / Specific Brief
                          TextField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Shift Brief / In-Store Tasks',
                              hintText: 'e.g. Sampling setup at entrance, POSM hygiene check',
                              prefixIcon: Icon(Icons.note_alt_outlined, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bottom Action Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: _isSaving ? null : _handleBatchSave,
                    child: _isSaving
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                            'Create ${_selectedDates.length} Shifts Simultaneously',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCalendarDaysGrid() {
    final firstDayOfMonth = DateTime(_currentCalendarMonth.year, _currentCalendarMonth.month, 1);
    final daysInMonth = DateTime(_currentCalendarMonth.year, _currentCalendarMonth.month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Mon, 7 = Sun

    final List<Widget> dayWidgets = [];

    // Empty spaces before first day
    for (int i = 1; i < startingWeekday; i++) {
      dayWidgets.add(const SizedBox(width: 38, height: 38));
    }

    // Days in current month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentCalendarMonth.year, _currentCalendarMonth.month, day);
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final isSelected = _selectedDates.contains(dateStr);

      dayWidgets.add(
        InkWell(
          onTap: () => _toggleDate(date),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.borderSubtle),
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.textMain,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: dayWidgets,
    );
  }
}
