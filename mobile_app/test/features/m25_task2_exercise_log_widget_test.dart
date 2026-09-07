import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/config/environment_config.dart';
import 'package:nutri_mobile_app/core/mocks/mock_diet_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_routine_repository.dart';
import 'package:nutri_mobile_app/core/models/routine_models.dart';
import 'package:nutri_mobile_app/core/providers/environment_provider.dart';
import 'package:nutri_mobile_app/core/providers/routine_provider.dart';
import 'package:nutri_mobile_app/core/providers/wizard_provider.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/molecules/exercise_card.dart';
import 'package:nutri_mobile_app/ui/pages/home_page.dart';
import 'package:provider/provider.dart';

void main() {
  const exercise = Exercise(
    id: 1001,
    name: 'Bench Press',
    muscleGroup: 'Chest',
    sets: 4,
    reps: '8-12',
    restSeconds: 90,
  );

  testWidgets('ExerciseCard shows a log control that reports taps', (
    tester,
  ) async {
    var loggedCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: ExerciseCard(
            exercise: exercise,
            onLog: () => loggedCalls++,
          ),
        ),
      ),
    );

    final logControl = find.byKey(const Key('log_exercise_Bench Press'));
    expect(logControl, findsOneWidget);

    await tester.tap(logControl);
    expect(loggedCalls, 1);
  });

  testWidgets('ExerciseCard reflects the logged state via a check icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: ExerciseCard(exercise: exercise, isLogged: true),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets(
    'Home dashboard logs and unlogs an exercise from the Exercises section',
    (tester) async {
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

      final logControl = find.byKey(const Key('log_exercise_Bench Press'));
      expect(logControl, findsOneWidget);

      await tester.tap(logControl);
      await tester.pump();
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      await tester.tap(logControl);
      await tester.pump();
      expect(find.byIcon(Icons.check_circle), findsNothing);
    },
  );
}