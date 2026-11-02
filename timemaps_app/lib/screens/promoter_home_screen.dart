import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/liquid_glass.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
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
    _todayDateStr = DateFormat('EEEE, dd MMMM yyyy').format(DateTime(2026, 10, 14));
    _loadPromoterShift();
  }

  Future<void> _loadPromoterShift() async {
    setState(() => _isLoading = true);
    final today = DateFormat('yyyy-MM-dd').format(DateTime(2026, 10, 14));
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
          const SnackBar(
            backgroundColor: AppTheme.success,
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Shift clocked in! Have a high-energy promotional day! 🚀'),
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
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusExtraLarge)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.borderStrong,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.successBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.successBorder),
              ),
              child: const Icon(Icons.celebration_rounded, size: 42, color: AppTheme.success),
            ),
            const SizedBox(height: 18),
            const Text(
              'Shift Successfully Logged!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppTheme.textMain,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Great work today at ${_assignedStore?.storeName ?? "Store"}! Your attendance and sampling hours have been submitted to your supervisor.',
              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: AppTheme.primaryDark,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Confirm & Close'),
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
    return Scaffold(
      backgroundColor: AppTheme.canvasBg,
      appBar: AppBar(
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
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.accent.withOpacity(0.12),
              child: Text(
                widget.promoterUser.name.isNotEmpty ? widget.promoterUser.name[0] : 'P',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.accent),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.promoterUser.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textMain, letterSpacing: -0.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'IML Field Specialist • $_todayDateStr',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: _loadPromoterShift,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 21, color: AppTheme.textMuted),
            tooltip: 'Sign Out',
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main Shift Telemetry Hero Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: _isShiftActive
                            ? const LinearGradient(
                                colors: [Color(0xFF064E3B), Color(0xFF047857)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : const LinearGradient(
                                colors: [AppTheme.primaryDark, AppTheme.primaryLight],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(AppTheme.radiusExtraLarge),
                        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.2),
                        boxShadow: AppTheme.floatingShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: _isShiftActive ? const Color(0xFF34D399) : Colors.white70,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isShiftActive ? 'ON DUTY (ACTIVE)' : 'READY TO CLOCK IN',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_shiftStartTime != null)
                                Text(
                                  'Clocked in at ${DateFormat('hh:mm a').format(_shiftStartTime!)}',
                                  style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w600),
                                ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _isShiftActive ? 'Shift in Progress' : 'Good Morning, Ready for Work?',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isShiftActive
                                ? 'Sampling actively at ${_assignedStore?.storeName ?? "Store"}.'
                                : 'Tap the button below to log your on-duty timestamp.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Thumb-Zone Shift Action Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isShiftActive ? const Color(0xFFDC2626) : AppTheme.success,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                              ),
                              onPressed: _toggleShift,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_isShiftActive ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isShiftActive ? 'END SHIFT FOR TODAY' : 'START SHIFT & CHECK IN',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Today's Assigned Store Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        border: Border.all(color: AppTheme.borderSubtle, width: 1.1),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TODAY\'S ASSIGNED STORE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textMuted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              InkWell(
                                onTap: () => _openMap(_assignedStore?.storeName ?? 'Lulu Hypermarket - Al Barsha'),
                                borderRadius: BorderRadius.circular(6),
                                child: const Row(
                                  children: [
                                    Icon(Icons.directions_rounded, size: 14, color: AppTheme.accent),
                                    SizedBox(width: 4),
                                    Text(
                                      'Maps',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.accent),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppTheme.success.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                                ),
                                child: const Center(
                                  child: Icon(Icons.storefront_rounded, color: AppTheme.success, size: 22),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _assignedStore?.storeName ?? 'Lulu Hypermarket - Al Barsha',
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textMain,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_assignedStore?.retailer ?? "Lulu"} • ${_assignedStore?.emirate ?? "Dubai"} Region',
                                      style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: AppTheme.borderSubtle),
                          const SizedBox(height: 14),

                          // Shift & Break Times
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Shift Timings', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                                    const SizedBox(height: 4),
                                    Text(
                                      _myShift != null ? '${_myShift!.startTime.substring(0, 5)} – ${_myShift!.endTime.substring(0, 5)}' : '02:00 PM – 10:00 PM',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textMain,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Scheduled Break', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                                    const SizedBox(height: 4),
                                    Text(
                                      _myShift?.breakTimings ?? '05:00 PM – 05:45 PM',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.warningText,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Daily Field Routine Checklist
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                        border: Border.all(color: AppTheme.borderSubtle, width: 1.1),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DAILY FIELD CHECKLIST',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildChecklistItem(0, 'Wear branded uniform & visible store badge'),
                          _buildChecklistItem(1, 'Display stand sanitization & sample stock check'),
                          _buildChecklistItem(2, 'Record daily customer tasting / interaction counter'),
                          _buildChecklistItem(3, 'Final stock count & supervisor sign-off'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Supervisor Hotline Card
                    LiquidGlassContainer(
                      radius: 22.0,
                      blur: 20.0,
                      opacity: 0.82,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ASSIGNED FIELD SUPERVISOR',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: AppTheme.purpleBg,
                                      child: const Icon(Icons.supervisor_account_rounded, color: AppTheme.purple, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _assignedStore?.supervisorName.isNotEmpty == true ? _assignedStore!.supervisorName : 'Babar (Lead)',
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textMain),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _assignedStore?.supervisorPhone.isNotEmpty == true ? _assignedStore!.supervisorPhone : '+971 50 123 4567',
                                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontFamily: 'monospace'),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton.filled(
                                    style: IconButton.styleFrom(backgroundColor: AppTheme.infoBg, foregroundColor: AppTheme.accent),
                                    icon: const Icon(Icons.phone_rounded, size: 18),
                                    onPressed: () => _makeCall(_assignedStore?.supervisorPhone ?? '+971501234567'),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filled(
                                    style: IconButton.styleFrom(backgroundColor: AppTheme.successBg, foregroundColor: AppTheme.success),
                                    icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                                    onPressed: () => _openWhatsApp(_assignedStore?.supervisorPhone ?? '+971501234567'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildChecklistItem(int index, String title) {
    final checked = _checklist[index];
    return InkWell(
      onTap: () => setState(() => _checklist[index] = !_checklist[index]),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: checked ? AppTheme.success : AppTheme.borderStrong,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: checked ? AppTheme.textSecondary : AppTheme.textMain,
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
