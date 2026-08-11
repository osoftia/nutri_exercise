import '../models/routine_models.dart';

abstract interface class RoutineRepository {
  Future<List<WorkoutDay>> getWeeklyRoutine();

  /// Requests an AI-generated workout routine for [userPreferences].
  /// Returns the generated routine text.
  Future<String> generateRoutine(String userPreferences);
}
