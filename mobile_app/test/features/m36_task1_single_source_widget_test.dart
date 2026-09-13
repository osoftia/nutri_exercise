import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/config/environment_config.dart';
import 'package:nutri_mobile_app/core/mocks/mock_diet_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_routine_repository.dart';
import 'package:nutri_mobile_app/core/providers/environment_provider.dart';
import 'package:nutri_mobile_app/core/providers/routine_provider.dart';
import 'package:nutri_mobile_app/core/providers/wizard_provider.dart';
import 'package:nutri_mobile_app/core/state/muscle_tamagotchi_state.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/organisms/interactive_body_map.dart';
import 'package:nutri_mobile_app/ui/pages/home_page.dart';
import 'package:provider/provider.dart';

Future<void> _pumpHome(
  WidgetTester tester, {
  MuscleTamagotchiState? tamagotchi,
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
          update: (_, env, __) =>
              RoutineWizardProvider(env.routineRepository),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: HomePage(
          dietRepository: MockDietRepository(),
          routineRepository: MockRoutineRepository(),
          tamagotchiState: tamagotchi,
        ),
      ),
    ),
  );

  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 50));
}

dynamic _bodyMapPainter(WidgetTester tester) {
  return (tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(InteractiveBodyMap).first,
      matching: find.byType(CustomPaint),
    ),
  ).painter)!;
}

void main() {
  setUp(resetSharedMuscleTamagotchiState);
  tearDown(resetSharedMuscleTamagotchiState);

  testWidgets('HomePage watches the shared singleton by default', (
    tester,
  ) async {
    await _pumpHome(tester);

    final painted =
        _bodyMapPainter(tester).tamagotchiState as MuscleTamagotchiState;
    expect(
      identical(painted, sharedMuscleTamagotchiState),
      isTrue,
      reason: 'default HomePage must watch the single global instance',
    );
  });

  testWidgets('injected state is the exact instance the avatar paints', (
    tester,
  ) async {
    final injected = MuscleTamagotchiState();
    await _pumpHome(tester, tamagotchi: injected);

    final painted =
        _bodyMapPainter(tester).tamagotchiState as MuscleTamagotchiState;
    expect(identical(painted, injected), isTrue);

    // Mutating that exact instance re-renders the avatar (revision bump).
    final before = _bodyMapPainter(tester).revision as int;
    injected.applyGrowth(const [MuscleTamagotchiGroup.arms]);
    await tester.pump();
    expect(
      _bodyMapPainter(tester).revision as int,
      greaterThan(before),
    );
  });
}
