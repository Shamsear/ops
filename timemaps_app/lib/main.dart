import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IMLOpsApp());
}

class IMLOpsApp extends StatelessWidget {
  const IMLOpsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IML Ops Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}

/// Backward compatibility alias
typedef TimeMapsApp = IMLOpsApp;
