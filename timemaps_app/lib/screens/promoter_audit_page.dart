import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class PromoterAuditPage extends StatefulWidget {
  final int? promoterId;
  final String? promoterName;
  final String? promoterPhone;
  final int? projectId;
  final int? storeId;
  final String? storeName;

  const PromoterAuditPage({
    super.key,
    this.promoterId,
    this.promoterName,
    this.promoterPhone,
    this.projectId,
    this.storeId,
    this.storeName,
  });

  @override
  State<PromoterAuditPage> createState() => _PromoterAuditPageState();
}

class _PromoterAuditPageState extends State<PromoterAuditPage> {
  List<ProjectModel> _projects = [];
  List<StoreModel> _stores = [];
  List<PromoterModel> _promoters = [];

  ProjectModel? _selectedProject;
  StoreModel? _selectedStore;
  PromoterModel? _selectedPromoter;

  int _grooming = 5;
  int _pitch = 5;
  int _engagement = 4;
  int _punctuality = 5;
  final _feedbackController = TextEditingController(
    text: 'Active shopper engagement, pristine uniform and stand hygiene.',
  );

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
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

        if (widget.projectId != null) {
          _selectedProject = _projects.where((p) => p.id == widget.projectId).firstOrNull;
        }
        _selectedProject ??= _projects.isNotEmpty ? _projects.first : null;

        if (widget.storeId != null) {
          _selectedStore = _stores.where((s) => s.id == widget.storeId).firstOrNull;
        }
        _selectedStore ??= _stores.isNotEmpty ? _stores.first : null;

        if (widget.promoterId != null) {
          _selectedPromoter = _promoters.where((p) => p.id == widget.promoterId).firstOrNull;
        }
        if (_selectedPromoter == null && widget.promoterName != null) {
          _selectedPromoter = _promoters
              .where((p) => p.name.toLowerCase() == widget.promoterName!.toLowerCase())
              .firstOrNull;
        }
        _selectedPromoter ??= _promoters.isNotEmpty ? _promoters.first : null;

