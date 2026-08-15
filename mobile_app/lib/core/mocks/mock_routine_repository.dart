import '../data/routine_repository.dart';
import '../models/routine_models.dart';
import 'mock_routine_payload.dart';

final mockWorkoutRoutines =
    mockRoutineApiPayload.map(WorkoutDay.fromJson).toList(growable: false);

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
