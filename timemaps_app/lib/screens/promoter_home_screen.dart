import 'package:flutter/material.dart';
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
            backgroundColor: AppTheme.accentEmerald,
            content: Text('Shift started! Have a productive promotional day.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppTheme.primaryDark,
            content: Text('Shift ended successfully. Great job today!'),
          ),
        );
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello, ${widget.promoterUser.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textMain)),
            Text('IML Field Promoter • $_todayDateStr', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadPromoterShift,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Banner Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _isShiftActive ? const Color(0xFFECFDF5) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isShiftActive ? const Color(0xFFA7F3D0) : AppTheme.borderSubtle,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isShiftActive ? AppTheme.accentEmerald : AppTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isShiftActive ? 'ON DUTY (ACTIVE)' : 'NOT CLOCKED IN',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: _isShiftActive ? AppTheme.accentEmerald : AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                            if (_shiftStartTime != null)
                              Text(
                                'Clocked in at ${DateFormat('hh:mm a').format(_shiftStartTime!)}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontFamily: 'monospace'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Prominent 1-Tap Shift Start Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isShiftActive ? const Color(0xFFDC2626) : AppTheme.accentEmerald,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _toggleShift,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_isShiftActive ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  _isShiftActive ? 'END SHIFT FOR TODAY' : 'TAP TO START SHIFT',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Store & Shift Details Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TODAY\'S ASSIGNED STORE',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 12),

                          Text(
                            _assignedStore?.storeName ?? 'Lulu Hypermarket - Al Barsha',
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textMain),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_assignedStore?.retailer ?? "Lulu"} • ${_assignedStore?.emirate ?? "Dubai"}',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: AppTheme.borderSubtle),
                          const SizedBox(height: 16),

                          // Shift Hours & Break Times
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
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textMain, fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Break Timings', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                                    const SizedBox(height: 4),
                                    Text(
                                      _myShift?.breakTimings ?? '05:00 PM – 05:45 PM',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.accentAmber, fontFamily: 'monospace'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Supervisor Support Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ASSIGNED FIELD SUPERVISOR',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _assignedStore?.supervisorName.isNotEmpty == true ? _assignedStore!.supervisorName : 'Babar (Lead)',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textMain),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _assignedStore?.supervisorPhone.isNotEmpty == true ? _assignedStore!.supervisorPhone : '+971 50 123 4567',
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontFamily: 'monospace'),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  IconButton.filled(
                                    style: IconButton.styleFrom(backgroundColor: const Color(0xFFEFF6FF), foregroundColor: AppTheme.primary),
                                    icon: const Icon(Icons.phone_rounded, size: 20),
                                    onPressed: () => _makeCall(_assignedStore?.supervisorPhone ?? '+971501234567'),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filled(
                                    style: IconButton.styleFrom(backgroundColor: const Color(0xFFECFDF5), foregroundColor: AppTheme.accentEmerald),
                                    icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                                    onPressed: () => _openWhatsApp(_assignedStore?.supervisorPhone ?? '+971501234567'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
