import '../models/routine_models.dart';

abstract interface class RoutineRepository {
  Future<List<WorkoutDay>> getWeeklyRoutine();
}
