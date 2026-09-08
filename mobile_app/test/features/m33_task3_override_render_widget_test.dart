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

Future<void> _pumpHome(WidgetTester tester) async {
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
        ),
      ),
    ),
  );

  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 50));
}

dynamic _bodyMapPainter(WidgetTester tester) {
  final painted = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(InteractiveBodyMap).first,
      matching: find.byType(CustomPaint),
    ),
  );
  return painted.painter!;
}

void main() {
  testWidgets('selecting an exercise highlights it with override colors',
      (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.text('Bench Press'));
    await tester.pump();

    final painter = _bodyMapPainter(tester);
    expect(painter.selectedMuscle, 'chest');
    final tamagotchi = painter.tamagotchiState as MuscleTamagotchiState?;
    expect(tamagotchi, isNotNull);
    expect(tamagotchi!.regionColorOverrides['chest'], Colors.red);
    expect(tamagotchi.regionColorOverrides['upper_arms'], Colors.orange);
  });

  testWidgets('override updates repaint the map with a new revision',
      (tester) async {
    await _pumpHome(tester);

    final before = _bodyMapPainter(tester).revision as int;
    final tamagotchi =
        _bodyMapPainter(tester).tamagotchiState as MuscleTamagotchiState;
    tamagotchi.setOverrides(const {'thighs': Colors.red});
    await tester.pump();

    final after = _bodyMapPainter(tester);
    expect(after.revision as int, greaterThan(before));
    expect(
      (after.tamagotchiState as MuscleTamagotchiState)
          .regionColorOverrides['thighs'],
      Colors.red,
    );
  });
}
