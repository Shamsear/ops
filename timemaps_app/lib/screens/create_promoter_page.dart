import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class CreatePromoterPage extends StatefulWidget {
  const CreatePromoterPage({super.key});

  @override
  State<CreatePromoterPage> createState() => _CreatePromoterPageState();
}

class _CreatePromoterPageState extends State<CreatePromoterPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedNationality = 'Filipino';
  List<String> _nationalities = [
    'Filipino',
    'Indian',
    'Pakistani',
    'Nepalese',
    'Arabic',
    'African',
    'Egyptian',
  ];

  String _gender = 'FEMALE';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadNationalities();
  }

  Future<void> _loadNationalities() async {
    final list = await ApiService.getDistinctNationalities();
    if (mounted) {
      setState(() {
        _nationalities = list;
        if (!_nationalities.contains(_selectedNationality)) {
          _nationalities.insert(0, _selectedNationality);
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.inner)),
          content: Text(
            'Please enter Full Name and Phone Number',
            style: AppText.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final promoter = await ApiService.createPromoter(
      name: name,
      phone: phone,
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      gender: _gender,
      nationality: _selectedNationality.trim().isEmpty ? null : _selectedNationality.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (promoter != null) {
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
                  'Promoter "${promoter.name}" registered to roster! 👤',
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
            'Failed to register promoter. Please try again.',
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
      title: 'Register Promoter',
      subtitle: 'Onboard staff to national operations roster',
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: AppSpacing.sm),
          child: StatusBadge(
            label: 'Roster',
            variant: StatusVariant.neutral,
            showDot: false,
          ),
        ),
      ],
      floatingBottom: StickyActionBar(
        primaryLabel: _isSaving ? 'Registering...' : 'Register to Active Roster',
        primaryIcon: Icons.person_add_rounded,
        primaryLoading: _isSaving,
        onPrimaryPressed: _isSaving ? null : _handleSave,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card 1: Staff Identity
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(
                  icon: Icons.person_outline_rounded,
                  iconColor: AppColors.primary,
                  microLabel: 'STAFF IDENTITY',
                  title: 'Personal Information',
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _nameController,
                  label: 'Full Legal Name *',
                  hint: 'e.g. Sony Mathew',
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _phoneController,
                  label: 'UAE Mobile Phone *',
                  hint: '+971 50 123 4567',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _emailController,
                  label: 'Work / Personal Email (Optional)',
                  hint: 'sony@imlme.com',
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),

          // Card 2: Demographics & Nationality
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(
                  icon: Icons.public_outlined,
                  iconColor: AppColors.accent,
                  microLabel: 'DEMOGRAPHICS',
                  title: 'Gender & Nationality',
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'GENDER *',
                  style: AppText.micro.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    FilterPill(
                      label: 'Female',
                      isSelected: _gender == 'FEMALE',
                      onTap: () => setState(() => _gender = 'FEMALE'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilterPill(
                      label: 'Male',
                      isSelected: _gender == 'MALE',
                      onTap: () => setState(() => _gender = 'MALE'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SearchableSelectField<String>(
                  label: 'Nationality',
                  value: _selectedNationality,
                  hintText: 'Select or type any nationality',
                  allowCustomValue: true,
                  prefixIcon: const Icon(Icons.public_rounded, size: 20, color: AppColors.accent),
                  options: _nationalities
                      .map((nat) => SearchableOption<String>(value: nat, label: nat))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedNationality = val);
                    }
                  },
                  onCustomValueSubmitted: (val) {
                    setState(() {
                      _selectedNationality = val;
                      if (!_nationalities.contains(val)) {
                        _nationalities.insert(0, val);
                      }
                    });
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
