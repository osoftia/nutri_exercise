import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/atoms/neumorphic_fab.dart';

void main() {
  Future<void> pumpFab(
    WidgetTester tester, {
    required VoidCallback onPressed,
    IconData icon = Icons.smart_toy_outlined,
    String tooltip = 'Ask AI',
    double size = 56,
    Color color = AppColors.primary500,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: NeumorphicFab(
            onPressed: onPressed,
            icon: icon,
            tooltip: tooltip,
            size: size,
            color: color,
          ),
        ),
      ),
    );
  }

  testWidgets('renders the icon and exposes a semantic tooltip', (
    tester,
  ) async {
    await pumpFab(tester, onPressed: () {});

    expect(find.byType(NeumorphicFab), findsOneWidget);
    expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);
    expect(find.byTooltip('Ask AI'), findsOneWidget);
  });

  testWidgets('invokes onPressed when tapped', (tester) async {
    var tapped = false;
    await pumpFab(tester, onPressed: () => tapped = true);

    await tester.tap(find.byType(NeumorphicFab));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('honours a custom icon, tooltip and color', (tester) async {
    await pumpFab(
      tester,
      onPressed: () {},
      icon: Icons.send,
      tooltip: 'Send',
      color: AppColors.accent,
    );

    expect(find.byIcon(Icons.send), findsOneWidget);
    expect(find.byTooltip('Send'), findsOneWidget);
  });
}
