import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timemaps_app/screens/ops_dashboard_screen.dart';
import 'package:timemaps_app/screens/supervisor_hub_screen.dart';
import 'package:timemaps_app/models/models.dart';
import 'package:timemaps_app/theme/app_theme.dart';

void main() {
  for (int tab = 0; tab < 4; tab++) {
    testWidgets('Test OpsDashboardScreen tab $tab layout and overflow', (tester) async {
      final origOnError = FlutterError.onError;
      final errors = <FlutterErrorDetails>[];
      FlutterError.onError = (details) {
        errors.add(details);
      };

      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        FlutterError.onError = origOnError;
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: OpsDashboardScreen(initialTab: tab),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      if (errors.isNotEmpty) {
        print('=== TAB $tab ERRORS (${errors.length}) ===');
        for (final err in errors) {
          print(err.toString());
        }
      }
      expect(errors, isEmpty, reason: 'Tab $tab has ${errors.length} layout errors');
    });
  }

  testWidgets('Test SupervisorHubScreen layout and overflow', (tester) async {
    final origOnError = FlutterError.onError;
    final errors = <FlutterErrorDetails>[];
    FlutterError.onError = (details) {
      errors.add(details);
    };

    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      FlutterError.onError = origOnError;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final dummyUser = UserModel(id: 1, name: 'Babar Supervisor', role: 'SUPERVISOR', phone: '+971501234567', email: 'babar@imlme.com');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: SupervisorHubScreen(supervisor: dummyUser),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    if (errors.isNotEmpty) {
      print('=== SUPERVISOR HUB ERRORS (${errors.length}) ===');
      for (final err in errors) {
        print(err.toString());
      }
    }
    expect(errors, isEmpty, reason: 'SupervisorHub has ${errors.length} layout errors');
  });
}
