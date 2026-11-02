import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

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
    'Carrefour',
    'Union Coop',
    'Spinneys',
    'Choithrams',
    'Nesto',
    'Viva',
    'Grandiose',
    'Mair Group',
    'Mark and Save',
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

  @override
  void dispose() {
    _storeNameController.dispose();
    _customerCodeController.dispose();
    _retailerController.dispose();
    _branchCodeController.dispose();
    _cityController.dispose();
    _smnContactController.dispose();
    _merchandiserLeadController.dispose();
    _contactPersonController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _storeNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.inner)),
          content: Text(
            'Please enter Store Branch Name',
            style: AppText.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    StoreModel? store;
    if (widget.storeToEdit != null) {
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

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (store != null) {
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
                  widget.storeToEdit != null
                      ? 'Store "${store.storeName}" updated successfully!'
                      : 'Store "${store.storeName}" onboarded to directory! 🏪',
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
            'Failed to save store. Please check required fields.',
            style: AppText.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.storeToEdit != null;

    return AppScreenScaffold(
      bottomClearance: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: isEditing ? 'Edit Store Branch' : 'Onboard New Store',
      subtitle: isEditing
          ? 'Update branch contacts & customer code'
          : 'Register hypermarket branch to UAE network',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: StatusBadge(
            label: isEditing ? 'Edit' : 'New',
            variant: StatusVariant.neutral,
            showDot: false,
          ),
        ),
      ],
      floatingBottom: StickyActionBar(
        primaryLabel: _isSaving
            ? 'Saving...'
            : (isEditing ? 'Update Store Information' : 'Save Store Location'),
        primaryIcon: Icons.storefront_rounded,
        primaryLoading: _isSaving,
        onPrimaryPressed: _isSaving ? null : _handleSave,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card 1: Branch & Retailer Chain
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(
                  icon: Icons.storefront_rounded,
                  iconColor: AppColors.primary,
                  microLabel: 'BRANCH IDENTITY',
                  title: 'Name & Retailer Chain',
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _storeNameController,
                  label: 'Store Branch Name *',
                  hint: 'e.g. Lulu Hypermarket - Al Barsha',
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _retailerController,
                  label: 'Retailer / Chain *',
                  hint: 'e.g. Lulu Hypermarket, Carrefour, Union Coop',
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _popularRetailers.map((chain) {
                    final isSel = _retailerController.text == chain;
                    return FilterPill(
                      label: chain,
                      isSelected: isSel,
                      onTap: () => setState(() => _retailerController.text = chain),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),

          // Card 2: Location & Codes
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(
                  icon: Icons.location_on_outlined,
                  iconColor: AppColors.accent,
                  microLabel: 'LOCATION & CODES',
                  title: 'Emirate & System Codes',
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'EMIRATE *',
                  style: AppText.micro.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _emirates.map((em) {
                    return FilterPill(
                      label: em,
                      isSelected: _selectedEmirate == em,
                      onTap: () => setState(() => _selectedEmirate = em),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 340) {
                      return Column(
                        children: [
                          AppTextField(
                            controller: _customerCodeController,
                            label: 'Customer Code (Optional)',
                            hint: 'e.g. 10482',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _branchCodeController,
                            label: 'Branch Code (Optional)',
                            hint: 'e.g. DXB-04',
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _customerCodeController,
                            label: 'Customer Code (Optional)',
                            hint: 'e.g. 10482',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm + 2),
                        Expanded(
                          child: AppTextField(
                            controller: _branchCodeController,
                            label: 'Branch Code (Optional)',
                            hint: 'e.g. DXB-04',
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _cityController,
                  label: 'City / Neighborhood',
                  hint: 'e.g. Al Barsha 1, Dubai',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),

          // Card 3: Key Field Contacts
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(
                  icon: Icons.contacts_outlined,
                  iconColor: AppColors.success,
                  microLabel: 'KEY CONTACTS',
                  title: 'Field Operations & Leads',
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 340) {
                      return Column(
                        children: [
                          AppTextField(
                            controller: _smnContactController,
                            label: 'SMN / Key Account Contact',
                            hint: 'Lead person name',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _merchandiserLeadController,
                            label: 'Merchandiser Lead',
                            hint: 'Merchandiser in charge',
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _smnContactController,
                            label: 'SMN / Account Contact',
                            hint: 'Lead person name',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm + 2),
                        Expanded(
                          child: AppTextField(
                            controller: _merchandiserLeadController,
                            label: 'Merchandiser Lead',
                            hint: 'Merchandiser in charge',
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 340) {
                      return Column(
                        children: [
                          AppTextField(
                            controller: _contactPersonController,
                            label: 'Branch Manager / Receiving Lead',
                            hint: 'On-site contact name',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _contactPhoneController,
                            label: 'Contact Phone Number',
                            hint: '+971 50 000 0000',
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _contactPersonController,
                            label: 'Branch Manager / Receiving',
                            hint: 'On-site contact name',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm + 2),
                        Expanded(
                          child: AppTextField(
                            controller: _contactPhoneController,
                            label: 'Contact Phone',
                            hint: '+971 50 000 0000',
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    );
                  },
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
