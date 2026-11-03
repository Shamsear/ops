import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'ops_dashboard_screen.dart';
import 'supervisor_hub_screen.dart';
import 'promoter_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController(text: 'ops@imlme.com');
  final TextEditingController _passwordController = TextEditingController(text: 'admin123');
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String _selectedPersonaEmail = 'ops@imlme.com';

  bool _isPersonaSelected(String email) =>
      _selectedPersonaEmail == email ||
      _emailController.text.trim().toLowerCase() == email.toLowerCase();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = await ApiService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    if (user != null && mounted) {
      if (user.role == 'OPS_ADMIN') {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const OpsDashboardScreen(),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          ),
        );
      } else if (user.role == 'PROMOTER') {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => PromoterHomeScreen(promoterUser: user),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => SupervisorHubScreen(supervisor: user),
            transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
          ),
        );
      }
    } else {
      setState(() {
        _errorMessage = 'Invalid credentials. Please verify your email & password.';
      });
    }
  }

  void _selectPersona({required String email, required String role, required String password}) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
      _selectedPersonaEmail = email;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Brand Hero
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(AppRadius.card),
                                  border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                                  boxShadow: AppShadows.card,
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Image.asset(
                                  'assets/images/iml_logo_dark.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.warehouse_rounded,
                                    color: AppColors.primary,
                                    size: 32,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              const Text(
                                'IML Ops',
                                style: AppText.display,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Warehouse & UAE National Field Operations',
                                style: AppText.bodySmall.copyWith(color: AppColors.textMuted),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              const StatusBadge(
                                label: '74+ Retail Stores Synchronized',
                                variant: StatusVariant.success,
                                showDot: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Credentials Card
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SectionHeader(
                                icon: Icons.lock_open_rounded,
                                iconColor: AppColors.primary,
                                microLabel: 'Authentication',
                                title: 'Sign In to Operations',
                              ),
                              if (_errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.dangerSoft,
                                    borderRadius: BorderRadius.circular(AppRadius.inner),
                                    border: Border.all(color: AppColors.statusBorder(AppColors.danger)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 16),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: AppText.caption.copyWith(
                                            color: AppColors.danger,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                              ],
                              AppTextField(
                                controller: _emailController,
                                label: 'Work Email Address',
                                hint: 'e.g. ops@imlme.com',
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AppTextField(
                                controller: _passwordController,
                                label: 'Account Password',
                                hint: 'Enter your password',
                                obscureText: _obscurePassword,
                                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 18,
                                    color: AppColors.textMuted,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AppButton(
                                label: 'Sign In to Operations',
                                onPressed: _handleLogin,
                                loading: _isLoading,
                                icon: Icons.arrow_forward_rounded,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Demo Persona Selection
                        const SectionHeader(
                          icon: Icons.badge_outlined,
                          iconColor: AppColors.accent,
                          microLabel: 'Quick Access',
                          title: 'One-Tap Demo Personas',
                        ),
                        Column(
                          children: [
                            _PersonaCard(
                              icon: Icons.admin_panel_settings_rounded,
                              accentColor: AppColors.accent,
                              roleLabel: 'OPS DIRECTOR',
                              name: 'Operations Director',
                              details: 'Full UAE Command & Logistics',
                              isSelected: _isPersonaSelected('ops@imlme.com'),
                              onTap: () => _selectPersona(
                                email: 'ops@imlme.com',
                                role: 'OPS_ADMIN',
                                password: 'admin123',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _PersonaCard(
                              icon: Icons.supervisor_account_rounded,
                              accentColor: AppColors.purple,
                              roleLabel: 'SUPERVISOR',
                              name: 'Babar Abdul Majeed',
                              details: 'Dubai Stores & Stand Inspections',
                              isSelected: _isPersonaSelected('babar@imlme.com'),
                              onTap: () => _selectPersona(
                                email: 'babar@imlme.com',
                                role: 'SUPERVISOR',
                                password: 'super123',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _PersonaCard(
                              icon: Icons.supervisor_account_rounded,
                              accentColor: AppColors.success,
                              roleLabel: 'SUPERVISOR',
                              name: 'Jasheer Kanhirathil',
                              details: 'Abu Dhabi Stores & Stand Inspections',
                              isSelected: _isPersonaSelected('jasheer@imlme.com'),
                              onTap: () => _selectPersona(
                                email: 'jasheer@imlme.com',
                                role: 'SUPERVISOR',
                                password: 'super123',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _PersonaCard(
                              icon: Icons.person_rounded,
                              accentColor: AppColors.warning,
                              roleLabel: 'PROMOTER',
                              name: 'Sony Mathew',
                              details: 'Lulu Hypermarket Al Barsha Shift',
                              isSelected: _isPersonaSelected('sony@imlme.com'),
                              onTap: () => _selectPersona(
                                email: 'sony@imlme.com',
                                role: 'PROMOTER',
                                password: 'admin123',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Center(
                          child: Text(
                            'IML Operations Hub • Enterprise Field Logistics',
                            style: AppText.caption,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PersonaCard extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String roleLabel;
  final String name;
  final String details;
  final bool isSelected;
  final VoidCallback onTap;

  const _PersonaCard({
    required this.icon,
    required this.accentColor,
    required this.roleLabel,
    required this.name,
    required this.details,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$roleLabel $name',
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: onTap,
        color: isSelected ? AppColors.primarySoft : AppColors.surface,
        border: isSelected
            ? BorderSide(color: AppColors.primary, width: 1.5)
            : const BorderSide(color: AppColors.borderSubtle, width: 1.0),
        child: Row(
          children: [
            IconBox(
              icon: icon,
              color: isSelected ? AppColors.primary : accentColor,
              backgroundColor: isSelected ? Colors.white : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        roleLabel,
                        style: AppText.micro.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('•', style: AppText.caption),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          name,
                          style: AppText.bodyBold.copyWith(
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    details,
                    style: AppText.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.borderStrong,
                  width: isSelected ? 5.5 : 1.5,
                ),
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
