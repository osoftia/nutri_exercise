import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/popups/exercise_completion.dart';
import 'package:nutri_mobile_app/core/services/workout_summary_calculator.dart';
import 'package:nutri_mobile_app/core/state/muscle_tamagotchi_state.dart';
import 'package:nutri_mobile_app/core/state/workout_completion_controller.dart';

CompletedExercise _exercise({
  required String name,
  required int planned,
  required int completed,
}) =>
    CompletedExercise(
      name: name,
      plannedSets: planned,
      completedSets: completed,
      reps: 8,
      loadKg: 60,
    );

class _SummaryExample {
  const _SummaryExample(this.name, this.completed, this.planned, this.burned, this.recovery);

  final String name;
  final int completed;
  final int planned;
  final int burned;
  final String recovery;
}

void main() {
  const calculator = WorkoutSummaryCalculator();

  group('M38 workout summary calculator', () {
    const examples = <_SummaryExample>[
      _SummaryExample('Bench Press', 4, 4, 250, 'recovered'),
      _SummaryExample('Squat', 2, 4, 250, 'recovering'),
      _SummaryExample('Deadlift', 0, 3, 0, 'fatigued'),
    ];

    for (final example in examples) {
      test('${example.name} ${example.completed}/${example.planned} is '
          '${example.recovery}', () {
        final summary = calculator.summarize(
          date: '2026-09-18',
          exercises: [
            _exercise(
              name: example.name,
              planned: example.planned,
              completed: example.completed,
            ),
          ],
        );

        expect(summary.caloriesBurned, example.burned);
        expect(summary.exercises, hasLength(1));

        final region = switch (example.name) {
          'Bench Press' => 'chest',
          'Squat' => 'thighs',
          _ => 'thighs',
        };
        expect(
          summary.recovery[region],
          RecoveryLevel.values.byName(example.recovery),
        );
      });
    }

    test('totals sets, reps and volume', () {
      final summary = calculator.summarize(
        date: '2026-09-18',
        exercises: [
          _exercise(name: 'Bench Press', planned: 4, completed: 4),
          _exercise(name: 'Squat', planned: 4, completed: 2),
        ],
      );

      expect(summary.totalSets, 6);
      expect(summary.totalReps, 6 * 8);
      expect(summary.totalVolume, 6 * 8 * 60);
      expect(summary.caloriesBurned, 500);
      expect(summary.isEmpty, isFalse);
    });

    test('an empty workout is empty and burns nothing', () {
      final summary = calculator.summarize(date: '2026-09-18', exercises: const []);
      expect(summary.isEmpty, isTrue);
      expect(summary.caloriesBurned, 0);
      expect(summary.recovery, isEmpty);
    });
  });

  group('M38 exercise completion value objects', () {
    test('CompletedExercise derives completion and volume', () {
      final complete = _exercise(name: 'Bench Press', planned: 4, completed: 4);
      final partial = _exercise(name: 'Squat', planned: 4, completed: 2);
      final none = _exercise(name: 'Deadlift', planned: 3, completed: 0);

      expect(complete.isComplete, isTrue);
      expect(partial.isComplete, isFalse);
      expect(complete.volume, 4 * 8 * 60);
      expect(none.remainingSets, 3);
      expect(complete, equals(complete.copyWith()));
      expect(complete.hashCode, equals(complete.copyWith().hashCode));
      expect(complete.copyWith(name: 'X').name, 'X');
      expect(complete.toString(), contains('Bench Press'));
      expect(complete, isNot(equals(partial)));
    });

    test('ExerciseCompletionSummary copies and compares', () {
      final summary = calculator.summarize(
        date: '2026-09-18',
        exercises: [_exercise(name: 'Bench Press', planned: 4, completed: 4)],
      );
      expect(summary, equals(summary.copyWith()));
      expect(summary.hashCode, equals(summary.copyWith().hashCode));
      expect(summary.copyWith(date: 'x').date, 'x');
      expect(summary.toString(), contains('ExerciseCompletionSummary'));
      expect(summary, isNot(equals(summary.copyWith(date: 'x'))));
    });

    test('summary equality compares exercise and recovery contents', () {
      final bench = calculator.summarize(
        date: 'd',
        exercises: [_exercise(name: 'Bench Press', planned: 4, completed: 4)],
      );
      final squat = calculator.summarize(
        date: 'd',
        exercises: [_exercise(name: 'Squat', planned: 4, completed: 4)],
      );
      expect(bench, isNot(equals(squat)));

      final fatigued = bench.copyWith(
        recovery: {
          for (final region in bench.recovery.keys)
            region: RecoveryLevel.fatigued,
        },
      );
      expect(bench, isNot(equals(fatigued)));
      expect(bench.recovery, isNot(equals(fatigued.recovery)));
    });
  });

  group('M38 WorkoutCompletionController', () {
    test('confirm builds the summary and grows the tamagotchi', () async {
      final tamagotchi = MuscleTamagotchiState();
      final controller = WorkoutCompletionController(tamagotchi: tamagotchi);
      final before = tamagotchi.massOf(MuscleTamagotchiGroup.chest);

      await controller.confirm([
        _exercise(name: 'Bench Press', planned: 4, completed: 4),
      ]);

      expect(controller.summary, isNotNull);
      expect(controller.summary!.caloriesBurned, 250);
      expect(controller.isConfirming, isFalse);
      expect(
        tamagotchi.massOf(MuscleTamagotchiGroup.chest),
        greaterThan(before),
      );
    });

    test('confirm notifies listeners', () async {
      final controller = WorkoutCompletionController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.confirm([
        _exercise(name: 'Squat', planned: 4, completed: 2),
      ]);

      expect(notifications, greaterThan(0));
    });
  });
}
