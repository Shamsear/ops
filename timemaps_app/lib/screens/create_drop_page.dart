import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/searchable_select_field.dart';
import '../widgets/status_badge.dart';
import 'create_project_page.dart';
import 'create_store_page.dart';

class CreateDropPage extends StatefulWidget {
  final int? preselectedProjectId;
  final int? preselectedStoreId;

  const CreateDropPage({
    super.key,
    this.preselectedProjectId,
    this.preselectedStoreId,
  });

  @override
  State<CreateDropPage> createState() => _CreateDropPageState();
}

class _CreateDropPageState extends State<CreateDropPage> {
  List<ProjectModel> _projects = [];
  List<StoreModel> _stores = [];
  List<UserModel> _supervisors = [];

  ProjectModel? _selectedProject;
  StoreModel? _selectedStore;
  UserModel? _selectedSupervisor;

  DateTime _dropDate = DateTime.now();
  String _priority = 'Standard Morning';
  final _manifestController = TextEditingController(
    text: '1x Pop-up Display Stand, 2x Rollup Banners, 5x Sampling Cartons',
  );
  final _accessNotesController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _quickManifestPills = [
    '1x Pop-up Display Stand',
    '2x Rollup Banners',
    '5x Sampling Cartons',
    '1x Branded Podium',
    'Chiller POSM Kit',
    'Product Leaflets & Vouchers',
  ];

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  @override
  void dispose() {
    _manifestController.dispose();
    _accessNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    setState(() => _isLoading = true);
    final projects = await ApiService.getProjects();
    final stores = await ApiService.getStores();
    final supervisors = await ApiService.getSupervisors();

    if (mounted) {
      setState(() {
        _projects = projects;
        _stores = stores;
        _supervisors = supervisors;

        if (widget.preselectedProjectId != null) {
          _selectedProject = _projects.where((p) => p.id == widget.preselectedProjectId).firstOrNull;
        }
        _selectedProject ??= _projects.isNotEmpty ? _projects.first : null;

        if (widget.preselectedStoreId != null) {
          _selectedStore = _stores.where((s) => s.id == widget.preselectedStoreId).firstOrNull;
        }
        _selectedStore ??= _stores.isNotEmpty ? _stores.first : null;

        _selectedSupervisor = _supervisors.isNotEmpty ? _supervisors.first : null;
        _isLoading = false;
      });
    }
  }

  void _addManifestItem(String item) {
    final current = _manifestController.text.trim();
    if (current.isEmpty) {
      _manifestController.text = item;
    } else if (!current.contains(item)) {
      _manifestController.text = '$current, $item';
    }
  }

  Future<void> _handleSave() async {
    if (_selectedProject == null) {
      _showWarning('Please select a Campaign Project');
      return;
    }
    if (_selectedStore == null) {
      _showWarning('Please select Destination Store');
      return;
    }
    if (_selectedSupervisor == null) {
      _showWarning('Please assign a Supervisor / Delivery Driver');
      return;
    }
    if (_manifestController.text.trim().isEmpty) {
      _showWarning('Please specify items manifest to deliver');
      return;
    }

    setState(() => _isSaving = true);

    final success = await ApiService.createDrop(
      projectId: _selectedProject!.id,
      storeId: _selectedStore!.id,
      supervisorId: _selectedSupervisor!.id,
      scheduledDate: DateFormat('yyyy-MM-dd').format(_dropDate),
      itemsManifest: _manifestController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
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
                  'Morning Drop dispatched to ${_selectedStore!.storeName}!',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
      Navigator.pop(context, true);
    } else {
      _showWarning('Failed to dispatch drop. Please try again.');
    }
  }

