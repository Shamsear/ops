import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timemaps_app/widgets/searchable_select_field.dart';

void main() {
  testWidgets('SearchableSelectField filters and creates custom value', (tester) async {
    String? selectedValue = 'India';
    String? submittedCustom;

    final options = const [
      SearchableOption<String>(value: 'India', label: 'India'),
      SearchableOption<String>(value: 'Philippines', label: 'Philippines'),
      SearchableOption<String>(value: 'Pakistan', label: 'Pakistan'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SearchableSelectField<String>(
                label: 'Country',
                value: selectedValue,
                options: options,
                allowCustomValue: true,
                onChanged: (val) => setState(() => selectedValue = val),
                onCustomValueSubmitted: (val) => setState(() {
                  selectedValue = val;
                  submittedCustom = val;
                }),
              );
            },
          ),
        ),
      ),
    );

    // Initial value is displayed
    expect(find.text('India'), findsOneWidget);

    // Tap to open sheet
    await tester.tap(find.text('India'));
    await tester.pumpAndSettle();

    // Sheet title and search field are visible
    expect(find.text('Select Country'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Type "Brazil" (not in options list)
    await tester.enterText(find.byType(TextField), 'Brazil');
    await tester.pumpAndSettle();

    // Custom value tile appears
    expect(find.text('Use "Brazil"'), findsOneWidget);

    // Tap the custom value tile
    await tester.tap(find.text('Use "Brazil"'));
    await tester.pumpAndSettle();

    // Custom value is selected and displayed
    expect(selectedValue, 'Brazil');
    expect(submittedCustom, 'Brazil');
    expect(find.text('Brazil'), findsOneWidget);
  });

  testWidgets('SearchableSelectField.compact renders properly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchableSelectField<String>.compact(
            label: 'Chain',
            value: 'All',
            options: const [
              SearchableOption<String>(value: 'All', label: 'All'),
              SearchableOption<String>(value: 'Lulu', label: 'Lulu'),
            ],
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('All'), findsOneWidget);
  });
}
