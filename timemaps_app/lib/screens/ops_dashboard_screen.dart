import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'timemap_calendar_screen.dart';
import 'login_screen.dart';
import 'create_schedule_page.dart';
import 'create_store_page.dart';
import 'create_promoter_page.dart';
import 'create_project_page.dart';
import 'create_badge_page.dart';
import 'badge_tracker_screen.dart';
import 'store_management_screen.dart';
import '../widgets/searchable_select_field.dart';


class OpsDashboardScreen extends StatefulWidget {
  const OpsDashboardScreen({super.key});

  @override
  State<OpsDashboardScreen> createState() => _OpsDashboardScreenState();
}

class _OpsDashboardScreenState extends State<OpsDashboardScreen> {
  String _selectedEmirate = 'All';
  final DateTime _selectedDate = DateTime(2026, 10, 14);
  bool _isLoading = true;
  Map<String, dynamic> _kpis = {};
  List<LiveStoreHub> _liveStores = [];

  final List<String> _emirates = [
    'All',
    'Dubai',
    'Abu Dhabi',
    'Sharjah',
    'Ajman',
    'Al Ain',
    'Ras Al Khaimah',
    'Fujairah',
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final data = await ApiService.getLiveDashboard(
      date: dateStr,
      emirate: _selectedEmirate,
    );

    if (mounted) {
      setState(() {
        _kpis = data['kpis'] ?? {};
        _liveStores = data['live_stores'] ?? [];
        _isLoading = false;
      });
    }
  }

  void _onEmirateSelected(String emirate) {
    setState(() {
      _selectedEmirate = emirate;
    });
    _loadDashboardData();
  }

