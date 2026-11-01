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
        const SnackBar(content: Text('Please enter Promoter Name')),
      );
      return;
    }

    if (_selectedProject == null || _selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Campaign Project and Store')),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Try finding promoter id if exact match
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
        SnackBar(content: Text('Badge application for "$promoterName" created!')),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save badge application. Try again.')),
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
            Text('Store Badge Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textMain)),
            Text('Permit Submission & Security Clearance', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _isSaving ? null : _handleSave,
              icon: _isSaving
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
                  : const Icon(Icons.check_rounded, size: 18),
              label: const Text('Save', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.badge_outlined, color: AppTheme.primary, size: 22),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Submit store permit application for hypermarkets. Track status through HR and Mall Security clearance.',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMain, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 1: Promoter & Campaign Details
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PROMOTER & CAMPAIGN',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 14),

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
                                  child: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedProject = val),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Card 2: Store & Emirate
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'STORE LOCATION',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 14),

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
                                  child: Text(em, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedEmirate = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Card 3: Badge Status & Submission Journey
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BADGE STATUS LIFECYCLE',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 14),

                            DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              decoration: const InputDecoration(
                                labelText: 'Current Badge Status *',
                                prefixIcon: Icon(Icons.verified_outlined, size: 20),
                              ),
                              items: _statusOptions.map((st) {
                                return DropdownMenuItem(
                                  value: st,
                                  child: Text(st, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedStatus = val);
                              },
                            ),
                            const SizedBox(height: 14),

                            // Submitter Name
                            TextField(
                              controller: _submittedByController,
                              decoration: const InputDecoration(
                                labelText: 'Submitted By',
                                hintText: 'Name of person submitting permit',
                                prefixIcon: Icon(Icons.badge_outlined, size: 20),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Badge / Pass Number (optional)
                            TextField(
                              controller: _badgeNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Badge / Pass Number (Optional)',
                                hintText: 'e.g. LULU-DXB-9842',
                                prefixIcon: Icon(Icons.pin_outlined, size: 20),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Notes
                            TextField(
                              controller: _notesController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Notes / Security Instructions',
                                hintText: 'e.g. Health card renewal submitted; awaiting CID clearance',
                                prefixIcon: Icon(Icons.note_alt_outlined, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Primary Save Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: _isSaving ? null : _handleSave,
                      child: _isSaving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Submit Badge Application', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
