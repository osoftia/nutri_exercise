import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/core/mocks/mock_body_detail_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_projection_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_tamagotchi_progress_repository.dart';
import 'package:nutri_mobile_app/core/services/rule_based_muscle_gap_advisor.dart';
import 'package:nutri_mobile_app/core/state/body_detail_controller.dart';
import 'package:nutri_mobile_app/core/state/muscle_tamagotchi_state.dart';
import 'package:nutri_mobile_app/core/state/projection_controller.dart';
import 'package:nutri_mobile_app/core/state/workout_completion_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/organisms/body_blueprint/body_blueprint_painter.dart';
import 'package:nutri_mobile_app/ui/pages/routines_page.dart';

void main() {
  group('M42 live weight & mass reactivity', () {
    test('confirming and undoing a workout rescales the chest instantly', () async {
      final tamagotchi = MuscleTamagotchiState();
      final repository = MockBodyDetailRepository();
      final detail = BodyDetailController(
        repository: repository,
        advisor: const RuleBasedMuscleGapAdvisor(),
        tamagotchi: tamagotchi,
      );
      await detail.loadOverview();
      final completion = WorkoutCompletionController(
        tamagotchi: tamagotchi,
        repository: repository,
      );

      final before = detail.buildViewModel().scaleFor(BodySegment.chest);

      await completion.confirm(detail.plannedExercises());
      await detail.refreshWorkouts();
      final grown = detail.buildViewModel().scaleFor(BodySegment.chest);
      expect(grown, greaterThan(before));

      await completion.undo();
      await detail.refreshWorkouts();
      expect(
        detail.buildViewModel().scaleFor(BodySegment.chest),
        lessThan(grown),
      );

      detail.dispose();
    });

    test('persisted muscle mass drives the diagram after a restart', () async {
      final progressRepository = MockTamagotchiProgressRepository();
      final first = MuscleTamagotchiState(repository: progressRepository);
      first.applyGrowth(const [MuscleTamagotchiGroup.chest]);
      await Future<void>.delayed(Duration.zero);

      final restored = MuscleTamagotchiState(repository: progressRepository);
      await restored.restore();

      final detail = BodyDetailController(
        repository: MockBodyDetailRepository(),
        advisor: const RuleBasedMuscleGapAdvisor(),
        tamagotchi: restored,
      );

      expect(
        detail.buildViewModel().scaleFor(BodySegment.chest),
        greaterThan(1.0),
      );
      detail.dispose();
    });

    testWidgets('the Routines toggle morphs the painted blueprint figure', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final tamagotchi = MuscleTamagotchiState();
      final repository = MockBodyDetailRepository();
      final detail = BodyDetailController(
        repository: repository,
        advisor: const RuleBasedMuscleGapAdvisor(),
        tamagotchi: tamagotchi,
      );
      final completion = WorkoutCompletionController(
        tamagotchi: tamagotchi,
        repository: repository,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: RoutinesPage(
              controller: ProjectionController(
                repository: MockProjectionRepository(),
              ),
              detailController: detail,
              workoutCompletionController: completion,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      double paintedChestScale() {
        final painter = tester
            .widget<CustomPaint>(find.byKey(const Key('body_blueprint_paint')))
            .painter! as BodyBlueprintPainter;
        return painter.viewModel.scaleFor(BodySegment.chest);
      }

      final before = paintedChestScale();

      await tester.tap(find.byKey(const Key('confirm_workout_toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('exercise_completion_close')));
      await tester.pumpAndSettle();

      expect(paintedChestScale(), greaterThan(before));
    });
  });
}
