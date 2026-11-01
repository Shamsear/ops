import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class CreateProjectPage extends StatefulWidget {
  const CreateProjectPage({super.key});

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
  final _nameController = TextEditingController();
  final _clientController = TextEditingController();
  DateTime _startDate = DateTime(2026, 10, 14);
  DateTime _endDate = DateTime(2026, 11, 30);
  bool _isSaving = false;

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final client = _clientController.text.trim();
    if (name.isEmpty || client.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Campaign Name and Client Name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final project = await ApiService.createProject(
      name: name,
      clientName: client,
      startDate: DateFormat('yyyy-MM-dd').format(_startDate),
      endDate: DateFormat('yyyy-MM-dd').format(_endDate),
    );

    setState(() => _isSaving = false);

    if (project != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Campaign "${project.name}" created successfully!')),
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create campaign. Please try again.')),
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
            Text('New Campaign Project', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textMain)),
            Text('Create Activation Roadshow', style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CAMPAIGN DETAILS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Campaign Project Name *',
                        hintText: 'e.g. Sadia In-Store Sampling Q4',
                        prefixIcon: Icon(Icons.campaign_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _clientController,
                      decoration: const InputDecoration(
                        labelText: 'Client / Brand *',
                        hintText: 'e.g. Sadia, Johnson & Johnson, Nutella',
                        prefixIcon: Icon(Icons.business_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _startDate,
                                firstDate: DateTime(2025),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) setState(() => _startDate = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                                prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                              ),
                              child: Text(DateFormat('yyyy-MM-dd').format(_startDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _endDate,
                                firstDate: DateTime(2025),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) setState(() => _endDate = picked);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End Date',
                                prefixIcon: Icon(Icons.event_outlined, size: 18),
                              ),
                              child: Text(DateFormat('yyyy-MM-dd').format(_endDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
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

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: _isSaving ? null : _handleSave,
              child: _isSaving
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create Campaign Project', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}
