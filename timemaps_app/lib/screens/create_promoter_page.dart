import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class CreatePromoterPage extends StatefulWidget {
  const CreatePromoterPage({super.key});

  @override
  State<CreatePromoterPage> createState() => _CreatePromoterPageState();
}

class _CreatePromoterPageState extends State<CreatePromoterPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _nationalityController = TextEditingController(text: 'Filipino');

  String _gender = 'FEMALE';
  bool _isSaving = false;

  final List<String> _popularNationalities = [
    'Filipino',
    'Indian',
    'Pakistani',
    'Nepalese',
    'Arabic',
    'African',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _nationalityController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.danger,
          content: Text('Please enter Full Name and Phone Number'),
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
      nationality: _nationalityController.text.trim().isEmpty ? null : _nationalityController.text.trim(),
    );

    setState(() => _isSaving = false);

    if (promoter != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.success,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Promoter "${promoter.name}" registered to national roster!'),
            ],
          ),
        ),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.danger,
          content: Text('Failed to register promoter. Please try again.'),
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
            Text('Register Promoter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textMain, letterSpacing: -0.2)),
            Text('Onboard Staff to National Operations Roster', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
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
                      Icon(Icons.person_add_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Register to Active Roster'),
                    ],
                  ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card 1: Personal Details
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
                    'STAFF IDENTITY',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _nameController,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textMain),
                    decoration: const InputDecoration(
                      labelText: 'Full Legal Name *',
                      hintText: 'e.g. Sony Mathew',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textMain, fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      labelText: 'UAE Mobile Phone *',
                      hintText: '+971 50 123 4567',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textMain),
                    decoration: const InputDecoration(
                      labelText: 'Work / Personal Email (Optional)',
                      hintText: 'sony@imlme.com',
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card 2: Gender & Nationality
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
                    'DEMOGRAPHICS & PERMIT INFO',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 16),

                  const Text('Gender *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Female'),
                        selected: _gender == 'FEMALE',
                        selectedColor: AppTheme.primaryDark,
                        labelStyle: TextStyle(
                          color: _gender == 'FEMALE' ? Colors.white : AppTheme.textMain,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                        onSelected: (sel) {
                          if (sel) setState(() => _gender = 'FEMALE');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Male'),
                        selected: _gender == 'MALE',
                        selectedColor: AppTheme.primaryDark,
                        labelStyle: TextStyle(
                          color: _gender == 'MALE' ? Colors.white : AppTheme.textMain,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                        onSelected: (sel) {
                          if (sel) setState(() => _gender = 'MALE');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _nationalityController,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textMain),
                    decoration: const InputDecoration(
                      labelText: 'Nationality',
                      hintText: 'Filipino, Indian, etc.',
                      prefixIcon: Icon(Icons.public_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 10),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _popularNationalities.map((nat) {
                        final isSel = _nationalityController.text == nat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text(nat, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            backgroundColor: isSel ? AppTheme.accent.withOpacity(0.12) : AppTheme.surfaceSubtle,
                            side: BorderSide(color: isSel ? AppTheme.accent : AppTheme.borderSubtle),
                            onPressed: () => setState(() => _nationalityController.text = nat),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
