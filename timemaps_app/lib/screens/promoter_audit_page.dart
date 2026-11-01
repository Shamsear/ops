import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/liquid_glass.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/searchable_select_field.dart';
import '../widgets/status_badge.dart';

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
          _selectedPromoter = _promoters.where((p) => p.name.toLowerCase() == widget.promoterName!.toLowerCase()).firstOrNull;
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
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Audit for ${_selectedPromoter!.name} submitted! (${_overallScore.toStringAsFixed(1)} ⭐)',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      extendBody: true,
      appBar: AppBar(
        titleSpacing: 0,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.76),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.50),
                    width: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Field Audit Scorecard',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMain,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              _selectedPromoter != null ? 'Auditing: ${_selectedPromoter!.name}' : 'Promoter quality & compliance review',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: StatusBadge(
              label: '${_overallScore.toStringAsFixed(1)} ⭐',
              variant: _overallScore >= 4.0 ? StatusVariant.success : StatusVariant.warning,
              showDot: true,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: LiquidGlassContainer(
            radius: 22.0,
            blur: 24.0,
            opacity: 0.85,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${_overallScore.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '/ 5.0 Rating',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _selectedPromoter != null ? _selectedPromoter!.name : 'Select promoter',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                onPressed: _isSaving ? null : _handleSubmit,
                icon: _isSaving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.rate_review_rounded, size: 18),
                label: Text(
                  _isSaving ? 'Submitting...' : 'Submit Scorecard',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card
                    _buildStaffInfoCard(),
                    const SizedBox(height: 16),

                    // Rating Criteria Cards
                    _buildCriteriaCard(
                      title: 'Uniform Grooming & Hygiene',
                      description: 'Ironed uniform, brand cap, name badge visible, clean footwear',
                      score: _grooming,
                      onChanged: (val) => setState(() => _grooming = val),
                    ),
                    const SizedBox(height: 12),

                    _buildCriteriaCard(
                      title: 'Product Pitch & Brand Script',
                      description: 'Accurate USP benefits, pricing knowledge, customer objection handling',
                      score: _pitch,
                      onChanged: (val) => setState(() => _pitch = val),
                    ),
                    const SizedBox(height: 12),

                    _buildCriteriaCard(
                      title: 'Shopper Engagement & Proactivity',
                      description: 'Active standing, welcoming body posture, proactive sample distribution',
                      score: _engagement,
                      onChanged: (val) => setState(() => _engagement = val),
                    ),
                    const SizedBox(height: 12),

                    _buildCriteriaCard(
                      title: 'Punctuality & Stand Floor Cleanliness',
                      description: 'On-time arrival, sampling tray hygienic, POSM arranged neatly',
                      score: _punctuality,
                      onChanged: (val) => setState(() => _punctuality = val),
                    ),
                    const SizedBox(height: 16),

                    // Coaching Notes Card
                    _buildNotesCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStaffInfoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_pin_circle_rounded, size: 18, color: AppTheme.primary),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROMOTER & LOCATION DETAILS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      'Assigned shift and brand venue',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Promoter Selector
            SearchableSelectField<PromoterModel>(
              label: 'Audited Promoter *',
              value: _selectedPromoter,
              options: _promoters.map((p) => SearchableOption<PromoterModel>(
                value: p,
                label: p.name,
                subtitle: '${p.phone} • ${p.nationality ?? 'Promoter'}',
              )).toList(),
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
              onChanged: (p) => setState(() => _selectedPromoter = p),
            ),
            const SizedBox(height: 12),

            // Store Location Selector
            SearchableSelectField<StoreModel>(
              label: 'Store Location *',
              value: _selectedStore,
              options: _stores.map((s) => SearchableOption<StoreModel>(
                value: s,
                label: s.storeName,
                subtitle: '${s.retailer} • ${s.emirate}',
              )).toList(),
              prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
              onChanged: (s) => setState(() => _selectedStore = s),
            ),
            const SizedBox(height: 12),

            // Campaign Project Selector
            SearchableSelectField<ProjectModel>(
              label: 'Campaign Roadshow *',
              value: _selectedProject,
              options: _projects.map((p) => SearchableOption<ProjectModel>(
                value: p,
                label: p.name,
                subtitle: p.clientName.isNotEmpty ? p.clientName : 'Direct Client',
              )).toList(),
              prefixIcon: const Icon(Icons.campaign_outlined, size: 20),
              onChanged: (p) => setState(() => _selectedProject = p),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCriteriaCard({
    required String title,
    required String description,
    required int score,
    required ValueChanged<int> onChanged,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMain,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: score >= 4 ? AppTheme.successBg : AppTheme.warningBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$score / 5 ⭐',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: score >= 4 ? AppTheme.success : AppTheme.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.3),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                final starVal = index + 1;
                final isFilled = starVal <= score;
                return InkWell(
                  onTap: () => onChanged(starVal),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isFilled ? const Color(0xFFFEF3C7) : AppTheme.surfaceSubtle,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isFilled ? const Color(0xFFF59E0B) : AppTheme.borderSubtle,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: isFilled ? const Color(0xFFF59E0B) : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$starVal',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isFilled ? const Color(0xFFB45309) : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.rate_review_outlined, size: 18, color: AppTheme.accent),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SUPERVISOR COACHING FEEDBACK',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      'Constructive guidance for promoter development',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _feedbackController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Coaching Notes & Observations',
                hintText: 'e.g. Excellent greeting, proactive sampling. Encourage louder pitch during peak footfall.',
                prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
