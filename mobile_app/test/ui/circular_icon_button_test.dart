import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/atoms/circular_icon_button.dart';
import 'package:nutri_mobile_app/ui/molecules/circular_icon_button_group.dart';

void main() {
  Future<void> pumpButton(
    WidgetTester tester, {
    required String tooltip,
    VoidCallback? onPressed,
    bool selected = false,
    IconData icon = Icons.healing,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Center(
            child: CircularIconButton(
              icon: icon,
              tooltip: tooltip,
              onPressed: onPressed,
              selected: selected,
            ),
          ),
        ),
      ),
    );
  }

  group('CircularIconButton', () {
    testWidgets('renders a clear graphic icon', (tester) async {
      await pumpButton(tester, tooltip: 'Pain', onPressed: () {});

      expect(find.byType(CircularIconButton), findsOneWidget);
      expect(find.byIcon(Icons.healing), findsOneWidget);
    });

    testWidgets('exposes a long-press tooltip explaining its function', (
      tester,
    ) async {
      await pumpButton(tester, tooltip: 'Pain — tap to log severity');

      // The tooltip is registered for long-press activation.
      expect(find.byTooltip('Pain — tap to log severity'), findsOneWidget);

      await tester.longPress(find.byType(CircularIconButton));
      await tester.pumpAndSettle();

      expect(find.text('Pain — tap to log severity'), findsWidgets);
    });

    testWidgets('invokes onPressed when tapped', (tester) async {
      var tapped = false;
      await pumpButton(tester, tooltip: 'Pain', onPressed: () => tapped = true);

      await tester.tap(find.byType(CircularIconButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('provides ample padding inside a large circular target', (
      tester,
    ) async {
      await pumpButton(tester, tooltip: 'Pain', onPressed: () {});

      final size = tester.getSize(find.byType(CircularIconButton));
      expect(size.width, greaterThanOrEqualTo(CircularIconButton.minimumSize));
      expect(size.height, greaterThanOrEqualTo(CircularIconButton.minimumSize));
      expect(CircularIconButton.defaultPadding, greaterThanOrEqualTo(12));

      final padding = tester.widget<Padding>(
        find.descendant(
          of: find.byType(CircularIconButton),
          matching: find.byType(Padding),
        ),
      );
      expect(
        padding.padding,
        const EdgeInsets.all(CircularIconButton.defaultPadding),
      );
    });

    testWidgets('marks the selected state for assistive tech', (tester) async {
      await pumpButton(
        tester,
        tooltip: 'Pain',
        onPressed: () {},
        selected: true,
      );

      final semantics = tester.getSemantics(find.byType(CircularIconButton));
      expect(semantics.hasFlag(SemanticsFlag.isSelected), isTrue);
    });

    testWidgets('is disabled when no callback is supplied', (tester) async {
      await pumpButton(tester, tooltip: 'Pain');

      final semantics = tester.getSemantics(find.byType(CircularIconButton));
      expect(semantics.hasFlag(SemanticsFlag.isEnabled), isFalse);
    });
  });

  group('CircularIconButtonGroup', () {
    testWidgets('spaces its buttons generously apart', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: CircularIconButtonGroup(
              children: [
                CircularIconButton(
                  icon: Icons.healing,
                  tooltip: 'Pain',
                  onPressed: () {},
                ),
                CircularIconButton(
                  icon: Icons.bolt,
                  tooltip: 'Energy',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      final wrap = tester.widget<Wrap>(find.byType(Wrap));
      expect(
        wrap.spacing,
        greaterThanOrEqualTo(CircularIconButtonGroup.defaultSpacing),
      );
      expect(CircularIconButtonGroup.defaultSpacing, greaterThanOrEqualTo(16));

      final first = tester.getRect(find.byTooltip('Pain'));
      final second = tester.getRect(find.byTooltip('Energy'));
      expect(
        second.left - first.right,
        greaterThanOrEqualTo(CircularIconButtonGroup.defaultSpacing),
      );
    });
  });
}
