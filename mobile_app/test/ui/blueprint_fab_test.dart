import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/atoms/blueprint_fab.dart';

void main() {
  Future<void> pumpFab(
    WidgetTester tester, {
    required VoidCallback onPressed,
    IconData icon = Icons.history,
    String tooltip = 'History',
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: BlueprintFab(
            onPressed: onPressed,
            icon: icon,
            tooltip: tooltip,
          ),
        ),
      ),
    );
  }

  testWidgets('renders the history icon and a semantic tooltip', (
    tester,
  ) async {
    await pumpFab(tester, onPressed: () {});

    expect(find.byType(BlueprintFab), findsOneWidget);
    expect(find.byIcon(Icons.history), findsOneWidget);
    expect(find.byTooltip('History'), findsOneWidget);
  });

  testWidgets('invokes onPressed when tapped', (tester) async {
    var tapped = false;
    await pumpFab(tester, onPressed: () => tapped = true);

    await tester.tap(find.byType(BlueprintFab));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