  void _showWarning(String message) {
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
    return Scaffold(
      backgroundColor: AppTheme.canvasBg,
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
                color: Colors.white.withOpacity(0.78),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.55),
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Morning Drop-off',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMain,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Dispatch POSM & stands to venue',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: StatusBadge(
              label: 'Drop-off',
              variant: StatusVariant.warning,
              showDot: true,
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
            opacity: 0.88,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.accent),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('EEE, dd MMM yyyy').format(_dropDate),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMain,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedStore != null
                            ? '${_selectedStore!.retailer} • ${_selectedStore!.emirate}'
                            : 'Select destination store',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warning,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    onPressed: _isSaving ? null : _handleSave,
                    icon: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.local_shipping_rounded, size: 18),
                    label: Text(
                      _isSaving ? 'Dispatching...' : 'Dispatch Drop Task',
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
          : AmbientMeshBackground(
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Guidance Banner
                      _buildGuideBanner(),
                      const SizedBox(height: 14),

                      // Section 1: Venue & Campaign Selection
                      _buildVenueCard(),
                      const SizedBox(height: 14),

                      // Section 2: Logistics Driver & Scheduled Date
                      _buildDispatchScheduleCard(),
                      const SizedBox(height: 14),

                      // Section 3: Items Manifest to Deliver
                      _buildManifestCard(),
                      const SizedBox(height: 14),

                      // Section 4: Loading Bay & Store Access Instructions
                      _buildAccessNotesCard(),
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildGuideBanner() {
    return GlassCard(
      radius: 16,
      opacity: 0.88,
      padding: const EdgeInsets.all(14),
      tintColor: const Color(0xFFFFFBEB).withOpacity(0.92),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_shipping_rounded, color: AppTheme.warning, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Morning Stand & Material Drop-off',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  'Assign promotional stands, rollups, and stock to field supervisor.',
                  style: TextStyle(
                    fontSize: 11.5,
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
    return GlassCard(
      radius: 20,
      opacity: 0.85,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.storefront_rounded, size: 18, color: AppTheme.primary),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DESTINATION VENUE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.6,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Store receiving promotional delivery',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () async {
                  final newStore = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateStorePage()),
                  );
                  if (newStore == true) _loadFormData();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '+ New Store',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.accent,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Campaign Project Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Campaign Project',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
              ),
              InkWell(
                onTap: () async {
                  final newProj = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateProjectPage()),
                  );
                  if (newProj == true) _loadFormData();
                },
                child: const Text(
                  '+ New Campaign',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SearchableSelectField<ProjectModel>(
            label: 'Campaign Project *',
            value: _selectedProject,
            options: _projects.map((p) => SearchableOption<ProjectModel>(
              value: p,
              label: p.name,
              subtitle: p.clientName.isNotEmpty ? p.clientName : 'Direct Client',
            )).toList(),
            prefixIcon: const Icon(Icons.campaign_outlined, size: 20),
            onChanged: (p) => setState(() => _selectedProject = p),
          ),
          const SizedBox(height: 14),

          // Store Location Selector
          SearchableSelectField<StoreModel>(
            label: 'Destination Store *',
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
                      '${_selectedStore!.emirate} • Lead: ${_selectedStore!.smnContact ?? 'Operations Team'}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDispatchScheduleCard() {
    return GlassCard(
      radius: 20,
      opacity: 0.85,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_pin_circle_rounded, size: 18, color: AppTheme.accent),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DISPATCH & TIMELINE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.6,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Assigned supervisor and target drop date',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Assigned Supervisor Selector
          SearchableSelectField<UserModel>(
            label: 'Assigned Supervisor (to Deliver) *',
            value: _selectedSupervisor,
            options: _supervisors.map((u) => SearchableOption<UserModel>(
              value: u,
              label: u.name,
              subtitle: '${u.phone} • ${u.role}',
            )).toList(),
            prefixIcon: const Icon(Icons.manage_accounts_outlined, size: 20),
            onChanged: (u) => setState(() => _selectedSupervisor = u),
          ),
          const SizedBox(height: 14),

          // Scheduled Date Picker
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dropDate,
                firstDate: DateTime.now().subtract(const Duration(days: 3)),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (picked != null) setState(() => _dropDate = picked);
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSubtle,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SCHEDULED DROP-OFF DATE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('EEEE, dd MMMM yyyy').format(_dropDate),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMain,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Priority Selector Chips
          const Text(
            'Delivery Priority Window:',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Standard Morning',
              'Urgent Pre-Opening',
              'Mid-day Restock',
            ].map((p) {
              final isSelected = _priority == p;
              return ChoiceChip(
                label: Text(
                  p,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.textMain,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppTheme.warning,
                backgroundColor: AppTheme.surfaceSubtle,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onSelected: (val) {
                  if (val) setState(() => _priority = p);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildManifestCard() {
    return GlassCard(
      radius: 20,
      opacity: 0.85,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2_rounded, size: 18, color: AppTheme.warning),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ITEMS MANIFEST TO DELIVER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.6,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Promotional stands, banners & stock kits',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Quick Item Pills
          const Text(
            'Quick Add Common Items (Tap to append):',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _quickManifestPills.map((item) {
              return ActionChip(
                backgroundColor: AppTheme.surfaceSubtle,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                label: Text(
                  '+ $item',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMain),
                ),
                onPressed: () => _addManifestItem(item),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _manifestController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Detailed Manifest & Items List *',
              hintText: 'e.g. 1x Pop-up Display Stand, 2x Rollup Banners, 5x Sampling Cartons',
              prefixIcon: Icon(Icons.checklist_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessNotesCard() {
    return GlassCard(
      radius: 20,
      opacity: 0.85,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_turned_in_rounded, size: 18, color: AppTheme.accentTeal),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LOADING BAY & STORE ACCESS NOTES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.6,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Security clearance, dock entrance & contact',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _accessNotesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Access Instructions (Optional)',
              hintText: 'e.g. Enter via Loading Bay 3; present Hypermarket gate pass at security desk',
              prefixIcon: Icon(Icons.door_sliding_outlined, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
