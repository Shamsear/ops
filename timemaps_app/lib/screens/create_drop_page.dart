import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
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
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.inner)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Morning Drop dispatched to ${_selectedStore!.storeName}!',
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
      _showWarning('Failed to dispatch drop. Please try again.');
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
      title: 'Morning Drop-off',
      subtitle: 'Dispatch POSM & stands to venue',
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: AppSpacing.sm),
          child: StatusBadge(
            label: 'Drop-off',
            variant: StatusVariant.warning,
            showDot: true,
          ),
        ),
      ],
      floatingBottom: StickyActionBar(
        summaryText: _selectedStore != null
            ? '${_selectedStore!.retailer} • ${_selectedStore!.emirate} (${DateFormat("dd MMM").format(_dropDate)})'
            : null,
        primaryLabel: _isSaving ? 'Dispatching...' : 'Dispatch Drop Task',
        primaryIcon: Icons.local_shipping_rounded,
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
                        icon: Icons.local_shipping_rounded,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Morning Stand & Material Drop-off', style: AppText.bodyBold),
                            const SizedBox(height: 2),
                            Text(
                              'Assign promotional stands, rollups, and stock to field supervisor.',
                              style: AppText.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),

                // Section 1: Venue & Campaign Selection
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionHeader(
                        icon: Icons.storefront_rounded,
                        iconColor: AppColors.primary,
                        microLabel: 'DESTINATION VENUE',
                        title: 'Store Receiving Delivery',
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
                        label: 'Destination Store *',
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

                // Section 2: Logistics Driver & Scheduled Date
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(
                        icon: Icons.person_pin_circle_rounded,
                        iconColor: AppColors.accent,
                        microLabel: 'DISPATCH & TIMELINE',
                        title: 'Assigned Driver & Date',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SearchableSelectField<UserModel>(
                        label: 'Assigned Supervisor (to Deliver) *',
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
                        label: 'Scheduled Drop-off Date *',
                        value: _dropDate,
                        onChanged: (picked) => setState(() => _dropDate = picked),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'DELIVERY PRIORITY WINDOW',
                        style: AppText.micro.copyWith(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'Standard Morning',
                          'Urgent Pre-Opening',
                          'Mid-day Restock',
                        ].map((p) {
                          return FilterPill(
                            label: p,
                            isSelected: _priority == p,
                            onTap: () => setState(() => _priority = p),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),

                // Section 3: Items Manifest to Deliver
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(
                        icon: Icons.inventory_2_rounded,
                        iconColor: AppColors.warning,
                        microLabel: 'ITEMS MANIFEST',
                        title: 'Equipment & Stock Kits',
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
                        children: _quickManifestPills.map((item) {
                          return InkWell(
                            onTap: () => _addManifestItem(item),
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
                        controller: _manifestController,
                        label: 'Detailed Manifest & Items List *',
                        hint: 'e.g. 1x Pop-up Display Stand, 2x Rollup Banners, 5x Sampling Cartons',
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),

                // Section 4: Loading Bay & Store Access Instructions
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(
                        icon: Icons.assignment_turned_in_rounded,
                        iconColor: AppColors.accent,
                        microLabel: 'ACCESS INSTRUCTIONS',
                        title: 'Loading Bay & Security Gate',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _accessNotesController,
                        label: 'Access Instructions (Optional)',
                        hint: 'e.g. Enter via Loading Bay 3; present Hypermarket gate pass at security desk',
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
