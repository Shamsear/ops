import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class CreateStorePage extends StatefulWidget {
  final StoreModel? storeToEdit;

  const CreateStorePage({super.key, this.storeToEdit});

  @override
  State<CreateStorePage> createState() => _CreateStorePageState();
}

class _CreateStorePageState extends State<CreateStorePage> {
  final _storeNameController = TextEditingController();
  final _customerCodeController = TextEditingController();
  final _retailerController = TextEditingController(text: 'Lulu Hypermarket');
  final _branchCodeController = TextEditingController();
  final _cityController = TextEditingController(text: 'Dubai');
  final _smnContactController = TextEditingController();
  final _merchandiserLeadController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  String _selectedEmirate = 'Dubai';
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

  final List<String> _popularRetailers = [
    'Lulu Hypermarket',
    'Union Coop',
    'Carrefour',
    'Mair Group',
    'Mark and Save',
    'Spinneys',
    'Choithrams',
    'Nesto',
    'Viva',
    'Al Maya',
    'Grandiose',
    'Al Ain Coop',
    'Sharjah Coop',
    'KM Trading',
    'West Zone',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.storeToEdit != null) {
      final s = widget.storeToEdit!;
      _storeNameController.text = s.storeName;
      _customerCodeController.text = s.customerCode ?? '';
      _retailerController.text = s.chain ?? s.retailer;
      _branchCodeController.text = s.branchCode ?? '';
      _cityController.text = s.city ?? '';
      _smnContactController.text = s.smnContact ?? '';
      _merchandiserLeadController.text = s.merchandiserLead ?? '';
      _contactPersonController.text = s.contactPerson ?? '';
      _contactPhoneController.text = s.contactPhone ?? '';
      if (_emirates.contains(s.emirate)) {
        _selectedEmirate = s.emirate;
      }
    }
  }

  Future<void> _handleSave() async {
    final name = _storeNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Store Branch Name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    StoreModel? store;
    if (widget.storeToEdit != null) {
      // Edit mode
      store = await ApiService.updateStore(
        storeId: widget.storeToEdit!.id,
        storeName: name,
        retailer: _retailerController.text.trim().isEmpty ? 'Retailer' : _retailerController.text.trim(),
        emirate: _selectedEmirate,
        customerCode: _customerCodeController.text.trim().isEmpty ? null : _customerCodeController.text.trim(),
        chain: _retailerController.text.trim().isEmpty ? null : _retailerController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        smnContact: _smnContactController.text.trim().isEmpty ? null : _smnContactController.text.trim(),
        merchandiserLead: _merchandiserLeadController.text.trim().isEmpty ? null : _merchandiserLeadController.text.trim(),
        branchCode: _branchCodeController.text.trim().isEmpty ? null : _branchCodeController.text.trim(),
        locationAddress: _cityController.text.trim(),
        contactPerson: _contactPersonController.text.trim().isEmpty ? null : _contactPersonController.text.trim(),
        contactPhone: _contactPhoneController.text.trim().isEmpty ? null : _contactPhoneController.text.trim(),
      );
    } else {
      // Create new
      store = await ApiService.createStore(
        storeName: name,
        retailer: _retailerController.text.trim().isEmpty ? 'Retailer' : _retailerController.text.trim(),
        emirate: _selectedEmirate,
        customerCode: _customerCodeController.text.trim().isEmpty ? null : _customerCodeController.text.trim(),
        chain: _retailerController.text.trim().isEmpty ? null : _retailerController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        smnContact: _smnContactController.text.trim().isEmpty ? null : _smnContactController.text.trim(),
        merchandiserLead: _merchandiserLeadController.text.trim().isEmpty ? null : _merchandiserLeadController.text.trim(),
        branchCode: _branchCodeController.text.trim().isEmpty ? null : _branchCodeController.text.trim(),
        locationAddress: _cityController.text.trim(),
        contactPerson: _contactPersonController.text.trim().isEmpty ? null : _contactPersonController.text.trim(),
        contactPhone: _contactPhoneController.text.trim().isEmpty ? null : _contactPhoneController.text.trim(),
      );
    }

    setState(() => _isSaving = false);

    if (store != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.storeToEdit != null
              ? 'Store "${store.storeName}" updated successfully!'
              : 'Store "${store.storeName}" onboarded successfully!'),
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save store. Please check required fields.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.storeToEdit != null;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEditing ? 'Edit Store Branch' : 'Store Onboarding',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textMain)),
            Text(isEditing ? 'Update Branch Info & Contacts' : 'Add Hypermarket Branch & Account Codes',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
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
              label: Text(isEditing ? 'Update' : 'Save', style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card 1: Branch & Retailer Chain
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BRANCH IDENTITY & RETAILER CHAIN',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _storeNameController,
                      decoration: const InputDecoration(
                        labelText: 'Store Branch Name *',
                        hintText: 'e.g. Lulu Hypermarket - Al Barsha',
                        prefixIcon: Icon(Icons.storefront_outlined, size: 20),
                        helperText: 'Unique hypermarket branch name',
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _retailerController,
                            decoration: const InputDecoration(
                              labelText: 'Retailer Chain (Type Any Chain) *',
                              hintText: 'Lulu, Carrefour, Nesto, Spinneys...',
                              prefixIcon: Icon(Icons.shopping_bag_outlined, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _customerCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Cus. Code',
                              hintText: 'e.g. 201104',
                              prefixIcon: Icon(Icons.pin_outlined, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick Retailer Chips (Any Chain can also be typed freely)
                    const Text('Quick Select or Type New Chain:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _popularRetailers.map((ret) {
                          final isSelected = _retailerController.text == ret;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(ret, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600)),
                              backgroundColor: isSelected ? AppTheme.surfaceSubtle : Colors.white,
                              onPressed: () => setState(() => _retailerController.text = ret),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Card 2: Region & Location
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GEOGRAPHY & CITY',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: _selectedEmirate,
                            decoration: const InputDecoration(
                              labelText: 'Emirate *',
                              prefixIcon: Icon(Icons.location_city_outlined, size: 18),
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
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'City / Area',
                              hintText: 'e.g. Al Barsha 1',
                              prefixIcon: Icon(Icons.map_outlined, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Card 3: Merchandising & Contacts
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'FIELD LEADS & CONTACTS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _smnContactController,
                            decoration: const InputDecoration(
                              labelText: 'SMN Contact',
                              hintText: 'e.g. Imran SMN',
                              prefixIcon: Icon(Icons.person_pin_outlined, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _merchandiserLeadController,
                            decoration: const InputDecoration(
                              labelText: 'Merchandiser Lead',
                              hintText: 'e.g. Babar / Jasheer',
                              prefixIcon: Icon(Icons.supervisor_account_outlined, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _contactPersonController,
                            decoration: const InputDecoration(
                              labelText: 'Store In-Charge',
                              hintText: 'Branch Manager name',
                              prefixIcon: Icon(Icons.badge_outlined, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _contactPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              hintText: '+971 50...',
                              prefixIcon: Icon(Icons.phone_outlined, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: _isSaving ? null : _handleSave,
              child: _isSaving
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isEditing ? 'Update Store Details' : 'Save Store Location',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
