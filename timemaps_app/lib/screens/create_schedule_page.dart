import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

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
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.inner)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Successfully scheduled $createdCount shifts for ${_selectedStore!.storeName}!',
                  style: AppText.bodyBold.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.inner)),
        content: Text(
          message,
          style: AppText.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalHoursPerShift = _calculateTotalHours();
    final cumulativeHours = (totalHoursPerShift * _selectedDates.length).toStringAsFixed(1);

    return AppScreenScaffold(
      bottomClearance: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: 'Batch Shift Scheduler',
      subtitle: '${_selectedDates.length} shifts selected • $cumulativeHours total hrs',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: StatusBadge(
            label: '${_selectedDates.length} Shifts',
            variant: _selectedDates.isNotEmpty ? StatusVariant.info : StatusVariant.neutral,
            showDot: _selectedDates.isNotEmpty,
          ),
        ),
      ],
      floatingBottom: StickyActionBar(
        summaryText: _selectedStore != null
            ? '${_selectedStore!.storeName} • ${_selectedDates.length} shifts (${cumulativeHours}h)'
            : null,
        primaryLabel: _isSaving ? 'Scheduling...' : 'Confirm Shifts (${_selectedDates.length})',
        primaryIcon: Icons.event_available_rounded,
        primaryLoading: _isSaving,
        onPrimaryPressed: _isSaving ? null : _handleBatchSave,
      ),
      body: _isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Guidance Banner
                AppCard.flat(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      const IconBox(
                        icon: Icons.auto_awesome_rounded,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Multi-Date Batch Generator', style: AppText.bodyBold),
                            const SizedBox(height: 2),
                            Text(
                              'Select venue and tap dates to generate synced shifts with break rotations.',
                              style: AppText.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),

                // Section 1: Venue & Staff Assignment
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(
                        icon: Icons.store_mall_directory_rounded,
                        iconColor: AppColors.primary,
                        microLabel: 'VENUE & STAFF',
                        title: 'Campaign & Store Assignment',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SearchableSelectField<ProjectModel>(
                        label: 'Campaign Roadshow *',
                        value: _selectedProject,
                        options: _projects
                            .map((p) => SearchableOption<ProjectModel>(
                                  value: p,
                                  label: p.name,
                                  subtitle: p.clientName.isNotEmpty ? p.clientName : 'Direct Client',
                                ))
                            .toList(),
                        prefixIcon: const Icon(Icons.campaign_outlined, size: 20),
                        onChanged: (p) => setState(() => _selectedProject = p),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SearchableSelectField<StoreModel>(
                        label: 'Store Location *',
                        value: _selectedStore,
                        options: _stores
                            .map((s) => SearchableOption<StoreModel>(
                                  value: s,
                                  label: s.storeName,
                                  subtitle: '${s.retailer} • ${s.emirate} • Code: ${s.customerCode ?? "N/A"}',
                                ))
                            .toList(),
                        prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
                        onChanged: (s) => setState(() => _selectedStore = s),
                      ),
                      if (_selectedStore != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        AppCard.flat(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              InitialsAvatar(name: _selectedStore!.retailer, size: 24),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  '${_selectedStore!.retailer} • ${_selectedStore!.emirate} • SMN: ${_selectedStore!.smnContact ?? "Operations"}',
                                  style: AppText.caption.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
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
                                subtitle: '${p.phone}${p.nationality != null ? " • ${p.nationality}" : ""}',
                              )),
                        ],
                        prefixIcon: const Icon(Icons.person_pin_circle_outlined, size: 20),
                        onChanged: (p) => setState(() => _selectedPromoter = p),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),

                // Section 2: Shift Date Matrix (Calendar)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionHeader(
                        icon: Icons.calendar_month_rounded,
                        iconColor: AppColors.accent,
                        microLabel: 'SHIFT DATES MATRIX',
                        title: 'Tap Dates to Toggle',
                        trailing: StatusBadge(
                          label: '${_selectedDates.length} Days Active',
                          variant: _selectedDates.isNotEmpty ? StatusVariant.success : StatusVariant.neutral,
                          showDot: _selectedDates.isNotEmpty,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Month navigation bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadius.inner),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left_rounded, size: 22, color: AppColors.textPrimary),
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
                              style: AppText.title,
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right_rounded, size: 22, color: AppColors.textPrimary),
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
                      const SizedBox(height: AppSpacing.sm),

                      // Weekday headers
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
                      const SizedBox(height: 6),

                      // Grid of days
                      _buildResponsiveCalendarGrid(),
                      const SizedBox(height: AppSpacing.md),

                      // Quick Select Actions
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          AppButton.secondary(
                            label: 'Peak Retail (Thu–Sun)',
                            icon: Icons.bolt_rounded,
                            height: 36,
                            onPressed: _selectWeekendDays,
                          ),
                          AppButton.secondary(
                            label: 'All Days',
                            icon: Icons.calendar_view_month_rounded,
                            height: 36,
                            onPressed: _selectAllMonthDays,
                          ),
                          AppButton.destructive(
                            label: 'Clear',
                            icon: Icons.close_rounded,
                            height: 36,
                            onPressed: () => setState(() => _selectedDates.clear()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),

                // Section 3: Shift Timing & Rotation
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionHeader(
                        icon: Icons.schedule_rounded,
                        iconColor: AppColors.warning,
                        microLabel: 'SHIFT TIMING & ROTATION',
                        title: 'Hours & Breaks',
                        trailing: StatusBadge(
                          label: '${totalHoursPerShift}h / shift',
                          variant: StatusVariant.info,
                          showDot: false,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      Text(
                        'PRESET TIMING TEMPLATES',
                        style: AppText.micro.copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          'Morning Shift (10:00 - 18:00)',
                          'Evening Shift (14:00 - 22:00)',
                          'Full Day / Split (10:00 - 22:00)',
                          'Weekend Split Shift',
                          'Custom Shift',
                        ].map((preset) {
                          return FilterPill(
                            label: preset,
                            isSelected: _selectedShiftPreset == preset,
                            onTap: () => _applyShiftPreset(preset),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Dual Start & End time tap containers
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final startWidget = InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(context: context, initialTime: _startTime);
                              if (picked != null) {
                                setState(() {
                                  _startTime = picked;
                                  _selectedShiftPreset = 'Custom Shift';
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(AppRadius.input),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(AppRadius.input),
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.login_rounded, size: 14, color: AppColors.accent),
                                      const SizedBox(width: 4),
                                      Text(
                                        'START TIME',
                                        style: AppText.micro.copyWith(color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(_startTime.format(context), style: AppText.title),
                                ],
                              ),
                            ),
                          );

                          final endWidget = InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(context: context, initialTime: _endTime);
                              if (picked != null) {
                                setState(() {
                                  _endTime = picked;
                                  _selectedShiftPreset = 'Custom Shift';
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(AppRadius.input),
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(AppRadius.input),
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.logout_rounded, size: 14, color: AppColors.warning),
                                      const SizedBox(width: 4),
                                      Text(
                                        'END TIME',
                                        style: AppText.micro.copyWith(color: AppColors.textMuted),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(_endTime.format(context), style: AppText.title),
                                ],
                              ),
                            ),
                          );

                          if (constraints.maxWidth < 340) {
                            return Column(
                              children: [
                                startWidget,
                                const SizedBox(height: AppSpacing.sm),
                                endWidget,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: startWidget),
                              const SizedBox(width: AppSpacing.sm + 2),
                              Expanded(child: endWidget),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      Text(
                        'BREAK ROTATION PRESETS (TAP TO APPLY)',
                        style: AppText.micro.copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          '5:00 PM - 5:45 PM',
                          '1:30 PM - 2:15 PM',
                          '4:00 PM - 4:45 PM',
                          'Split: 2x 30 mins',
                          'No Break',
                        ].map((bPreset) {
                          final isSel = _breakTimingsController.text == bPreset;
                          return FilterPill(
                            label: bPreset,
                            isSelected: isSel,
                            onTap: () {
                              setState(() {
                                _breakTimingsController.text = bPreset;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _breakTimingsController,
                        label: 'Break Rotation Window *',
                        hint: 'e.g. 5:00 PM - 5:45 PM',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),

                // Section 4: In-Store Brief & Instructions
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(
                        icon: Icons.notes_rounded,
                        iconColor: AppColors.success,
                        microLabel: 'IN-STORE BRIEF',
                        title: 'Promoter Task Notes',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _notesController,
                        label: 'Shift Brief / Execution Instructions',
                        hint: 'e.g. Stand near entrance carousel; check POSM hygiene; distribute sample kits',
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
              ],
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
              style: AppText.micro.copyWith(
                fontWeight: isPeak ? FontWeight.w800 : FontWeight.w600,
                color: isPeak ? AppColors.accent : AppColors.textMuted,
              ),
            ),
            if (isPeak)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
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
          borderRadius: BorderRadius.circular(AppRadius.inner),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : (isWeekend ? AppColors.surfaceMuted : AppColors.surface),
              borderRadius: BorderRadius.circular(AppRadius.inner),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.borderSubtle,
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.24),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: AppText.caption.copyWith(
                  fontWeight: isSelected ? FontWeight.w800 : (isWeekend ? FontWeight.w700 : FontWeight.w500),
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