  // ==============================================
  // MASTER DATA MODAL 1: CREATE CAMPAIGN / PROJECT
  // ==============================================
  Future<ProjectModel?> _showCreateProjectModal() async {
    final nameController = TextEditingController();
    final clientController = TextEditingController();
    DateTime startDate = _selectedDate;
    DateTime endDate = _selectedDate.add(const Duration(days: 30));
    bool isSaving = false;

    return showModalBottomSheet<ProjectModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.campaign_outlined, color: AppTheme.primary, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'New Campaign / Project',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textMain),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Campaign / Project Name *',
                    hintText: 'e.g. Sadia In-Store Sampling Q4',
                    prefixIcon: Icon(Icons.folder_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: clientController,
                  decoration: const InputDecoration(
                    labelText: 'Client / Brand Name *',
                    hintText: 'e.g. Sadia, L\'Oreal, Nestle',
                    prefixIcon: Icon(Icons.business_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: startDate,
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setModalState(() => startDate = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Date',
                            prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                          ),
                          child: Text(DateFormat('yyyy-MM-dd').format(startDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: endDate,
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setModalState(() => endDate = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Date',
                            prefixIcon: Icon(Icons.event_outlined, size: 18),
                          ),
                          child: Text(DateFormat('yyyy-MM-dd').format(endDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    final name = nameController.text.trim();
                    final client = clientController.text.trim();
                    if (name.isEmpty || client.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter Campaign Name and Client Name')),
                      );
                      return;
                    }
                    setModalState(() => isSaving = true);
                    final project = await ApiService.createProject(
                      name: name,
                      clientName: client,
                      startDate: DateFormat('yyyy-MM-dd').format(startDate),
                      endDate: DateFormat('yyyy-MM-dd').format(endDate),
                    );
                    if (project != null && mounted) {
                      Navigator.pop(ctx, project);
                      _loadDashboardData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Campaign "${project.name}" created successfully!')),
                      );
                    } else {
                      setModalState(() => isSaving = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to create campaign. Please try again.')),
                      );
                    }
                  },
                  child: isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Create Campaign Project'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================
  // MASTER DATA MODAL 2: CREATE STORE LOCATION
  // ==============================================
  Future<StoreModel?> _showCreateStoreModal() async {
    final storeNameController = TextEditingController();
    final retailerController = TextEditingController(text: 'Carrefour');
    final branchCodeController = TextEditingController();
    final locationController = TextEditingController();
    final contactPersonController = TextEditingController();
    final contactPhoneController = TextEditingController();
    String selectedEmirate = _selectedEmirate == 'All' ? 'Dubai' : _selectedEmirate;
    bool isSaving = false;

    final retailers = ['Carrefour', 'Lulu Hypermarket', 'Spinneys', 'Choithrams', 'Union Coop', 'Geant'];

    return showModalBottomSheet<StoreModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.storefront_outlined, color: AppTheme.primary, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'New Store Location',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textMain),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: storeNameController,
                  decoration: const InputDecoration(
                    labelText: 'Store Branch Name *',
                    hintText: 'e.g. Carrefour Mall of the Emirates',
                    prefixIcon: Icon(Icons.store_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: retailerController,
                        decoration: const InputDecoration(
                          labelText: 'Retailer Chain *',
                          hintText: 'Carrefour, Lulu, etc.',
                          prefixIcon: Icon(Icons.shopping_bag_outlined, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: selectedEmirate,
                        isDense: true,
                        decoration: const InputDecoration(
                          labelText: 'Emirate *',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        ),
                        items: _emirates.where((e) => e != 'All').map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => selectedEmirate = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: retailers.map((r) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(r, style: const TextStyle(fontSize: 11)),
                        backgroundColor: retailerController.text == r ? AppTheme.surfaceSubtle : Colors.white,
                        onPressed: () {
                          setModalState(() => retailerController.text = r);
                        },
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: branchCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Branch Code (Opt)',
                          hintText: 'e.g. MOE-01',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: contactPersonController,
                        decoration: const InputDecoration(
                          labelText: 'Store Manager (Opt)',
                          hintText: 'e.g. John Doe',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location / Address (Opt)',
                    hintText: 'e.g. Ground Floor, Sheikh Zayed Road',
                    prefixIcon: Icon(Icons.pin_drop_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contactPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone (Opt)',
                    hintText: 'e.g. +971 4 123 4567',
                    prefixIcon: Icon(Icons.phone_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    final sName = storeNameController.text.trim();
                    final ret = retailerController.text.trim();
                    if (sName.isEmpty || ret.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill Store Name and Retailer')),
                      );
                      return;
                    }
                    setModalState(() => isSaving = true);
                    final store = await ApiService.createStore(
                      storeName: sName,
                      retailer: ret,
                      emirate: selectedEmirate,
                      branchCode: branchCodeController.text.trim().isEmpty ? null : branchCodeController.text.trim(),
                      locationAddress: locationController.text.trim().isEmpty ? null : locationController.text.trim(),
                      contactPerson: contactPersonController.text.trim().isEmpty ? null : contactPersonController.text.trim(),
                      contactPhone: contactPhoneController.text.trim().isEmpty ? null : contactPhoneController.text.trim(),
                    );
                    if (store != null && mounted) {
                      Navigator.pop(ctx, store);
                      _loadDashboardData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Store "${store.storeName}" created successfully!')),
                      );
                    } else {
                      setModalState(() => isSaving = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to create store. Please check server.')),
                      );
                    }
                  },
                  child: isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Create Store Location'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================
  // MASTER DATA MODAL 3: REGISTER NEW PROMOTER
  // ==============================================
  Future<PromoterModel?> _showCreatePromoterModal() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController(text: '+971 ');
    final emailController = TextEditingController();
    final nationalityController = TextEditingController(text: 'Filipino');
    String gender = 'FEMALE';
    bool isSaving = false;

    final popularNationalities = ['Filipino', 'Indian', 'Pakistani', 'Emirati', 'Egyptian', 'Moroccan'];

    return showModalBottomSheet<PromoterModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.badge_outlined, color: AppTheme.primary, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Register New Promoter',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textMain),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'e.g. Maria Santos',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Phone *',
                    hintText: '+971 50 123 4567',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address (Opt)',
                    hintText: 'maria.s@imlme.com',
                    prefixIcon: Icon(Icons.email_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Gender *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              ChoiceChip(
                                label: const Text('Female'),
                                selected: gender == 'FEMALE',
                                onSelected: (sel) {
                                  if (sel) setModalState(() => gender = 'FEMALE');
                                },
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('Male'),
                                selected: gender == 'MALE',
                                onSelected: (sel) {
                                  if (sel) setModalState(() => gender = 'MALE');
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: nationalityController,
                        decoration: const InputDecoration(
                          labelText: 'Nationality',
                          hintText: 'Filipino, Indian, etc.',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: popularNationalities.map((nat) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(nat, style: const TextStyle(fontSize: 11)),
                        backgroundColor: nationalityController.text == nat ? AppTheme.surfaceSubtle : Colors.white,
                        onPressed: () {
                          setModalState(() => nationalityController.text = nat);
                        },
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    final name = nameController.text.trim();
                    final phone = phoneController.text.trim();
                    if (name.isEmpty || phone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter Full Name and Phone Number')),
                      );
                      return;
                    }
                    setModalState(() => isSaving = true);
                    final promoter = await ApiService.createPromoter(
                      name: name,
                      phone: phone,
                      email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                      gender: gender,
                      nationality: nationalityController.text.trim().isEmpty ? null : nationalityController.text.trim(),
                    );
                    if (promoter != null && mounted) {
                      Navigator.pop(ctx, promoter);
                      _loadDashboardData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Promoter "${promoter.name}" registered successfully!')),
                      );
                    } else {
                      setModalState(() => isSaving = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to register promoter. Please try again.')),
                      );
                    }
                  },
                  child: isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Register Promoter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================
  // MODAL 4: FAST IN-APP SCHEDULE CREATOR
  // ==============================================
  void _showCreateScheduleModal() async {
    List<ProjectModel> projects = await ApiService.getProjects();
    List<StoreModel> stores = await ApiService.getStores();
    List<PromoterModel> promoters = await ApiService.getPromoters();
    List<UserModel> supervisors = await ApiService.getSupervisors();

    if (!mounted) return;

    int? selectedProjectId = projects.isNotEmpty ? projects.first.id : null;
    int? selectedStoreId = stores.isNotEmpty ? stores.first.id : null;
    int? selectedPromoterId = promoters.isNotEmpty ? promoters.first.id : null;
    int? selectedSupervisorId = supervisors.isNotEmpty ? supervisors.first.id : null;

    final startTimeController = TextEditingController(text: '14:00:00');
    final endTimeController = TextEditingController(text: '22:00:00');
    final breakController = TextEditingController(text: '5:00 PM - 5:45 PM');
    
    List<DateTime> selectedDays = [
      _selectedDate,
      _selectedDate.add(const Duration(days: 1)),
      _selectedDate.add(const Duration(days: 2)),
      _selectedDate.add(const Duration(days: 3)),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Create Store Schedule',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textMain),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Project
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Campaign Project', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                    InkWell(
                      onTap: () async {
                        final newProj = await _showCreateProjectModal();
                        if (newProj != null) {
                          final updated = await ApiService.getProjects();
                          setModalState(() {
                            projects = updated;
                            selectedProjectId = newProj.id;
                          });
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                        child: Text('+ New Campaign', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SearchableSelectField<int>(
                  label: '',
                  hintText: 'Select Campaign Project',
                  value: selectedProjectId,
                  options: projects.map((p) => SearchableOption<int>(
                    value: p.id,
                    label: p.name,
                    subtitle: 'Client: ${p.clientName}',
                  )).toList(),
                  onChanged: (val) => setModalState(() => selectedProjectId = val),
                ),
                const SizedBox(height: 12),

                // Store
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Store & Retailer Location', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                    InkWell(
                      onTap: () async {
                        final newStore = await _showCreateStoreModal();
                        if (newStore != null) {
                          final updated = await ApiService.getStores();
                          setModalState(() {
                            stores = updated;
                            selectedStoreId = newStore.id;
                          });
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                        child: Text('+ New Store', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SearchableSelectField<int>(
                  label: '',
                  hintText: 'Select Store & Retailer Location',
                  value: selectedStoreId,
                  options: stores.map((s) => SearchableOption<int>(
                    value: s.id,
                    label: s.storeName,
                    subtitle: '${s.emirate} • Retailer: ${s.retailer}',
                  )).toList(),
                  onChanged: (val) => setModalState(() => selectedStoreId = val),
                ),
                const SizedBox(height: 12),

                // Promoter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('IML Promoter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                    InkWell(
                      onTap: () async {
                        final newPromoter = await _showCreatePromoterModal();
                        if (newPromoter != null) {
                          final updated = await ApiService.getPromoters();
                          setModalState(() {
                            promoters = updated;
                            selectedPromoterId = newPromoter.id;
                          });
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                        child: Text('+ New Promoter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SearchableSelectField<int>(
                  label: '',
                  hintText: 'Select IML Promoter',
                  value: selectedPromoterId,
                  options: promoters.map((pr) => SearchableOption<int>(
                    value: pr.id,
                    label: pr.name,
                    subtitle: 'Phone: ${pr.phone}',
                  )).toList(),
                  onChanged: (val) => setModalState(() => selectedPromoterId = val),
                ),
                const SizedBox(height: 12),

                // Supervisor
                SearchableSelectField<int>(
                  label: 'Assigned Field Supervisor',
                  value: selectedSupervisorId,
                  options: supervisors.map((u) => SearchableOption<int>(
                    value: u.id,
                    label: u.name,
                    subtitle: u.email,
                  )).toList(),
                  onChanged: (val) => setModalState(() => selectedSupervisorId = val),
                ),
                const SizedBox(height: 12),

                // Timings
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startTimeController,
                        decoration: const InputDecoration(labelText: 'Start Time (14:00)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: endTimeController,
                        decoration: const InputDecoration(labelText: 'End Time (22:00)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: breakController,
                  decoration: const InputDecoration(labelText: 'Break Rotation (5:00 PM - 5:45 PM)'),
                ),
                const SizedBox(height: 16),

                // Scheduled Days chips
                const Text('Active Shift Days:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textMain)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: selectedDays.map((d) {
                    final dayStr = DateFormat('E dd-MMM').format(d);
                    return Chip(
                      label: Text(dayStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      backgroundColor: AppTheme.surfaceSubtle,
                      side: const BorderSide(color: AppTheme.borderSubtle),
                      deleteIcon: const Icon(Icons.close_rounded, size: 14),
                      onDeleted: () {
                        setModalState(() {
                          selectedDays.remove(d);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async {
                    if (selectedProjectId == null || selectedStoreId == null || selectedPromoterId == null || selectedSupervisorId == null || selectedDays.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                      return;
                    }

                    final datesStr = selectedDays.map((d) => DateFormat('yyyy-MM-dd').format(d)).toList();
                    final success = await ApiService.createSchedule(
                      projectId: selectedProjectId!,
                      storeId: selectedStoreId!,
                      promoterId: selectedPromoterId!,
                      supervisorId: selectedSupervisorId!,
                      dates: datesStr,
                      startTime: startTimeController.text.trim(),
                      endTime: endTimeController.text.trim(),
                      breakTimings: breakController.text.trim(),
                    );

                    if (success && mounted) {
                      Navigator.pop(ctx);
                      _loadDashboardData();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schedule published to Cloud DB!')));
                    }
                  },
                  child: const Text('Save & Publish Schedule'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================
  // MODAL 2: ASSIGN MORNING LOGISTICS DROP
  // ==============================================
  void _showAssignDropModal() async {
    List<ProjectModel> projects = await ApiService.getProjects();
    List<StoreModel> stores = await ApiService.getStores();
    List<UserModel> supervisors = await ApiService.getSupervisors();

    if (!mounted) return;

    int? selectedProjectId = projects.isNotEmpty ? projects.first.id : null;
    int? selectedStoreId = stores.isNotEmpty ? stores.first.id : null;
    int? selectedSupervisorId = supervisors.isNotEmpty ? supervisors.first.id : null;
    final manifestController = TextEditingController(text: '1x Pop-up Display Stand, 2x Rollups, 5x Cartons');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Assign Morning Drop-off', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textMain)),
                    IconButton(icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),

                // Project
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Campaign Project', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                    InkWell(
                      onTap: () async {
                        final newProj = await _showCreateProjectModal();
                        if (newProj != null) {
                          final updated = await ApiService.getProjects();
                          setModalState(() {
                            projects = updated;
                            selectedProjectId = newProj.id;
                          });
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                        child: Text('+ New Campaign', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SearchableSelectField<int>(
                  label: 'Campaign Project',
                  value: selectedProjectId,
                  options: projects.map((p) => SearchableOption<int>(
                    value: p.id,
                    label: p.name,
                    subtitle: 'Client: ${p.clientName}',
                  )).toList(),
                  onChanged: (val) => setModalState(() => selectedProjectId = val),
                ),
                const SizedBox(height: 12),

                // Store
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Destination Store', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                    InkWell(
                      onTap: () async {
                        final newStore = await _showCreateStoreModal();
                        if (newStore != null) {
                          final updated = await ApiService.getStores();
                          setModalState(() {
                            stores = updated;
                            selectedStoreId = newStore.id;
                          });
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                        child: Text('+ New Store', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SearchableSelectField<int>(
                  label: 'Destination Store',
                  value: selectedStoreId,
                  options: stores.map((s) => SearchableOption<int>(
                    value: s.id,
                    label: s.storeName,
                    subtitle: '${s.emirate} • Retailer: ${s.retailer}',
                  )).toList(),
                  onChanged: (val) => setModalState(() => selectedStoreId = val),
                ),
                const SizedBox(height: 12),

                SearchableSelectField<int>(
                  label: 'Assigned Supervisor (to Deliver)',
                  value: selectedSupervisorId,
                  options: supervisors.map((u) => SearchableOption<int>(
                    value: u.id,
                    label: u.name,
                    subtitle: u.email,
                  )).toList(),
                  onChanged: (val) => setModalState(() => selectedSupervisorId = val),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: manifestController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Items Manifest to Deliver'),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentAmber),
                  onPressed: () async {
                    if (selectedProjectId == null || selectedStoreId == null || selectedSupervisorId == null) return;
                    final success = await ApiService.createDrop(
                      projectId: selectedProjectId!,
                      storeId: selectedStoreId!,
                      supervisorId: selectedSupervisorId!,
                      scheduledDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
                      itemsManifest: manifestController.text.trim(),
                    );

                    if (success && mounted) {
                      Navigator.pop(ctx);
                      _loadDashboardData();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Morning Drop dispatched!')));
                    }
                  },
                  child: const Text('Dispatch Drop Task'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================
  // MODAL 3: ASSIGN RETURN COLLECTION (SEPARATE!)
  // ==============================================
  void _showAssignCollectionModal() async {
    List<ProjectModel> projects = await ApiService.getProjects();
    List<StoreModel> stores = await ApiService.getStores();
    List<UserModel> supervisors = await ApiService.getSupervisors();

    if (!mounted) return;

    int? selectedProjectId = projects.isNotEmpty ? projects.first.id : null;
    int? selectedStoreId = stores.isNotEmpty ? stores.first.id : null;
    int? selectedSupervisorId = supervisors.isNotEmpty ? supervisors.first.id : null;
    final itemsController = TextEditingController(text: '1x Pop-up Display Stand, 2x Rollups');
    DateTime collectionDate = _selectedDate.add(const Duration(days: 4));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Assign Return Collection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textMain)),
                    IconButton(icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),

                // Project
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Campaign Project', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                    InkWell(
                      onTap: () async {
                        final newProj = await _showCreateProjectModal();
                        if (newProj != null) {
                          final updated = await ApiService.getProjects();
                          setModalState(() {
                            projects = updated;
                            selectedProjectId = newProj.id;
                          });
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                        child: Text('+ New Campaign', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SearchableSelectField<int>(
                  label: 'Campaign Project',
                  value: selectedProjectId,
                  options: projects.map((p) => SearchableOption<int>(
                    value: p.id,
                    label: p.name,
                    subtitle: 'Client: ${p.clientName}',
                  )).toList(),
                  onChanged: (val) => setModalState(() => selectedProjectId = val),
                ),
                const SizedBox(height: 12),

                // Store
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Store Location to Collect From', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                    InkWell(
                      onTap: () async {
                        final newStore = await _showCreateStoreModal();
                        if (newStore != null) {
                          final updated = await ApiService.getStores();
                          setModalState(() {
                            stores = updated;
                            selectedStoreId = newStore.id;
                          });
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                        child: Text('+ New Store', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SearchableSelectField<int>(
                  label: 'Store Location to Collect From',
                  value: selectedStoreId,
                  options: stores.map((s) => SearchableOption<int>(
                    value: s.id,
                    label: s.storeName,
                    subtitle: '${s.emirate} • Retailer: ${s.retailer}',
                  )).toList(),
                  onChanged: (val) => setModalState(() => selectedStoreId = val),
                ),
                const SizedBox(height: 12),

                SearchableSelectField<int>(
                  label: 'Assigned Field Supervisor (to Collect)',
                  value: selectedSupervisorId,
                  options: supervisors.map((u) => SearchableOption<int>(
                    value: u.id,
                    label: u.name,
                    subtitle: u.email,
                  )).toList(),
                  onChanged: (val) => setModalState(() => selectedSupervisorId = val),
                ),
                const SizedBox(height: 12),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Collection Date: ${DateFormat('EEE, dd-MMM-yyyy').format(collectionDate)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  trailing: TextButton(
                    child: const Text('Change Date'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: collectionDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 90)),
                      );
                      if (picked != null) {
                        setModalState(() => collectionDate = picked);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: itemsController,
                  decoration: const InputDecoration(labelText: 'Items to Collect Back to Base'),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentEmerald),
                  onPressed: () async {
                    if (selectedProjectId == null || selectedStoreId == null || selectedSupervisorId == null) return;
                    final success = await ApiService.createCollection(
                      projectId: selectedProjectId!,
                      storeId: selectedStoreId!,
                      supervisorId: selectedSupervisorId!,
                      scheduledDate: DateFormat('yyyy-MM-dd').format(collectionDate),
                      itemsToCollect: itemsController.text.trim(),
                    );

                    if (success && mounted) {
                      Navigator.pop(ctx);
                      _loadDashboardData();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Collection task scheduled!')));
                    }
                  },
                  child: const Text('Save Collection Assignment'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================
  // MODAL 4: IN-STORE PROMOTER AUDIT SCORECARD
  // ==============================================
  void _showEvaluationModal(String promoterName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Promoter Audit Scorecard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textMain)),
                      Text('Evaluating: $promoterName', style: const TextStyle(fontSize: 13, color: AppTheme.accent, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),

              _buildEvaluationCriteria('Clean Branded Uniform', 'Badge visible & tidy hygiene', 5),
              const SizedBox(height: 8),
              _buildEvaluationCriteria('Product Pitch & Knowledge', 'Accurate benefits explanation', 5),
              const SizedBox(height: 8),
              _buildEvaluationCriteria('Shopper Engagement', 'Active standing & proactive sampling', 4),
              const SizedBox(height: 16),

              const TextField(
                decoration: InputDecoration(
                  labelText: 'Supervisor Coaching Note',
                  hintText: 'Grooming perfect, active customer sampling.',
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Audit for $promoterName submitted successfully! (4.8 ⭐)')),
                  );
                },
                child: const Text('Submit Scorecard (4.8 ⭐)'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEvaluationCriteria(String title, String subtitle, int stars) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textMain)),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                Icons.star_rounded,
                size: 18,
                color: index < stars ? const Color(0xFFF59E0B) : const Color(0xFFD1D1C8),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateDisplay = DateFormat('EEE, dd MMM yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TimeMaps™ Ops Command', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textMain)),
            Text(dateDisplay, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.storefront_outlined),
            tooltip: 'Store Directory & Chains',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreManagementScreen())).then((_) => _loadDashboardData());
            },
          ),
          IconButton(
            icon: const Icon(Icons.badge_outlined),
            tooltip: 'Store Badge Tracker',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BadgeTrackerScreen()));
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
            tooltip: 'Create New...',
            onSelected: (val) {
              if (val == 'schedule') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateSchedulePage())).then((_) => _loadDashboardData());
              }
              if (val == 'badge') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateBadgePage())).then((_) => _loadDashboardData());
              }
              if (val == 'project') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateProjectPage())).then((_) => _loadDashboardData());
              }
              if (val == 'store') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateStorePage())).then((_) => _loadDashboardData());
              }
              if (val == 'promoter') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePromoterPage())).then((_) => _loadDashboardData());
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'schedule',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, size: 18, color: AppTheme.primary),
                    SizedBox(width: 10),
                    Text('Batch Schedule Shifts'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'badge',
                child: Row(
                  children: [
                    Icon(Icons.badge_outlined, size: 18, color: AppTheme.primary),
                    SizedBox(width: 10),
                    Text('Store Badge Permit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'project',
                child: Row(
                  children: [
                    Icon(Icons.campaign_outlined, size: 18, color: AppTheme.primary),
                    SizedBox(width: 10),
                    Text('New Campaign Project'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'store',
                child: Row(
                  children: [
                    Icon(Icons.storefront_outlined, size: 18, color: AppTheme.primary),
                    SizedBox(width: 10),
                    Text('New Store Location'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'promoter',
                child: Row(
                  children: [
                    Icon(Icons.person_add_alt_outlined, size: 18, color: AppTheme.primary),
                    SizedBox(width: 10),
                    Text('Register Promoter'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Master TimeMap Calendar',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TimeMapCalendarScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Roster',
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                children: [
                  // KPI Section
                  _buildKpiSection(),
                  const SizedBox(height: 14),

                  // Quick Action Buttons (Zero-Overflow Scrollable Bar)
                  _buildQuickActionButtons(),
                  const SizedBox(height: 14),

                  // Emirate Filter Chips
                  _buildEmirateFilter(),
                  const SizedBox(height: 16),

                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Live Stores Today (${_liveStores.length})',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textMain),
                      ),
                      Text(
                        'Emirate: $_selectedEmirate',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Live Stores List
                  if (_liveStores.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderSubtle),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.storefront_outlined, size: 40, color: AppTheme.textMuted),
                          const SizedBox(height: 12),
                          const Text('No stores active in this filter today', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textMain)),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _showCreateScheduleModal,
                            child: const Text('+ Add a Store Schedule Now'),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._liveStores.map((store) => _buildStoreCard(store)),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiSection() {
    final liveStoresCount = _kpis['live_stores_count'] ?? 0;
    final activePromotersCount = _kpis['active_promoters_count'] ?? 0;
    final pendingDrops = _kpis['pending_drops'] ?? 0;
    final pendingCollections = _kpis['pending_collections'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _kpiTile('Live Stores', '$liveStoresCount', Icons.storefront_rounded, AppTheme.textMain),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _kpiTile('Promoters', '$activePromotersCount', Icons.people_alt_rounded, AppTheme.accent),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _kpiTile('Drops Due', '$pendingDrops', Icons.local_shipping_rounded, AppTheme.accentAmber),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _kpiTile('Collections', '$pendingCollections', Icons.repeat_rounded, AppTheme.accentEmerald),
        ),
      ],
    );
  }

  Widget _kpiTile(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
              Icon(icon, size: 15, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(44, 40),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            icon: const Icon(Icons.bolt_rounded, size: 16),
            label: const Text('Batch Schedule'),
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateSchedulePage()),
              );
              if (res == true) _loadDashboardData();
            },
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryDark,
              foregroundColor: Colors.white,
              minimumSize: const Size(44, 40),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            icon: const Icon(Icons.badge_outlined, size: 16),
            label: const Text('Badge Tracker', style: TextStyle(fontWeight: FontWeight.w700)),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BadgeTrackerScreen()),
              );
              _loadDashboardData();
            },
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(44, 40),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            icon: const Icon(Icons.campaign_outlined, size: 16, color: AppTheme.primary),
            label: const Text('+ Campaign', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateProjectPage()),
              );
              if (res == true) _loadDashboardData();
            },
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(44, 40),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            icon: const Icon(Icons.storefront_outlined, size: 16, color: AppTheme.primary),
            label: const Text('+ Store', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateStorePage()),
              );
              if (res == true) _loadDashboardData();
            },
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(44, 40),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            icon: const Icon(Icons.person_add_alt_outlined, size: 16, color: AppTheme.primary),
            label: const Text('+ Promoter', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
            onPressed: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePromoterPage()),
              );
              if (res == true) _loadDashboardData();
            },
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(44, 40),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            icon: const Icon(Icons.local_shipping_outlined, size: 16, color: AppTheme.accentAmber),
            label: const Text('Assign Drop', style: TextStyle(color: AppTheme.accentAmber, fontWeight: FontWeight.w700)),
            onPressed: _showAssignDropModal,
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(44, 40),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            icon: const Icon(Icons.repeat_rounded, size: 16, color: AppTheme.accentEmerald),
            label: const Text('Assign Collection', style: TextStyle(color: AppTheme.accentEmerald, fontWeight: FontWeight.w700)),
            onPressed: _showAssignCollectionModal,
          ),
        ],
      ),
    );
  }

  Widget _buildEmirateFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _emirates.map((emirate) {
          final isSelected = _selectedEmirate == emirate;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(emirate),
              selected: isSelected,
              onSelected: (_) => _onEmirateSelected(emirate),
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textMain,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.borderSubtle),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _makeCall(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Calling $phone...')));
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening WhatsApp for $phone...')));
    }
  }

  Widget _buildStoreCard(LiveStoreHub store) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Title Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.storeName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textMain),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceSubtle,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppTheme.borderSubtle),
                            ),
                            child: Text(
                              store.emirate,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMain),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            store.retailer,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Supervisor Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Field Lead', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                      Text(
                        store.supervisorName,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMain),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppTheme.borderSubtle),
            const SizedBox(height: 10),

            // Concurrent Projects & Promoters
            ...store.projects.map((project) {
              final isSadia = project.projectName.toLowerCase().contains('sadia');
              final accentColor = isSadia ? AppTheme.accentRose : AppTheme.accent;
              final bgColor = isSadia ? const Color(0xFFFFF1F2) : const Color(0xFFEFF6FF);
              final borderColor = isSadia ? const Color(0xFFFECDD3) : const Color(0xFFBFDBFE);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          project.projectName.toUpperCase(),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: accentColor),
                        ),
                        Text(
                          '${project.promoters.length} Staff',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Promoters working under this project
                    ...project.promoters.map((p) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  p.promoterName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textMain),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFFA7F3D0)),
                                  ),
                                  child: const Text('ON DUTY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.accentEmerald)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${p.startTime.substring(0, 5)} – ${p.endTime.substring(0, 5)} • Break: ${p.breakTimings ?? "None"}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontFamily: 'monospace'),
                            ),
                            const SizedBox(height: 8),

                            // Quick Action Buttons (Call, WhatsApp, Audit)
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(36, 32),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  icon: const Icon(Icons.phone_outlined, size: 14, color: AppTheme.accentEmerald),
                                  label: const Text('Call', style: TextStyle(fontSize: 11)),
                                  onPressed: () => _makeCall(p.promoterPhone),
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(36, 32),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppTheme.accent),
                                  label: const Text('WhatsApp', style: TextStyle(fontSize: 11)),
                                  onPressed: () => _openWhatsApp(p.promoterPhone),
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(36, 32),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  ),
                                  icon: const Icon(Icons.star_rounded, size: 14, color: AppTheme.accentAmber),
                                  label: const Text('Audit ⭐', style: TextStyle(fontSize: 11)),
                                  onPressed: () => _showEvaluationModal(p.promoterName),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