        _isLoading = false;
      });
    }
  }

  double get _overallScore => (_grooming + _pitch + _engagement + _punctuality) / 4.0;

  Future<void> _handleSubmit() async {
    if (_selectedProject == null) {
      _showWarning('Please select Campaign Project');
      return;
    }
    if (_selectedStore == null) {
      _showWarning('Please select Store Location');
      return;
    }
    if (_selectedPromoter == null) {
      _showWarning('Please select Promoter being audited');
      return;
    }

    setState(() => _isSaving = true);

    final success = await ApiService.submitEvaluation(
      projectId: _selectedProject!.id,
      storeId: _selectedStore!.id,
      promoterId: _selectedPromoter!.id,
      supervisorId: 1, // Default supervisor
      grooming: _grooming,
      pitch: _pitch,
      engagement: _engagement,
      punctuality: _punctuality,
      feedback: _feedbackController.text.trim().isEmpty ? null : _feedbackController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.inner)),
          content: Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Audit for ${_selectedPromoter!.name} submitted! (${_overallScore.toStringAsFixed(1)} ⭐)',
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
      _showWarning('Failed to submit evaluation. Please try again.');
    }
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.inner)),
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppText.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      bottomClearance: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: 'Field Audit Scorecard',
      subtitle: _selectedPromoter != null
          ? 'Auditing: ${_selectedPromoter!.name}'
          : 'Promoter quality & compliance review',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: StatusBadge(
            label: '${_overallScore.toStringAsFixed(1)} ⭐',
            variant: _overallScore >= 4.0 ? StatusVariant.success : StatusVariant.warning,
            showDot: true,
          ),
        ),
      ],
      floatingBottom: StickyActionBar(
        summaryText: _selectedPromoter != null
            ? '${_selectedPromoter!.name} • ${_overallScore.toStringAsFixed(1)} / 5.0 Rating'
            : null,
        primaryLabel: _isSaving ? 'Submitting...' : 'Submit Scorecard',
        primaryIcon: Icons.rate_review_rounded,
        primaryLoading: _isSaving,
        onPrimaryPressed: _isSaving ? null : _handleSubmit,
      ),
      body: _isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Target Promoter & Store
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(
                        icon: Icons.person_pin_circle_rounded,
                        iconColor: AppColors.primary,
                        microLabel: 'AUDIT TARGET',
                        title: 'Promoter & Location',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SearchableSelectField<PromoterModel>(
                        label: 'Audited Promoter *',
                        value: _selectedPromoter,
                        options: _promoters
                            .map((p) => SearchableOption<PromoterModel>(
                                  value: p,
                                  label: p.name,
                                  subtitle: '${p.phone} • ${p.nationality ?? "Promoter"}',
                                ))
                            .toList(),
                        prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                        onChanged: (p) => setState(() => _selectedPromoter = p),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SearchableSelectField<StoreModel>(
                        label: 'Store Location *',
                        value: _selectedStore,
                        options: _stores
                            .map((s) => SearchableOption<StoreModel>(
                                  value: s,
                                  label: s.storeName,
                                  subtitle: '${s.retailer} • ${s.emirate}',
                                ))
                            .toList(),
                        prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
                        onChanged: (s) => setState(() => _selectedStore = s),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SearchableSelectField<ProjectModel>(
                        label: 'Campaign Roadshow *',
                        value: _selectedProject,
                        options: _projects
                            .map((p) => SearchableOption<ProjectModel>(
                                  value: p,
                                  label: p.name,
                                  subtitle: p.clientName.isNotEmpty ? p.clientName : 'Direct Client',
                                ))
                            .toList(),
                        prefixIcon: const Icon(Icons.campaign_outlined, size: 20),
                        onChanged: (p) => setState(() => _selectedProject = p),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),

                // 2. Performance Dimensions
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(
                        icon: Icons.star_rounded,
                        iconColor: AppColors.warning,
                        microLabel: 'SCORING CRITERIA',
                        title: 'Performance Dimensions',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildCriteriaRow(
                        title: 'Uniform Grooming & Hygiene',
                        description: 'Ironed uniform, brand cap, badge visible, tidy footwear',
                        score: _grooming,
                        onChanged: (val) => setState(() => _grooming = val),
                      ),
                      const Divider(height: 24),
                      _buildCriteriaRow(
                        title: 'Product Pitch & Brand Script',
                        description: 'Accurate USP benefits, pricing, objection handling',
                        score: _pitch,
                        onChanged: (val) => setState(() => _pitch = val),
                      ),
                      const Divider(height: 24),
                      _buildCriteriaRow(
                        title: 'Shopper Engagement & Proactivity',
                        description: 'Active posture, welcoming smile, sample handovers',
                        score: _engagement,
                        onChanged: (val) => setState(() => _engagement = val),
                      ),
                      const Divider(height: 24),
                      _buildCriteriaRow(
                        title: 'Punctuality & Stand Cleanliness',
                        description: 'On-time arrival, sampling tray hygiene, neat POSM',
                        score: _punctuality,
                        onChanged: (val) => setState(() => _punctuality = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),

                // 3. Supervisor Feedback
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader(
                        icon: Icons.edit_note_rounded,
                        iconColor: AppColors.accent,
                        microLabel: 'COACHING FEEDBACK',
                        title: 'Supervisor Observations',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _feedbackController,
                        label: 'Coaching Notes & Recommendations',
                        hint: 'e.g. Active engagement, neat uniform. Encourage louder greeting during peak footfall.',
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
              ],
            ),
    );
  }

  Widget _buildCriteriaRow({
    required String title,
    required String description,
    required int score,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: AppText.bodyBold,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            StatusBadge(
              label: '$score / 5 ⭐',
              variant: score >= 4 ? StatusVariant.success : StatusVariant.warning,
              showDot: true,
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(description, style: AppText.caption),
        const SizedBox(height: AppSpacing.sm + 2),
        Row(
          children: List.generate(5, (index) {
            final starVal = index + 1;
            final isFilled = starVal <= score;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 3,
                  right: index == 4 ? 0 : 3,
                ),
                child: InkWell(
                  onTap: () => onChanged(starVal),
                  borderRadius: BorderRadius.circular(AppRadius.inner),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isFilled ? AppColors.warningSoft : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadius.inner),
                      border: Border.all(
                        color: isFilled ? AppColors.warning.withOpacity(0.3) : AppColors.borderSubtle,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: isFilled ? AppColors.warning : AppColors.textMuted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$starVal',
                          style: AppText.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isFilled ? AppColors.warning : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
