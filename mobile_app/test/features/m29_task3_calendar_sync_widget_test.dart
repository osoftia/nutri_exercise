import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/config/environment_config.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_log_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/models/daily_entry.dart';
import 'package:nutri_mobile_app/core/mocks/mock_diet_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_routine_repository.dart';
import 'package:nutri_mobile_app/core/providers/environment_provider.dart';
import 'package:nutri_mobile_app/core/providers/routine_provider.dart';
import 'package:nutri_mobile_app/core/providers/wizard_provider.dart';
import 'package:nutri_mobile_app/core/state/daily_log_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/pages/home_page.dart';
import 'package:provider/provider.dart';

String today() => DailyEntry.dateKey(DateTime.now());

void main() {
  late MockDailyEntryRepository entries;

  Future<void> pumpHome(WidgetTester tester) async {
    entries = MockDailyEntryRepository();
    tester.view.physicalSize = const Size(1000, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final dailyLogController = DailyLogController(
      repository: MockDailyLogRepository(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => EnvironmentProvider(
              config: EnvironmentConfig.fromFlavor(Flavor.dev),
            ),
          ),
          ListenableProxyProvider<EnvironmentProvider, RoutineProvider>(
            update: (_, env, __) =>
                RoutineProvider(env.routineRepository)..loadRoutine(),
          ),
          ListenableProxyProvider<EnvironmentProvider, RoutineWizardProvider>(
            update: (_, env, __) =>
                RoutineWizardProvider(env.routineRepository),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: HomePage(
            dietRepository: MockDietRepository(),
            routineRepository: MockRoutineRepository(),
            dailyEntryRepository: entries,
            dailyLogController: dailyLogController,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 50));
  }


  testWidgets('Quick Add persists today entry with the added calories', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(find.byKey(const Key('quick_add_button')));
    await tester.pump();

    final entry = await entries.getByDate(today());
    expect(entry, isNotNull);
    expect(entry!.calories, 650);
    expect(entry.healthyMeals, greaterThan(0));
  });

  testWidgets('the Daily Log action persists today entry', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byKey(const Key('daily_log_action')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('daily_log_input')),
      'Ate chicken and trained legs',
    );
    await tester.tap(find.byKey(const Key('daily_log_save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(await entries.getByDate(today()), isNotNull);
  });

  testWidgets('the calendar marks the logged day', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byKey(const Key('quick_add_button')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('history_action')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final dayCell = find.byKey(Key('calendar_day_${today()}'));
    expect(dayCell, findsOneWidget);
    expect(
      find.descendant(of: dayCell, matching: find.byIcon(Icons.circle)),
      findsOneWidget,
    );
  });
}
