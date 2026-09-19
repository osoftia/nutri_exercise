import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_diagram_builder.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/muscle_workout_log.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/nutrition_log.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/segment_status.dart';
import 'package:nutri_mobile_app/core/models/food_entry.dart';

/// One row of the "Segment statuses are assembled" Scenario Outline.
class _AssembleExample {
  const _AssembleExample(
    this.segment,
    this.kcal,
    this.target,
    this.completed,
    this.planned,
    this.status,
  );

  final String segment;
  final int kcal;
  final int target;
  final int completed;
  final int planned;
  final String status;
}

const _targets = MacroTargets(protein: 150, carbs: 250, fat: 70);

DailyFoodLog _foodLog(int kcal) {
  if (kcal == 0) return const DailyFoodLog();
  return DailyFoodLog(
    entries: [
      LoggedFood(
        name: 'Test meal',
        portion: '1 plate',
        calories: kcal,
        proteinG: 40,
        carbsG: 60,
        fatG: 20,
        time: '12:00',
      ),
    ],
  );
}

MuscleWorkoutLog? _workout(int completed, int planned) {
  if (planned == 0) return null;
  return MuscleWorkoutLog(
    segment: BodySegment.rightThigh,
    periodLabel: 'This week',
    entries: [
      MuscleExerciseLog(
        name: 'Squat',
        plannedSets: planned,
        reps: 10,
        loadKg: 60,
        completedSets: completed,
      ),
    ],
  );
}

void main() {
  const builder = BodyDiagramBuilder();

  group('M37 body diagram builder (domain, pure)', () {
    const examples = <_AssembleExample>[
      _AssembleExample('rightThigh', 0, 2000, 12, 12, 'balanced'),
      _AssembleExample('rightThigh', 0, 2000, 6, 12, 'critical'),
      _AssembleExample('rightThigh', 0, 2000, 9, 12, 'warning'),
      _AssembleExample('abdomen', 2900, 2000, 0, 0, 'critical'),
      _AssembleExample('abdomen', 0, 2000, 0, 0, 'noData'),
    ];

    for (final example in examples) {
      test(
        '${example.segment} kcal=${example.kcal} '
        '${example.completed}/${example.planned} -> ${example.status}',
        () {
          final segment = BodySegment.values.byName(example.segment);
          final workout = _workout(example.completed, example.planned);
          final viewModel = builder.build(
            foodLog: _foodLog(example.kcal),
            workouts: workout == null
                ? const {}
                : {BodySegment.rightThigh: workout},
            calorieTarget: example.target,
            macroTargets: _targets,
          );

          expect(
            viewModel.statusFor(segment),
            SegmentStatus.values.byName(example.status),
          );
        },
      );
    }

    test('assembles the stomach callout from the food total', () {
      final viewModel = builder.build(
        foodLog: _foodLog(1840),
        workouts: const {},
        calorieTarget: 2000,
        macroTargets: _targets,
      );

      final callout = viewModel.calloutFor(BodySegment.abdomen);
      expect(callout, isNotNull);
      expect(callout!.label, 'STOMACH');
      expect(callout.value, '1840 kcal');
    });

    test('assembles a limb callout from completed versus planned sets', () {
      final viewModel = builder.build(
        foodLog: const DailyFoodLog(),
        workouts: {BodySegment.rightThigh: _workout(9, 12)!},
        calorieTarget: 2000,
        macroTargets: _targets,
      );

      final callout = viewModel.calloutFor(BodySegment.rightThigh);
      expect(callout, isNotNull);
      expect(callout!.value, '9/12 sets');
    });

    test('carries projection scale factors through to the view model', () {
      final viewModel = builder.build(
        foodLog: const DailyFoodLog(),
        workouts: const {},
        calorieTarget: 2000,
        macroTargets: _targets,
        scaleFactors: const {BodySegment.chest: 1.3},
      );

      expect(viewModel.scaleFor(BodySegment.chest), 1.3);
    });

    test('keeps the selected segment', () {
      final viewModel = builder.build(
        foodLog: const DailyFoodLog(),
        workouts: const {},
        calorieTarget: 2000,
        macroTargets: _targets,
        selectedSegment: BodySegment.chest,
      );

      expect(viewModel.selectedSegment, BodySegment.chest);
    });
  });
}
