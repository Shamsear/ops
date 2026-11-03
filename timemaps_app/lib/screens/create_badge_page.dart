import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class CreateBadgePage extends StatefulWidget {
  final int? preselectedStoreId;
  final int? preselectedProjectId;
  final String? preselectedPromoterName;

  const CreateBadgePage({
    super.key,
    this.preselectedStoreId,
    this.preselectedProjectId,
    this.preselectedPromoterName,
  });

  @override
  State<CreateBadgePage> createState() => _CreateBadgePageState();
}

class _CreateBadgePageState extends State<CreateBadgePage> {
  final _formKey = GlobalKey<FormState>();
  final _promoterNameController = TextEditingController();
  final _submittedByController = TextEditingController(text: 'Operations Lead');
  final _badgeNumberController = TextEditingController();
  final _notesController = TextEditingController();

  List<ProjectModel> _projects = [];
  List<StoreModel> _stores = [];
  List<PromoterModel> _promoters = [];

  ProjectModel? _selectedProject;
  StoreModel? _selectedStore;
  String _selectedEmirate = 'Dubai';
  String _selectedStatus = 'Documents ready for collection';
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _emirates = [
    'Dubai',
    'Abu Dhabi',
    'Sharjah',
    'Ajman',
    'Al Ain',
    'Ras Al Khaimah',
    'Fujairah',
  ];

