import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timemaps_app/screens/operations_menu_page.dart';
import 'package:timemaps_app/theme/app_theme.dart';

void main() {
  final widths = [320.0, 360.0, 390.0, 430.0];
  final textScales = [1.0, 1.3];

  for (final width in widths) {
    for (final scale in textScales) {
      testWidgets('OperationsMenuPage zero overflow and complete text on ${width.toInt()}px at scale $scale', (tester) async {
        FlutterErrorDetails? errorDetails;
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.toString().contains('overflowed by')) {
            errorDetails = details;
          }
          originalOnError?.call(details);
        };

        tester.view.physicalSize = Size(width, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          FlutterError.onError = originalOnError;
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1200),
                textScaler: TextScaler.linear(scale),
              ),
              child: const OperationsMenuPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(errorDetails, isNull, reason: 'Encountered overflow error on ${width.toInt()}px at scale $scale');

        // Verify full action titles exist
        expect(find.text('Assign Morning Drop-off'), findsOneWidget);
        expect(find.text('Assign Return Collection'), findsOneWidget);
        expect(find.text('Batch Shift Scheduler'), findsOneWidget);
        expect(find.text('Security Badge & Gate Pass'), findsOneWidget);
        expect(find.text('Promoter Audit Scorecard'), findsOneWidget);
        expect(find.text('New Campaign Project'), findsOneWidget);
      });
    }
  }
}
