import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/config/environment_config.dart';
import 'package:nutri_mobile_app/core/mocks/mock_diet_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_routine_repository.dart';
import 'package:nutri_mobile_app/core/providers/environment_provider.dart';
import 'package:nutri_mobile_app/core/providers/routine_provider.dart';
import 'package:nutri_mobile_app/core/providers/wizard_provider.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/organisms/interactive_body_map.dart';
import 'package:nutri_mobile_app/ui/pages/home_page.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Quick Add button sits directly below the InteractiveBodyMap', (
    tester,
  ) async {
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
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 50));

    final quickAdd = find.byKey(const Key('quick_add_button'));
    final bodyMap = find.byType(InteractiveBodyMap);

    expect(quickAdd, findsOneWidget);
    expect(bodyMap, findsOneWidget);

    final quickAddRect = tester.getRect(quickAdd);
    final bodyMapRect = tester.getRect(bodyMap);

    expect(quickAddRect.top, greaterThanOrEqualTo(bodyMapRect.bottom));
  });

  testWidgets('tapping Quick Add logs a default meal into the daily totals', (
    tester,
  ) async {
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
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('0 kcal'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quick_add_button')));
    await tester.pump();

    expect(find.text('650 kcal'), findsOneWidget);
  });
}