  final List<String> _statusOptions = [
    'Documents ready for collection',
    'Submitted',
    'Pending with HR',
    'Pending with security',
    'Approved',
    'Rejected',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.preselectedPromoterName != null) {
      _promoterNameController.text = widget.preselectedPromoterName!;
    }
    _loadFormData();
  }

  @override
  void dispose() {
    _promoterNameController.dispose();
    _submittedByController.dispose();
    _badgeNumberController.dispose();
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
          _selectedProject = _projects.firstWhere(
            (p) => p.id == widget.preselectedProjectId,
            orElse: () => _projects.first,
          );
        } else if (_projects.isNotEmpty) {
          _selectedProject = _projects.first;
        }

        if (widget.preselectedStoreId != null) {
          _selectedStore = _stores.firstWhere(
            (s) => s.id == widget.preselectedStoreId,
            orElse: () => _stores.first,
          );
          _selectedEmirate = _selectedStore?.emirate ?? 'Dubai';
        } else if (_stores.isNotEmpty) {
          _selectedStore = _stores.first;
          _selectedEmirate = _selectedStore?.emirate ?? 'Dubai';
        }

        _isLoading = false;
      });
    }
  }

  Future<void> _handleSave() async {
    final promoterName = _promoterNameController.text.trim();
    if (promoterName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.inner)),
          content: Text(
            'Please enter Promoter Name',
            style: AppText.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    if (_selectedProject == null || _selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.inner)),
          content: Text(
            'Please select Campaign Project and Store',
            style: AppText.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final matchedPromoter = _promoters.where(
      (p) => p.name.trim().toLowerCase() == promoterName.toLowerCase(),
    ).firstOrNull;

    final badge = await ApiService.createBadge(
      promoterName: promoterName,
      promoterId: matchedPromoter?.id,
      projectId: _selectedProject!.id,
      storeId: _selectedStore!.id,
      emirate: _selectedEmirate,
      status: _selectedStatus,
      submittedBy: _submittedByController.text.trim().isEmpty ? 'Operations' : _submittedByController.text.trim(),
      badgeNumber: _badgeNumberController.text.trim().isEmpty ? null : _badgeNumberController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (badge != null) {
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
                  'Badge application for "$promoterName" submitted! 🪪',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.inner)),
          content: Text(
            'Failed to save badge application. Try again.',
            style: AppText.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      bottomClearance: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: 'Store Badge Application',
      subtitle: 'Permit submission & security clearance',
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: AppSpacing.sm),
          child: StatusBadge(
            label: 'Permit',
            variant: StatusVariant.neutral,
            showDot: false,
          ),
        ),
      ],
      floatingBottom: StickyActionBar(
        primaryLabel: _isSaving ? 'Submitting...' : 'Submit Badge Application',
        primaryIcon: Icons.badge_rounded,
        primaryLoading: _isSaving,
        onPrimaryPressed: _isSaving ? null : _handleSave,
      ),
      body: _isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Info banner
                  AppCard.flat(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        const IconBox(
                          icon: Icons.badge_outlined,
                          color: AppColors.purple,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Store Security Permit Application', style: AppText.bodyBold),
                              const SizedBox(height: 2),
                              Text(
                                'Submit store permit application for hypermarkets. Track status through HR and Security clearance.',
                                style: AppText.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),

                  // Card 1: Promoter & Campaign
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionHeader(
                          icon: Icons.person_pin_circle_rounded,
                          iconColor: AppColors.primary,
                          microLabel: 'PROMOTER & CAMPAIGN',
                          title: 'Staff Identity & Activation',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SearchableSelectField<String>(
                          label: 'Promoter Full Name *',
                          value: _promoterNameController.text.isEmpty ? null : _promoterNameController.text,
                          hintText: 'Select or type promoter name',
                          allowCustomValue: true,
                          prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: AppColors.primary),
                          options: _promoters
                              .map((p) => SearchableOption<String>(
                                    value: p.name,
                                    label: p.name,
                                    subtitle: '${p.phone} • ${p.nationality ?? "Staff"}',
                                  ))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _promoterNameController.text = val);
                            }
                          },
                          onCustomValueSubmitted: (val) {
                            setState(() => _promoterNameController.text = val);
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SearchableSelectField<ProjectModel>(
                          label: 'Campaign / Project *',
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
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),

                  // Card 2: Store & Emirate
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionHeader(
                          icon: Icons.storefront_rounded,
                          iconColor: AppColors.accent,
                          microLabel: 'STORE LOCATION',
                          title: 'Branch & Location',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SearchableSelectField<StoreModel>(
                          label: 'Store Branch *',
                          value: _selectedStore,
                          options: _stores
                              .map((s) => SearchableOption<StoreModel>(
                                    value: s,
                                    label: s.storeName,
                                    subtitle: '${s.retailer} • ${s.emirate}',
                                  ))
                              .toList(),
                          prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
                          onChanged: (store) {
                            setState(() {
                              _selectedStore = store;
                              if (store != null) {
                                _selectedEmirate = store.emirate;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SearchableSelectField<String>(
                          label: 'Emirate *',
                          value: _selectedEmirate,
                          prefixIcon: const Icon(Icons.location_on_outlined, size: 20, color: AppColors.accent),
                          options: _emirates
                              .map((em) => SearchableOption<String>(value: em, label: em))
                              .toList(),
                          onChanged: (em) {
                            if (em != null) {
                              setState(() => _selectedEmirate = em);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),

                  // Card 3: Badge Status Lifecycle
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SectionHeader(
                          icon: Icons.verified_outlined,
                          iconColor: AppColors.success,
                          microLabel: 'PERMIT LIFECYCLE',
                          title: 'Clearance Status & Pass No.',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SearchableSelectField<String>(
                          label: 'Initial Clearance Status *',
                          value: _selectedStatus,
                          prefixIcon: const Icon(Icons.check_circle_outline_rounded, size: 20, color: AppColors.success),
                          options: _statusOptions
                              .map((st) => SearchableOption<String>(value: st, label: st))
                              .toList(),
                          onChanged: (st) {
                            if (st != null) {
                              setState(() => _selectedStatus = st);
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 340) {
                              return Column(
                                children: [
                                  AppTextField(
                                    controller: _submittedByController,
                                    label: 'Submitted By',
                                    hint: 'Operations Lead Name',
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  AppTextField(
                                    controller: _badgeNumberController,
                                    label: 'Badge / Pass Number (Optional)',
                                    hint: 'e.g. LULU-DXB-9842',
                                  ),
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    controller: _submittedByController,
                                    label: 'Submitted By',
                                    hint: 'Operations Lead Name',
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm + 2),
                                Expanded(
                                  child: AppTextField(
                                    controller: _badgeNumberController,
                                    label: 'Badge Number (Optional)',
                                    hint: 'e.g. LULU-DXB-9842',
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _notesController,
                          label: 'Notes / Security Instructions',
                          hint: 'e.g. Health card renewal submitted; awaiting CID clearance',
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sectionGap),
                ],
              ),
            ),
    );
  }
}
