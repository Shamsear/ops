import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
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

        if (_selectedSupervisor != null) {
          _selectedSupervisor = _supervisors.where((s) => s.id == _selectedSupervisor!.id).firstOrNull ??
              (_supervisors.isNotEmpty ? _supervisors.first : null);
        } else {
          _selectedSupervisor = _supervisors.isNotEmpty ? _supervisors.first : null;
        }
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
      _showWarning('Please specify items to collect and return');
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
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.inner)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Stand collection booked from ${_selectedStore!.storeName}!',
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
      _showWarning('Failed to schedule collection. Please try again.');
    }
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.inner)),
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppText.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      bottomClearance: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: 'Stand Collection',
      subtitle: 'Post-campaign equipment retrieval',
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: AppSpacing.sm),
          child: StatusBadge(
            label: 'Collection',
            variant: StatusVariant.info,
            showDot: true,
          ),
        ),
      ],
      floatingBottom: StickyActionBar(
        summaryText: _selectedStore != null
            ? '${_selectedStore!.retailer} • ${_selectedStore!.emirate} (${DateFormat("dd MMM").format(_collectionDate)})'
            : null,
        primaryLabel: _isSaving ? 'Dispatching...' : 'Dispatch Retrieval Task',
        primaryIcon: Icons.repeat_rounded,
        primaryLoading: _isSaving,
        onPrimaryPressed: _isSaving ? null : _handleSave,
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
                        icon: Icons.repeat_rounded,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Post-Campaign Material Retrieval', style: AppText.bodyBold),
                            const SizedBox(height: 2),
                            Text(
                              'Schedule stand dismantling and excess stock return with logistics team.',
                              style: AppText.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),

                // Section 1: Retrieval Store Location
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionHeader(
                        icon: Icons.storefront_rounded,
                        iconColor: AppColors.primary,
                        microLabel: 'RETRIEVAL VENUE',
                        title: 'Store Location for Pick-up',
                        trailing: TextButton.icon(
                          onPressed: () async {
                            final newStore = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CreateStorePage()),
                            );
                            if (newStore == true) _loadFormData();
                          },
                          icon: const Icon(Icons.add_rounded, size: 14, color: AppColors.accent),
                          label: Text(
                            'Store',
                            style: AppText.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SearchableSelectField<ProjectModel>(
                        label: 'Campaign Project *',
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
                                  '${_selectedStore!.retailer} • ${_selectedStore!.emirate} • Lead: ${_selectedStore!.smnContact ?? "Operations"}',
                                  style: AppText.caption.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 2,
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
                const SizedBox(height: AppSpacing.sectionGap),

                // Section 2: Retrieval Schedule & Driver
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(
                        icon: Icons.person_pin_circle_rounded,
                        iconColor: AppColors.accent,
                        microLabel: 'LOGISTICS ASSIGNMENT',
                        title: 'Assigned Driver & Date',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SearchableSelectField<UserModel>(
                        label: 'Assigned Supervisor (to Collect) *',
                        value: _selectedSupervisor,
                        options: _supervisors
                            .map((u) => SearchableOption<UserModel>(
                                  value: u,
                                  label: u.name,
                                  subtitle: '${u.phone} • ${u.role}',
                                ))
                            .toList(),
                        prefixIcon: const Icon(Icons.manage_accounts_outlined, size: 20),
                        onChanged: (u) => setState(() => _selectedSupervisor = u),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppDateField(
                        label: 'Target Collection Date *',
                        value: _collectionDate,
                        onChanged: (picked) => setState(() => _collectionDate = picked),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'RETURN DESTINATION DEPOT',
                        style: AppText.micro.copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'Main Warehouse - Al Quoz',
                          'Sharjah Depot',
                          'Abu Dhabi Hub',
                        ].map((depot) {
                          return FilterPill(
                            label: depot,
                            isSelected: _destinationDepot == depot,
                            onTap: () => setState(() => _destinationDepot = depot),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),

                // Section 3: Items to Collect
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(
                        icon: Icons.inventory_2_rounded,
                        iconColor: AppColors.accent,
                        microLabel: 'ITEMS TO RETRIEVE',
                        title: 'Equipment & Stock Recovery',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'QUICK ADD ITEMS (TAP TO APPEND)',
                        style: AppText.micro.copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _quickCollectionPills.map((item) {
                          return InkWell(
                            onTap: () => _addCollectionItem(item),
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add_rounded, size: 12, color: AppColors.accent),
                                  const SizedBox(width: 4),
                                  Text(
                                    item,
                                    style: AppText.caption.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _itemsController,
                        label: 'Detailed Items & Hardware to Retrieve *',
                        hint: 'e.g. 1x Pop-up Display Stand, 2x Rollup Banners, Unused POSM',
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),

                // Section 4: Teardown & Security Clearance Notes
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(
                        icon: Icons.assignment_turned_in_rounded,
                        iconColor: AppColors.accent,
                        microLabel: 'CLEARANCE NOTES',
                        title: 'Dismantling & Security Permit',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _teardownNotesController,
                        label: 'Teardown Instructions (Optional)',
                        hint: 'e.g. Collect after 10 PM mall closing; gate pass approval on file with store manager',
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
}
