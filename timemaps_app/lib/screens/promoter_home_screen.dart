import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'login_screen.dart';

class PromoterHomeScreen extends StatefulWidget {
  final UserModel promoterUser;

  const PromoterHomeScreen({super.key, required this.promoterUser});

  @override
  State<PromoterHomeScreen> createState() => _PromoterHomeScreenState();
}

class _PromoterHomeScreenState extends State<PromoterHomeScreen> {
  bool _isLoading = true;
  bool _isShiftActive = false;
  DateTime? _shiftStartTime;
  LiveStoreHub? _assignedStore;
  LivePromoterShift? _myShift;
  String _todayDateStr = '';
  final List<bool> _checklist = [true, true, false, false];

  @override
  void initState() {
    super.initState();
    _todayDateStr = DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());
    _loadPromoterShift();
  }

  Future<void> _loadPromoterShift() async {
    setState(() => _isLoading = true);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final data = await ApiService.getLiveDashboard(date: today);
    final allStores = (data['live_stores'] as List<LiveStoreHub>?) ?? [];

    LiveStoreHub? matchedStore;
    LivePromoterShift? matchedShift;

    // Search for shift with current user's name
    for (final s in allStores) {
      for (final p in s.projects) {
        for (final shift in p.promoters) {
          if (shift.promoterName.toLowerCase().contains(widget.promoterUser.name.toLowerCase().split(' ').first)) {
            matchedStore = s;
            matchedShift = shift;
            break;
          }
        }
      }
    }

    // Fallback to first store and shift if demo account
    if (matchedStore == null && allStores.isNotEmpty) {
      matchedStore = allStores.first;
      if (matchedStore.projects.isNotEmpty && matchedStore.projects.first.promoters.isNotEmpty) {
        matchedShift = matchedStore.projects.first.promoters.first;
      }
    }

    if (mounted) {
      setState(() {
        _assignedStore = matchedStore;
        _myShift = matchedShift;
        _isLoading = false;
      });
    }
  }

  void _toggleShift() {
    setState(() {
      _isShiftActive = !_isShiftActive;
      if (_isShiftActive) {
        _shiftStartTime = DateTime.now();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.inner)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Shift clocked in! Have a high-energy promotional day! 🚀',
                  style: AppText.bodyBold.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        );
      } else {
        _showShiftEndCelebrationModal();
      }
    });
  }

  void _showShiftEndCelebrationModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            const IconBox(
              icon: Icons.celebration_rounded,
              color: AppColors.success,
              size: 48,
              iconSize: 26,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Shift Successfully Logged!',
              style: AppText.display,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Great work today at ${_assignedStore?.storeName ?? "Store"}! Your attendance and sampling hours have been submitted to your supervisor.',
              style: AppText.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'Confirm & Close',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
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

  Future<void> _openMap(String query) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreenScaffold(
      bottomClearance: false,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InitialsAvatar(name: widget.promoterUser.name, size: 36),
      ),
      title: widget.promoterUser.name,
      subtitle: 'IML Field Specialist • $_todayDateStr',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: _loadPromoterShift,
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, size: 20, color: AppColors.textMuted),
          tooltip: 'Sign Out',
          onPressed: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
          },
        ),
      ],
      floatingBottom: StickyActionBar(
        summaryText: _isShiftActive
            ? 'Active shift at ${_assignedStore?.storeName ?? "Store"}'
            : 'Tap button to clock in on duty',
        primaryLabel: _isShiftActive ? 'End Shift For Today' : 'Start Shift & Check In',
        primaryIcon: _isShiftActive ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
        onPrimaryPressed: _toggleShift,
      ),
      body: _isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Shift Telemetry Hero Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StatusBadge(
                            label: _isShiftActive ? 'ON DUTY (ACTIVE)' : 'READY TO CLOCK IN',
                            variant: _isShiftActive ? StatusVariant.success : StatusVariant.warning,
                            showDot: true,
                          ),
                          if (_shiftStartTime != null)
                            Text(
                              'Clocked in at ${DateFormat("hh:mm a").format(_shiftStartTime!)}',
                              style: AppText.caption.copyWith(fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _isShiftActive ? 'Shift in Progress' : 'Good Morning, Ready for Work?',
                        style: AppText.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isShiftActive
                            ? 'Sampling actively at ${_assignedStore?.storeName ?? "Store"}.'
                            : 'Tap the action button below to log your on-duty timestamp.',
                        style: AppText.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),

                // 2. Today's Assigned Store Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        icon: Icons.storefront_rounded,
                        iconColor: AppColors.primary,
                        microLabel: 'ASSIGNED VENUE',
                        title: _assignedStore?.storeName ?? 'Store Location',
                        trailing: TextButton.icon(
                          onPressed: () => _openMap(_assignedStore?.storeName ?? 'Lulu Hypermarket - Al Barsha'),
                          icon: const Icon(Icons.directions_rounded, size: 14, color: AppColors.accent),
                          label: Text(
                            'Maps',
                            style: AppText.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${_assignedStore?.retailer ?? "Retailer"} • ${_assignedStore?.emirate ?? "Dubai"} Region',
                        style: AppText.caption,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppCard.flat(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Shift Timings', style: AppText.caption),
                                  const SizedBox(height: 2),
                                  Text(
                                    _myShift != null
                                        ? '${_myShift!.startTime.substring(0, 5)} – ${_myShift!.endTime.substring(0, 5)}'
                                        : '02:00 PM – 10:00 PM',
                                    style: AppText.bodyBold,
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 28, color: AppColors.borderSubtle),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Scheduled Break', style: AppText.caption),
                                  const SizedBox(height: 2),
                                  Text(
                                    _myShift?.breakTimings ?? '05:00 PM – 05:45 PM',
                                    style: AppText.bodyBold.copyWith(color: AppColors.warning),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),

                // 3. Daily Field Checklist
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        icon: Icons.checklist_rounded,
                        iconColor: AppColors.accent,
                        microLabel: 'FIELD ROUTINE',
                        title: 'Daily Checklist',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _buildChecklistItem(0, 'Wear branded uniform & visible store badge'),
                      _buildChecklistItem(1, 'Display stand sanitization & sample stock check'),
                      _buildChecklistItem(2, 'Record daily customer tasting / interaction counter'),
                      _buildChecklistItem(3, 'Final stock count & supervisor sign-off'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),

                // 4. Supervisor Hotline Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        icon: Icons.supervisor_account_rounded,
                        iconColor: AppColors.purple,
                        microLabel: 'FIELD SUPERVISOR',
                        title: 'On-Duty Support',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          InitialsAvatar(
                            name: _assignedStore?.supervisorName.isNotEmpty == true
                                ? _assignedStore!.supervisorName
                                : 'Babar Lead',
                            size: 38,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _assignedStore?.supervisorName.isNotEmpty == true
                                      ? _assignedStore!.supervisorName
                                      : 'Babar (Lead)',
                                  style: AppText.bodyBold,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _assignedStore?.supervisorPhone.isNotEmpty == true
                                      ? _assignedStore!.supervisorPhone
                                      : '+971 50 123 4567',
                                  style: AppText.caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          IconButton(
                            icon: const IconBox(
                              icon: Icons.phone_rounded,
                              color: AppColors.accent,
                              isCompact: true,
                            ),
                            onPressed: () => _makeCall(_assignedStore?.supervisorPhone ?? '+971501234567'),
                          ),
                          IconButton(
                            icon: const IconBox(
                              icon: Icons.chat_bubble_rounded,
                              color: AppColors.success,
                              isCompact: true,
                            ),
                            onPressed: () => _openWhatsApp(_assignedStore?.supervisorPhone ?? '+971501234567'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
              ],
            ),
    );
  }

  Widget _buildChecklistItem(int index, String title) {
    final checked = _checklist[index];
    return InkWell(
      onTap: () => setState(() => _checklist[index] = !_checklist[index]),
      borderRadius: BorderRadius.circular(AppRadius.inner),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: checked ? AppColors.success : AppColors.borderStrong,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: AppText.body.copyWith(
                  color: checked ? AppColors.textSecondary : AppColors.textPrimary,
                  decoration: checked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
