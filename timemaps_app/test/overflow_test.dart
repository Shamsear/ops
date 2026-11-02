import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timemaps_app/dev/overflow_gallery.dart';
import 'package:timemaps_app/theme/app_theme.dart';

void main() {
  final widths = [320.0, 360.0, 390.0, 430.0];
  final textScales = [1.0, 1.3];

  for (final width in widths) {
    for (final scale in textScales) {
      testWidgets('Zero overflow on ${width.toInt()}px at scale $scale', (tester) async {
        // Track Flutter overflow errors
        FlutterErrorDetails? errorDetails;
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          if (details.toString().contains('overflowed by')) {
            errorDetails = details;
          }
          originalOnError?.call(details);
        };

        tester.view.physicalSize = Size(width, 800);
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
                size: Size(width, 800),
                textScaler: TextScaler.linear(scale),
              ),
              child: const OverflowGalleryScreen(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(errorDetails, isNull, reason: 'Encountered overflow error on ${width.toInt()}px at scale $scale');
      });
    }
  }
}
