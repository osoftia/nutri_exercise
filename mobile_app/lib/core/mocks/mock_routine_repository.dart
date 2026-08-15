import '../data/routine_repository.dart';
import '../models/routine_models.dart';
import 'mock_routine_payload.dart';

/// Parsed snapshot of [mockRoutineApiPayload] for quick access
/// (e.g. seeding the local database).
final List<WorkoutDay> mockWorkoutRoutines =
    mockRoutineApiPayload.map(WorkoutDay.fromJson).toList(growable: false);

/// In-memory mock implementation of [RoutineRepository].
///
/// Simulates network latency via [latency] so UI states (loading, error,
/// success) can be exercised during development without a live backend.
class MockRoutineRepository implements RoutineRepository {
  MockRoutineRepository({this.latency = const Duration(milliseconds: 500)});

  final Duration latency;

  @override
  Future<List<WorkoutDay>> getWeeklyRoutine() async {
    await Future<void>.delayed(latency);
    return mockRoutineApiPayload
        .map(WorkoutDay.fromJson)
        .toList(growable: false);
  }

  @override
  Future<String> generateRoutine(String userPreferences) async {
    await Future<void>.delayed(latency);
    final description = mockGeneratedRoutineApiPayload['description'] as String;
    return description.replaceFirst('{userPreferences}', userPreferences);
  }
}
