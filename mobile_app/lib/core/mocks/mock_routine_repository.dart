import '../data/routine_repository.dart';
import '../models/routine_models.dart';

const mockWorkoutRoutines = <WorkoutDay>[
  WorkoutDay(
    id: 1,
    weekday: 'Monday',
    focus: 'Chest & Triceps',
    exercises: [
      Exercise(
        id: 1001,
        name: 'Bench Press',
        muscleGroup: 'Chest',
        sets: 4,
        reps: '8-12',
        restSeconds: 90,
      ),
      Exercise(
        id: 1002,
        name: 'Incline Dumbbell Press',
        muscleGroup: 'Chest',
        sets: 3,
        reps: '10-12',
        restSeconds: 90,
      ),
      Exercise(
        id: 1003,
        name: 'Triceps Pushdown',
        muscleGroup: 'Triceps',
        sets: 3,
        reps: '12-15',
        restSeconds: 60,
      ),
    ],
  ),
  WorkoutDay(
    id: 2,
    weekday: 'Wednesday',
    focus: 'Back & Biceps',
    exercises: [
      Exercise(
        id: 2001,
        name: 'Deadlift',
        muscleGroup: 'Back',
        sets: 4,
        reps: '5-8',
        restSeconds: 120,
      ),
      Exercise(
        id: 2002,
        name: 'Lat Pulldown',
        muscleGroup: 'Back',
        sets: 3,
        reps: '10-12',
        restSeconds: 90,
      ),
      Exercise(
        id: 2003,
        name: 'Barbell Curl',
        muscleGroup: 'Biceps',
        sets: 3,
        reps: '10-12',
        restSeconds: 60,
      ),
    ],
  ),
  WorkoutDay(
    id: 3,
    weekday: 'Friday',
    focus: 'Legs & Core',
    exercises: [
      Exercise(
        id: 3001,
        name: 'Squat',
        muscleGroup: 'Legs',
        sets: 4,
        reps: '6-10',
        restSeconds: 120,
      ),
      Exercise(
        id: 3002,
        name: 'Leg Press',
        muscleGroup: 'Legs',
        sets: 3,
        reps: '10-12',
        restSeconds: 90,
      ),
      Exercise(
        id: 3003,
        name: 'Plank',
        muscleGroup: 'Core',
        sets: 3,
        reps: '60 sec',
        restSeconds: 45,
      ),
    ],
  ),
];

class MockRoutineRepository implements RoutineRepository {
  @override
  Future<List<WorkoutDay>> getWeeklyRoutine() {
    return Future.delayed(
      const Duration(milliseconds: 500),
      () => mockWorkoutRoutines,
    );
  }
}
