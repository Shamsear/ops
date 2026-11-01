import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
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
          MaterialPageRoute(builder: (_) => const OpsDashboardScreen()),
        );
      } else if (user.role == 'PROMOTER') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PromoterHomeScreen(promoterUser: user)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SupervisorHubScreen(supervisor: user)),
        );
      }
    } else {
      setState(() {
        _errorMessage = 'Invalid email or password. Please try again.';
      });
    }
  }

  void _quickFill(String email, String role) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = role == 'OPS_ADMIN' ? 'admin123' : (role == 'PROMOTER' ? 'admin123' : 'super123');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppTheme.borderSubtle, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Brand Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryDark,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.map_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'TimeMaps™',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryDark,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'Field Operations Platform',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMain,
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFF87171)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppTheme.danger, fontSize: 13),
                          ),
                        ),

                      // Email input
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMuted),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password input
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textMuted),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppTheme.textMuted,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Submit button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Sign In to TimeMaps'),
                      ),

                      const SizedBox(height: 24),
                      const Divider(color: AppTheme.borderSubtle),
                      const SizedBox(height: 12),

                      // Quick-fill buttons for instant testing
                      const Text(
                        'Quick-Fill Demo Users:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ActionChip(
                            label: const Text('Ops Director', style: TextStyle(fontSize: 12)),
                            onPressed: () => _quickFill('ops@imlme.com', 'OPS_ADMIN'),
                            backgroundColor: const Color(0xFFEFF6FF),
                          ),
                          ActionChip(
                            label: const Text('Supervisor Babar', style: TextStyle(fontSize: 12)),
                            onPressed: () => _quickFill('babar@imlme.com', 'SUPERVISOR'),
                            backgroundColor: const Color(0xFFF1F5F9),
                          ),
                          ActionChip(
                            label: const Text('Supervisor Jasheer', style: TextStyle(fontSize: 12)),
                            onPressed: () => _quickFill('jasheer@imlme.com', 'SUPERVISOR'),
                            backgroundColor: const Color(0xFFF1F5F9),
                          ),
                          ActionChip(
                            label: const Text('Promoter Sony', style: TextStyle(fontSize: 12)),
                            onPressed: () => _quickFill('sony@imlme.com', 'PROMOTER'),
                            backgroundColor: const Color(0xFFECFDF5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
