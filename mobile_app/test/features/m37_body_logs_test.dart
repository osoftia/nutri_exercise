import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/muscle_gap_advisor.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/muscle_workout_log.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/nutrition_log.dart';

const _oatmeal = LoggedFood(
  name: 'Oatmeal',
  portion: '1 bowl',
  calories: 420,
  proteinG: 10,
  carbsG: 60,
  fatG: 12,
  time: '08:10',
);

const _chicken = LoggedFood(
  name: 'Chicken',
  portion: '200 g',
  calories: 650,
  proteinG: 45,
  carbsG: 55,
  fatG: 18,
  time: '13:20',
);

void main() {
  group('M37 LoggedFood value object', () {
    test('copies every field', () {
      expect(_oatmeal.copyWith(name: 'X').name, 'X');
      expect(_oatmeal.copyWith(portion: '2 bowls').portion, '2 bowls');
      expect(_oatmeal.copyWith(calories: 1).calories, 1);
      expect(_oatmeal.copyWith(proteinG: 1).proteinG, 1);
      expect(_oatmeal.copyWith(carbsG: 1).carbsG, 1);
      expect(_oatmeal.copyWith(fatG: 1).fatG, 1);
      expect(_oatmeal.copyWith(time: '09:00').time, '09:00');
      expect(_oatmeal.copyWith(), equals(_oatmeal));
      expect(_oatmeal.hashCode, equals(_oatmeal.copyWith().hashCode));
      expect(_oatmeal.toString(), contains('Oatmeal'));
      expect(_oatmeal, isNot(equals(_oatmeal.copyWith(calories: 1))));
    });
  });

  group('M37 DailyFoodLog value object', () {
    const log = DailyFoodLog(date: '2026-09-18', entries: [_oatmeal, _chicken]);

    test('sums calories and every macro', () {
      expect(log.totalCalories, 1070);
      expect(log.totalProteinG, 55);
      expect(log.totalCarbsG, 115);
      expect(log.totalFatG, 30);
      expect(log.isEmpty, isFalse);
    });

    test('copies, compares and prints', () {
      expect(log.copyWith(), equals(log));
      expect(log.hashCode, equals(log.copyWith().hashCode));
      expect(log.copyWith(date: 'x').date, 'x');
      expect(log.copyWith(entries: const []).isEmpty, isTrue);
      expect(log.toString(), contains('DailyFoodLog'));
      expect(
        log,
        isNot(equals(log.copyWith(entries: const [_oatmeal]))),
      );
      expect(const DailyFoodLog().isEmpty, isTrue);
    });
  });

  group('M37 MuscleExerciseLog value object', () {
    const entry = MuscleExerciseLog(
      name: 'Squat',
      plannedSets: 4,
      reps: 10,
      loadKg: 60,
      completedSets: 3,
    );

    test('derives volumes, remaining sets and completion', () {
      expect(entry.plannedVolume, 2400);
      expect(entry.completedVolume, 1800);
      expect(entry.remainingSets, 1);
      expect(entry.isCompleted, isFalse);
    });

    test('clamps remaining sets and detects completion', () {
      final over = entry.copyWith(completedSets: 6);
      expect(over.remainingSets, 0);
      expect(over.isCompleted, isTrue);
    });

    test('copies, compares and prints', () {
      expect(entry.copyWith(), equals(entry));
      expect(entry.hashCode, equals(entry.copyWith().hashCode));
      expect(entry.copyWith(name: 'X').name, 'X');
      expect(entry.copyWith(plannedSets: 5).plannedSets, 5);
      expect(entry.copyWith(reps: 8).reps, 8);
      expect(entry.copyWith(loadKg: 80).loadKg, 80);
      expect(entry.copyWith(completedSets: 4).completedSets, 4);
      expect(entry.toString(), contains('Squat'));
      expect(entry, isNot(equals(entry.copyWith(reps: 1))));
    });
  });

  group('M37 MuscleWorkoutLog value object', () {
    const log = MuscleWorkoutLog(
      segment: BodySegment.rightThigh,
      periodLabel: 'This week',
      entries: [
        MuscleExerciseLog(
          name: 'Squat',
          plannedSets: 4,
          reps: 10,
          loadKg: 60,
          completedSets: 3,
        ),
        MuscleExerciseLog(
          name: 'Leg Press',
          plannedSets: 3,
          reps: 12,
          loadKg: 80,
          completedSets: 1,
        ),
      ],
    );

    test('sums sets and volumes and computes the completion ratio', () {
      expect(log.plannedSets, 7);
      expect(log.completedSets, 4);
      expect(log.plannedVolume, 2400 + 2880);
      expect(log.completedVolume, 1800 + 960);
      expect(log.completionRatio, closeTo(2760 / 5280, 0.0001));
      expect(log.isEmpty, isFalse);
    });

    test('an empty log is complete by definition', () {
      const empty = MuscleWorkoutLog(
        segment: BodySegment.chest,
        periodLabel: 'This week',
      );
      expect(empty.isEmpty, isTrue);
      expect(empty.completionRatio, 1);
      expect(empty.plannedSets, 0);
      expect(empty.completedSets, 0);
    });

    test('copies, compares and prints', () {
      expect(log.copyWith(), equals(log));
      expect(log.hashCode, equals(log.copyWith().hashCode));
      expect(log.copyWith(segment: BodySegment.chest).segment, BodySegment.chest);
      expect(log.copyWith(periodLabel: 'Today').periodLabel, 'Today');
      expect(log.copyWith(entries: const []).isEmpty, isTrue);
      expect(log.toString(), contains('rightThigh'));
      expect(log, isNot(equals(log.copyWith(periodLabel: 'Today'))));
    });

    test('gap context exposes volume, ratio and remaining sets', () {
      final context = MuscleGapContext(
        segment: BodySegment.rightThigh,
        workout: log,
      );
      expect(context.plannedVolume, log.plannedVolume);
      expect(context.completedVolume, log.completedVolume);
      expect(context.volumeGap, closeTo(log.plannedVolume - log.completedVolume, 0.0001));
      expect(context.completionRatio, log.completionRatio);
      expect(context.remainingSets, 3);
    });
  });
}
