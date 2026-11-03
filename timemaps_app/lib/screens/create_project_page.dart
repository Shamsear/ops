import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class CreateProjectPage extends StatefulWidget {
  const CreateProjectPage({super.key});

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
  final _nameController = TextEditingController();
  String _selectedClient = '';
  List<String> _clients = [
    'Sadia',
    'L\'Oreal',
    'Nestle',
    'Mondelez',
    'Unilever',
    'P&G',
    'IFFCO',
  ];
  DateTime _startDate = DateTime(2026, 10, 14);
  DateTime _endDate = DateTime(2026, 11, 30);
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    final list = await ApiService.getDistinctClients();
    if (mounted && list.isNotEmpty) {
      setState(() {
        final set = {..._clients, ...list};
        _clients = set.toList()..sort();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final client = _selectedClient.trim();
    if (name.isEmpty || client.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.inner)),
          content: Text(
            'Please enter Campaign Name and select Client Brand',
            style: AppText.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
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

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (project != null) {
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
                  'Campaign "${project.name}" launched successfully! 🚀',
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
            'Failed to create campaign. Please try again.',
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
      title: 'New Campaign Project',
      subtitle: 'In-store activation roadshow',
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: AppSpacing.sm),
          child: StatusBadge(
            label: 'Campaign',
            variant: StatusVariant.neutral,
            showDot: false,
          ),
        ),
      ],
      floatingBottom: StickyActionBar(
        primaryLabel: _isSaving ? 'Deploying...' : 'Deploy Campaign Project',
        primaryIcon: Icons.add_rounded,
        primaryLoading: _isSaving,
        onPrimaryPressed: _isSaving ? null : _handleSave,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(
                  icon: Icons.campaign_outlined,
                  iconColor: AppColors.primary,
                  microLabel: 'CAMPAIGN DETAILS',
                  title: 'Roadshow Specifications',
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _nameController,
                  label: 'Campaign Project Name *',
                  hint: 'e.g. Sadia In-Store Sampling Q4',
                ),
                const SizedBox(height: AppSpacing.md),
                SearchableSelectField<String>(
                  label: 'Client / Brand *',
                  value: _selectedClient.isEmpty ? null : _selectedClient,
                  hintText: 'Select or type brand / client name',
                  allowCustomValue: true,
                  prefixIcon: const Icon(Icons.business_rounded, size: 20, color: AppColors.accent),
                  options: _clients
                      .map((c) => SearchableOption<String>(value: c, label: c))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedClient = val);
                    }
                  },
                  onCustomValueSubmitted: (val) {
                    setState(() {
                      _selectedClient = val;
                      if (!_clients.contains(val)) {
                        _clients.insert(0, val);
                      }
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 340) {
                      return Column(
                        children: [
                          AppDateField(
                            label: 'Start Date',
                            value: _startDate,
                            onChanged: (d) => setState(() => _startDate = d),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppDateField(
                            label: 'End Date',
                            value: _endDate,
                            onChanged: (d) => setState(() => _endDate = d),
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: AppDateField(
                            label: 'Start Date',
                            value: _startDate,
                            onChanged: (d) => setState(() => _startDate = d),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm + 2),
                        Expanded(
                          child: AppDateField(
                            label: 'End Date',
                            value: _endDate,
                            onChanged: (d) => setState(() => _endDate = d),
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
