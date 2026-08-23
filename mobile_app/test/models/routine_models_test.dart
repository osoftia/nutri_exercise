import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/models/routine_models.dart';

void main() {
  group('Exercise', () {
    test('fromJson and toJson round-trip', () {
      const exercise = Exercise(
        id: 1001,
        name: 'Bench Press',
        muscleGroup: 'Chest',
        sets: 4,
        reps: '8-12',
        restSeconds: 90,
      );
      final restored = Exercise.fromJson(exercise.toJson());
      expect(restored.id, 1001);
      expect(restored.name, 'Bench Press');
      expect(restored.muscleGroup, 'Chest');
      expect(restored.sets, 4);
      expect(restored.reps, '8-12');
      expect(restored.restSeconds, 90);
    });
  });

  group('WorkoutDay', () {
    test('fromJson and toJson round-trip', () {
      const day = WorkoutDay(
        id: 1,
        weekday: 'Monday',
        focus: 'Chest & Triceps',
        exercises: [
          Exercise(
            id: 1,
            name: 'Bench',
            muscleGroup: 'Chest',
            sets: 4,
            reps: '8-12',
            restSeconds: 90,
          ),
        ],
      );
      final restored = WorkoutDay.fromJson(day.toJson());
      expect(restored.id, 1);
      expect(restored.weekday, 'Monday');
      expect(restored.focus, 'Chest & Triceps');
      expect(restored.exercises, hasLength(1));
      expect(restored.exercises.first.name, 'Bench');
    });
  });
}
