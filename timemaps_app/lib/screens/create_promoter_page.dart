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

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Full Name and Phone Number')),
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
        SnackBar(content: Text('Promoter "${promoter.name}" registered successfully!')),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to register promoter. Please try again.')),
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
            Text('Register Promoter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textMain)),
            Text('Add Field Staff to National Roster', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card 1: Personal Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STAFF PROFILE',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        hintText: 'e.g. Sony Mathew',
                        prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Phone *',
                        hintText: '+971 50 123 4567',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address (Optional)',
                        hintText: 'promoter@imlme.com',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Card 2: Gender & Nationality
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DEMOGRAPHICS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 14),

                    const Text('Gender *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Female'),
                          selected: _gender == 'FEMALE',
                          onSelected: (sel) {
                            if (sel) setState(() => _gender = 'FEMALE');
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Male'),
                          selected: _gender == 'MALE',
                          onSelected: (sel) {
                            if (sel) setState(() => _gender = 'MALE');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _nationalityController,
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
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(nat, style: const TextStyle(fontSize: 11)),
                              backgroundColor: _nationalityController.text == nat ? AppTheme.surfaceSubtle : Colors.white,
                              onPressed: () => setState(() => _nationalityController.text = nat),
                            ),
                          );
                        }).toList(),
                      ),
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
                  : const Text('Register Field Promoter', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
