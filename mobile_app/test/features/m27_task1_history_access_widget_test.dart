import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/app.dart';
import 'package:nutri_mobile_app/core/config/app_config.dart';

void main() {
  testWidgets('main app bar exposes History and opens the calendar editor', (
    tester,
  ) async {
    await tester.pumpWidget(
      NutriApp(config: const AppConfig(name: 'dev', useMocks: true)),
    );
    await tester.pumpAndSettle();

    final historyAction = find.byKey(const Key('history_action'));
    expect(historyAction, findsOneWidget);

    await tester.tap(historyAction);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calendar_history_dialog')), findsOneWidget);
  });
}