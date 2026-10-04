import '../domain/body_projection/body_segment.dart';
import '../domain/body_projection/muscle_workout_log.dart';
import '../domain/body_projection/nutrition_log.dart';

/// Default food log shown before the user has persisted anything.
const DailyFoodLog bodyFoodLogSeed = DailyFoodLog(
  entries: [
    LoggedFood(
      name: 'Oatmeal & Berries',
      portion: '1 bowl',
      calories: 420,
      proteinG: 10,
      carbsG: 60,
      fatG: 12,
      saturatedFatG: 1,
      sugarsG: 7,
      fiberG: 8,
      glycemicIndex: 55,
      purinesMg: 15,
      sodiumMg: 10,
      time: '08:10',
    ),
    LoggedFood(
      name: 'Grilled Chicken Bowl',
      portion: '350 g',
      calories: 650,
      proteinG: 45,
      carbsG: 55,
      fatG: 18,
      saturatedFatG: 3,
      sugarsG: 4,
      fiberG: 5,
      glycemicIndex: 50,
      purinesMg: 180,
      sodiumMg: 620,
      time: '13:20',
    ),
    LoggedFood(
      name: 'Greek Yogurt & Almonds',
      portion: '200 g',
      calories: 240,
      proteinG: 18,
      carbsG: 18,
      fatG: 10,
      saturatedFatG: 3,
      sugarsG: 8,
      fiberG: 4,
      glycemicIndex: 35,
      purinesMg: 45,
      sodiumMg: 80,
      time: '17:05',
    ),
  ],
);

/// Planned workouts used as the baseline for the blueprint overview and the
/// exercise detail popups.
const Map<BodySegment, MuscleWorkoutLog> bodyDetailPlannedSeed = {
  BodySegment.chest: MuscleWorkoutLog(
    segment: BodySegment.chest,
    periodLabel: 'This week',
    entries: [
      MuscleExerciseLog(
        name: 'Bench Press',
        plannedSets: 4,
        reps: 8,
        loadKg: 60,
        completedSets: 3,
      ),
      MuscleExerciseLog(
        name: 'Incline Dumbbell Press',
        plannedSets: 3,
        reps: 10,
        loadKg: 22,
        completedSets: 3,
      ),
    ],
  ),
  BodySegment.leftUpperArm: MuscleWorkoutLog(
    segment: BodySegment.leftUpperArm,
    periodLabel: 'This week',
    entries: [
      MuscleExerciseLog(
        name: 'Biceps Curl',
        plannedSets: 4,
        reps: 12,
        loadKg: 14,
        completedSets: 2,
      ),
    ],
  ),
  BodySegment.rightUpperArm: MuscleWorkoutLog(
    segment: BodySegment.rightUpperArm,
    periodLabel: 'This week',
    entries: [
      MuscleExerciseLog(
        name: 'Triceps Pushdown',
        plannedSets: 4,
        reps: 12,
        loadKg: 25,
        completedSets: 4,
      ),
    ],
  ),
  BodySegment.leftThigh: MuscleWorkoutLog(
    segment: BodySegment.leftThigh,
    periodLabel: 'This week',
    entries: [
      MuscleExerciseLog(
        name: 'Squat',
        plannedSets: 4,
        reps: 10,
        loadKg: 70,
        completedSets: 4,
      ),
    ],
  ),
  BodySegment.rightThigh: MuscleWorkoutLog(
    segment: BodySegment.rightThigh,
    periodLabel: 'This week',
    entries: [
      MuscleExerciseLog(
        name: 'Squat',
        plannedSets: 4,
        reps: 10,
        loadKg: 70,
        completedSets: 3,
      ),
      MuscleExerciseLog(
        name: 'Romanian Deadlift',
        plannedSets: 3,
        reps: 10,
        loadKg: 60,
        completedSets: 1,
      ),
    ],
  ),
};
