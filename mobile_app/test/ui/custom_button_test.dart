import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/ui/atoms/custom_button.dart';

void main() {
  group('CustomButton', () {
    testWidgets('renders the primary variant as an elevated button', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomButton(label: 'Save', variant: CustomButtonVariant.primary),
          ),
        ),
      );
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('renders the ghost variant as an outlined button', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomButton(label: 'Cancel', variant: CustomButtonVariant.ghost),
          ),
        ),
      );
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('renders the text variant as a text button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomButton(label: 'Link', variant: CustomButtonVariant.text),
          ),
        ),
      );
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('disabled buttons have no onPressed callback', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomButton(label: 'Disabled', disabled: true),
          ),
        ),
      );
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('tapping invokes the onPressed callback', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(label: 'Tap', onPressed: () => tapped++),
          ),
        ),
      );
      await tester.tap(find.text('Tap'));
      expect(tapped, 1);
    });
  });
}
