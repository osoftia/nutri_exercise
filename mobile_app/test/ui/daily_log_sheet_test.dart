import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_log_repository.dart';
import 'package:nutri_mobile_app/core/models/daily_log.dart';
import 'package:nutri_mobile_app/core/state/daily_log_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/molecules/daily_log_sheet.dart';

Widget _wrap(Widget child) => MaterialApp(theme: AppTheme.dark, home: Scaffold(body: child));

void main() {
  testWidgets('renders the input field and prompt', (tester) async {
    final controller = DailyLogController(
      repository: MockDailyLogRepository(),
    );
    await tester.pumpWidget(_wrap(DailyLogSheet(controller: controller)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('daily_log_input')), findsOneWidget);
    expect(find.text('What did you eat and train today?'), findsOneWidget);
  });

  testWidgets('pre-fills an existing summary for the day', (tester) async {
    final today = DailyLog.dateKey(DateTime.now());
    final controller = DailyLogController(
      repository: MockDailyLogRepository(seed: {today: 'Trained legs'}),
    );
    await tester.pumpWidget(_wrap(DailyLogSheet(controller: controller)));
    await tester.pumpAndSettle();

    final input = tester.widget<TextField>(find.byKey(const Key('daily_log_input')));
    expect(input.controller?.text, 'Trained legs');
  });

  testWidgets('typing and saving persists the summary and closes the sheet', (
    tester,
  ) async {
    final repo = MockDailyLogRepository();
    final controller = DailyLogController(repository: repo);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDailyLogSheet(context, controller),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('daily_log_input')),
      'Ate chicken and rice, trained chest',
    );
    await tester.tap(find.byKey(const Key('daily_log_save')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('daily_log_sheet')), findsNothing);
    expect((await repo.getByDate(controller.date))?.text,
        'Ate chicken and rice, trained chest');
  });
}
