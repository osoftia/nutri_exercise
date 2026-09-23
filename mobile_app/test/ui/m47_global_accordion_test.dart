import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/molecules/accordion_section.dart';

void main() {
  Future<void> pumpAccordion(
    WidgetTester tester, {
    bool initiallyExpanded = false,
    bool subtitleInHeaderWhenExpanded = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: AccordionSection(
            headerKey: const Key('acc_header'),
            title: 'Daily symptoms',
            subtitle: 'Long-press an icon to see what it tracks',
            icon: Icons.healing,
            initiallyExpanded: initiallyExpanded,
            subtitleInHeaderWhenExpanded: subtitleInHeaderWhenExpanded,
            child: const Text('BODY'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('M47 global accordion pattern — title-only collapsed state', () {
    testWidgets('collapsed shows only the title (no subtitle)', (tester) async {
      await pumpAccordion(tester);

      expect(find.text('Daily symptoms'), findsOneWidget);
      expect(
        find.text('Long-press an icon to see what it tracks'),
        findsNothing,
      );
      expect(find.text('BODY'), findsNothing);
    });

    testWidgets('expanding reveals the subtitle and content', (tester) async {
      await pumpAccordion(tester);

      await tester.tap(find.byKey(const Key('acc_header')));
      await tester.pumpAndSettle();

      expect(find.text('BODY'), findsOneWidget);
      // Subtitle moves into the revealed body by default.
      expect(
        find.text('Long-press an icon to see what it tracks'),
        findsOneWidget,
      );
    });

    testWidgets('subtitle can stay in the header while expanded', (
      tester,
    ) async {
      await pumpAccordion(
        tester,
        initiallyExpanded: true,
        subtitleInHeaderWhenExpanded: true,
      );

      // When expanded with the header-subtitle option, the subtitle is part
      // of the always-visible header region.
      expect(find.text('BODY'), findsOneWidget);
      expect(
        find.text('Long-press an icon to see what it tracks'),
        findsWidgets,
      );
    });

    testWidgets('collapsing hides the subtitle again', (tester) async {
      await pumpAccordion(tester, initiallyExpanded: true);

      await tester.tap(find.byKey(const Key('acc_header')));
      await tester.pumpAndSettle();

      expect(
        find.text('Long-press an icon to see what it tracks'),
        findsNothing,
      );
      expect(find.text('BODY'), findsNothing);
    });
  });
}
