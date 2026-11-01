import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/searchable_select_field.dart';

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
        const SnackBar(
          backgroundColor: AppTheme.danger,
          content: Text('Please enter Promoter Name'),
        ),
      );
      return;
    }

    if (_selectedProject == null || _selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.danger,
          content: Text('Please select Campaign Project and Store'),
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

    setState(() => _isSaving = false);

    if (badge != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.success,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Badge application for "$promoterName" submitted!'),
            ],
          ),
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.danger,
          content: Text('Failed to save badge application. Try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvasBg,
      appBar: AppBar(
        titleSpacing: 16,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Store Badge Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textMain, letterSpacing: -0.2)),
            Text('Permit Submission & Security Clearance', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: TextButton.icon(
              onPressed: _isSaving ? null : _handleSave,
              icon: _isSaving
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent))
                  : const Icon(Icons.check_rounded, size: 18),
              label: const Text('Save', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppTheme.borderSubtle)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _handleSave,
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.badge_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Submit Badge Application'),
                    ],
                  ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.infoBg,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(color: AppTheme.infoBorder),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.badge_outlined, color: AppTheme.accent, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Submit store permit application for hypermarkets. Track status through HR and Mall Security clearance.',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMain, height: 1.4, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 1: Promoter & Campaign Details
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        border: Border.all(color: AppTheme.borderSubtle, width: 1.1),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PROMOTER & CAMPAIGN',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 16),

                          // Promoter Name (Manual text input with suggestions)
                          Autocomplete<String>(
                            initialValue: TextEditingValue(text: _promoterNameController.text),
                            optionsBuilder: (textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return const Iterable<String>.empty();
                              }
                              return _promoters
                                  .map((p) => p.name)
                                  .where((name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                            },
                            onSelected: (selection) {
                              _promoterNameController.text = selection;
                            },
                            fieldViewBuilder: (ctx, controller, focusNode, onFieldSubmitted) {
                              controller.addListener(() {
                                _promoterNameController.text = controller.text;
                              });
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textMain),
                                decoration: const InputDecoration(
                                  labelText: 'Promoter Full Name *',
                                  hintText: 'Type promoter name (e.g. Sony Mathew)',
                                  prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),

                          // Project Dropdown
                          DropdownButtonFormField<ProjectModel>(
                            value: _selectedProject,
                            decoration: const InputDecoration(
                              labelText: 'Campaign / Project *',
                              prefixIcon: Icon(Icons.campaign_outlined, size: 20),
                            ),
                            items: _projects.map((p) {
                              return DropdownMenuItem(
                                value: p,
                                child: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedProject = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 2: Store & Emirate
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        border: Border.all(color: AppTheme.borderSubtle, width: 1.1),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'STORE LOCATION',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 16),

                          // Store searchable select
                          SearchableSelectField<StoreModel>(
                            label: 'Store Branch *',
                            value: _selectedStore,
                            options: _stores.map((s) => SearchableOption<StoreModel>(
                              value: s,
                              label: s.storeName,
                              subtitle: '${s.retailer} • ${s.emirate}',
                            )).toList(),
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
                          const SizedBox(height: 14),

                          // Emirate Dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedEmirate,
                            decoration: const InputDecoration(
                              labelText: 'Emirate *',
                              prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                            ),
                            items: _emirates.map((em) {
                              return DropdownMenuItem(
                                value: em,
                                child: Text(em, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedEmirate = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 3: Badge Status Lifecycle
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        border: Border.all(color: AppTheme.borderSubtle, width: 1.1),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BADGE STATUS LIFECYCLE',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 16),

                          DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Initial Clearance Status *',
                              prefixIcon: Icon(Icons.verified_outlined, size: 20),
                            ),
                            items: _statusOptions.map((st) {
                              return DropdownMenuItem(
                                value: st,
                                child: Text(st, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedStatus = val);
                            },
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: _submittedByController,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textMain),
                            decoration: const InputDecoration(
                              labelText: 'Submitted By',
                              hintText: 'Operations Lead Name',
                              prefixIcon: Icon(Icons.badge_outlined, size: 20),
                            ),
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: _badgeNumberController,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'monospace', color: AppTheme.textMain),
                            decoration: const InputDecoration(
                              labelText: 'Badge / Pass Number (Optional)',
                              hintText: 'e.g. LULU-DXB-9842',
                              prefixIcon: Icon(Icons.pin_outlined, size: 20),
                            ),
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: _notesController,
                            maxLines: 2,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textMain),
                            decoration: const InputDecoration(
                              labelText: 'Notes / Security Instructions',
                              hintText: 'e.g. Health card renewal submitted; awaiting CID clearance',
                              prefixIcon: Icon(Icons.note_alt_outlined, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
