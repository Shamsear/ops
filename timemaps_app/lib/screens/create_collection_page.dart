import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/liquid_glass.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/searchable_select_field.dart';
import '../widgets/status_badge.dart';
import 'create_project_page.dart';
import 'create_store_page.dart';

class CreateCollectionPage extends StatefulWidget {
  final int? preselectedProjectId;
  final int? preselectedStoreId;

  const CreateCollectionPage({
    super.key,
    this.preselectedProjectId,
    this.preselectedStoreId,
  });

  @override
  State<CreateCollectionPage> createState() => _CreateCollectionPageState();
}

class _CreateCollectionPageState extends State<CreateCollectionPage> {
  List<ProjectModel> _projects = [];
  List<StoreModel> _stores = [];
  List<UserModel> _supervisors = [];

  ProjectModel? _selectedProject;
  StoreModel? _selectedStore;
  UserModel? _selectedSupervisor;

  DateTime _collectionDate = DateTime.now().add(const Duration(days: 4));
  String _destinationDepot = 'Main Warehouse - Al Quoz';
  final _itemsController = TextEditingController(
    text: '1x Pop-up Display Stand, 2x Rollup Banners, Unused POSM',
  );
  final _teardownNotesController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _quickCollectionPills = [
    'Full Stand Teardown',
    '1x Pop-up Display Stand',
    '2x Rollup Banners',
    'Remaining Stock & Samples',
    'Podium & Brochure Racks',
    'Complete Venue Clearance',
  ];

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  @override
  void dispose() {
    _itemsController.dispose();
    _teardownNotesController.dispose();
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

  void _addCollectionItem(String item) {
    final current = _itemsController.text.trim();
    if (current.isEmpty) {
      _itemsController.text = item;
    } else if (!current.contains(item)) {
      _itemsController.text = '$current, $item';
    }
  }

  Future<void> _handleSave() async {
    if (_selectedProject == null) {
      _showWarning('Please select Campaign Roadshow');
      return;
    }
    if (_selectedStore == null) {
      _showWarning('Please select Store Location');
      return;
    }
    if (_selectedSupervisor == null) {
      _showWarning('Please assign a Supervisor / Logistics Driver');
      return;
    }
    if (_itemsController.text.trim().isEmpty) {
      _showWarning('Please specify items to retrieve from store');
      return;
    }

    setState(() => _isSaving = true);

    final success = await ApiService.createCollection(
      projectId: _selectedProject!.id,
      storeId: _selectedStore!.id,
      supervisorId: _selectedSupervisor!.id,
      scheduledDate: DateFormat('yyyy-MM-dd').format(_collectionDate),
      itemsToCollect: _itemsController.text.trim(),
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
                  'Return Collection scheduled for ${_selectedStore!.storeName}!',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
      Navigator.pop(context, true);
    } else {
      _showWarning('Failed to schedule collection. Please try again.');
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Assign Return Collection',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMain,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Schedule stand teardown & inventory retrieval',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: StatusBadge(
              label: 'Collection',
              variant: StatusVariant.success,
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
            opacity: 0.85,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEE, dd MMM yyyy').format(_collectionDate),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMain,
                      ),
                    ),
                    Text(
                      _selectedStore != null
                          ? '${_selectedStore!.retailer} • ${_selectedStore!.emirate}'
                          : 'Select store to collect from',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                onPressed: _isSaving ? null : _handleSave,
                icon: _isSaving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.repeat_rounded, size: 18),
                label: Text(
                  _isSaving ? 'Scheduling...' : 'Confirm Collection',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
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
                    // Guidance banner
                    _buildGuideBanner(),
                    const SizedBox(height: 16),

                    // Section 1: Venue & Campaign Selection
                    _buildVenueCard(),
                    const SizedBox(height: 16),

                    // Section 2: Logistics Driver & Scheduled Date
                    _buildCollectionTimelineCard(),
                    const SizedBox(height: 16),

                    // Section 3: Items to Collect
                    _buildItemsCard(),
                    const SizedBox(height: 16),

                    // Section 4: Return Warehouse & Teardown Notes
                    _buildDepotAndNotesCard(),
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
        color: AppTheme.successBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.successBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.repeat_rounded, color: AppTheme.success, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Post-Campaign Material Retrieval',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMain,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Schedule stand dismantling and excess stock return. Supervisors verify collected items on-site and confirm safe warehouse return.',
                  style: TextStyle(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.storefront_rounded, size: 18, color: AppTheme.success),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RETRIEVAL STORE LOCATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMuted,
                            letterSpacing: 0.6,
                          ),
                        ),
                        Text(
                          'Store where equipment will be picked up',
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
                InkWell(
                  onTap: () async {
                    final newStore = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreateStorePage()),
                    );
                    if (newStore == true) _loadFormData();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Text(
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
              label: 'Store Location to Collect From *',
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
      ),
    );
  }

  Widget _buildCollectionTimelineCard() {
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
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_pin_circle_rounded, size: 18, color: AppTheme.accent),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COLLECTION DRIVER & DATE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      'Assigned supervisor and target retrieval date',
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

            // Assigned Supervisor Selector
            SearchableSelectField<UserModel>(
              label: 'Assigned Supervisor (to Collect) *',
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
                  initialDate: _collectionDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 3)),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (picked != null) setState(() => _collectionDate = picked);
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.accent),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SCHEDULED COLLECTION DATE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('EEEE, dd MMMM yyyy').format(_collectionDate),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMain,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down_rounded, color: AppTheme.textMuted),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard() {
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
                  child: const Icon(Icons.inventory_rounded, size: 18, color: AppTheme.success),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ITEMS TO RETRIEVE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      'Display fixtures, remaining stock & marketing assets',
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

            // Quick Checklist Pills
            const Text(
              'Common Items (Tap to append):',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _quickCollectionPills.map((item) {
                return ActionChip(
                  backgroundColor: AppTheme.surfaceSubtle,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  label: Text(
                    '+ $item',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textMain),
                  ),
                  onPressed: () => _addCollectionItem(item),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _itemsController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Items Manifest to Retrieve *',
                hintText: 'e.g. 1x Pop-up Display Stand, 2x Rollup Banners, Unused POSM',
                prefixIcon: Icon(Icons.checklist_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepotAndNotesCard() {
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
                  child: const Icon(Icons.warehouse_rounded, size: 18, color: AppTheme.primary),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RETURN WAREHOUSE & INSTRUCTIONS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      'Destination warehouse and condition notes',
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

            // Destination Warehouse
            const Text(
              'Destination Storage Depot:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  'Main Warehouse - Al Quoz',
                  'Sharjah Depot Hub',
                  'Abu Dhabi Central Depot',
                  'Return Directly to Client',
                ].map((depot) {
                  final isSelected = _destinationDepot == depot;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        depot,
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
                        if (val) setState(() => _destinationDepot = depot);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _teardownNotesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Teardown & Handling Notes (Optional)',
                hintText: 'e.g. Carefully pack acrylic stand in original bubble wrap; verify store stamp',
                prefixIcon: Icon(Icons.note_alt_outlined, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
