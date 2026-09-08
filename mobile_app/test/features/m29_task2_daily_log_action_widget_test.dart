import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/config/environment_config.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_log_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_diet_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_routine_repository.dart';
import 'package:nutri_mobile_app/core/providers/environment_provider.dart';
import 'package:nutri_mobile_app/core/providers/routine_provider.dart';
import 'package:nutri_mobile_app/core/providers/wizard_provider.dart';
import 'package:nutri_mobile_app/core/state/daily_log_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/pages/home_page.dart';
import 'package:provider/provider.dart';

Future<void> _pumpHome(
  WidgetTester tester, {
  DailyLogController? dailyLogController,
}) async {
  tester.view.physicalSize = const Size(1000, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

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
          update: (_, env, __) => RoutineWizardProvider(env.routineRepository),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: HomePage(
          dietRepository: MockDietRepository(),
          routineRepository: MockRoutineRepository(),
          dailyLogController: dailyLogController,
        ),
      ),
    ),
  );

  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('Daily Log section shows a header and an action button', (
    tester,
  ) async {
    final controller = DailyLogController(
      repository: MockDailyLogRepository(),
    );
    await _pumpHome(tester, dailyLogController: controller);

    expect(find.text('Daily Log'), findsOneWidget);
    expect(find.byKey(const Key('daily_log_action')), findsOneWidget);
  });

  testWidgets('tapping the action button opens the quick logging sheet', (
    tester,
  ) async {
    final controller = DailyLogController(
      repository: MockDailyLogRepository(),
    );
    await _pumpHome(tester, dailyLogController: controller);

    await tester.tap(find.byKey(const Key('daily_log_action')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('daily_log_sheet')), findsOneWidget);
  });

  testWidgets('the section is hidden when no controller is provided', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.text('Daily Log'), findsNothing);
    expect(find.byKey(const Key('daily_log_action')), findsNothing);
  });
}