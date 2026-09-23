import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/molecules/accordion_section.dart';

void main() {
  Future<void> pumpAccordion(
    WidgetTester tester, {
    bool initiallyExpanded = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: AccordionSection(
            headerKey: const Key('acc_header'),
            title: 'Daily symptoms',
            subtitle: 'Long-press an icon',
            icon: Icons.healing,
            initiallyExpanded: initiallyExpanded,
            child: const Text('BODY'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AccordionSection (M46 Task 3)', () {
    testWidgets('starts collapsed and hides its body', (tester) async {
      await pumpAccordion(tester);

      expect(find.text('Daily symptoms'), findsOneWidget);
      expect(find.text('Long-press an icon'), findsNothing);
      expect(find.text('BODY'), findsNothing);
    });

    testWidgets('expands smoothly on tap and reveals the body', (tester) async {
      await pumpAccordion(tester);

      await tester.tap(find.byKey(const Key('acc_header')));
      await tester.pump();
      // Mid-animation the size is still growing (smooth, not a snap).
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('BODY'), findsOneWidget);
    });

    testWidgets('collapses again on a second tap', (tester) async {
      await pumpAccordion(tester, initiallyExpanded: true);
      expect(find.text('BODY'), findsOneWidget);

      await tester.tap(find.byKey(const Key('acc_header')));
      await tester.pumpAndSettle();

      expect(find.text('BODY'), findsNothing);
    });

    testWidgets('rotates the chevron when expanded', (tester) async {
      await pumpAccordion(tester);
      final rotation = tester.widget<AnimatedRotation>(
        find.byType(AnimatedRotation),
      );
      expect(rotation.turns, 0);

      await tester.tap(find.byKey(const Key('acc_header')));
      await tester.pumpAndSettle();

      expect(
        tester.widget<AnimatedRotation>(find.byType(AnimatedRotation)).turns,
        0.5,
      );
    });
  });
}
