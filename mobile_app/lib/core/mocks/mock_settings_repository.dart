import '../data/settings_repository.dart';
import '../mocks/mock_routine_repository.dart';
import '../models/routine_models.dart';

/// In-memory test double for [SettingsRepository], seeded from the shared
/// mock workout routines.
class MockSettingsRepository implements SettingsRepository {
  MockSettingsRepository({List<WorkoutDay>? records})
      : _records = records ?? List.of(mockWorkoutRoutines);

  final List<WorkoutDay> _records;

  @override
  Future<List<WorkoutDay>> getRecords() async => List.of(_records);

  @override
  Future<void> updateRecordFocus(int id, String focus) async {
    final index = _records.indexWhere((r) => r.id == id);
    if (index < 0) return;
    final record = _records[index];
    _records[index] = WorkoutDay(
      id: record.id,
      weekday: record.weekday,
      focus: focus,
      exercises: record.exercises,
    );
  }

  @override
  Future<void> deleteRecord(int id) async {
    _records.removeWhere((r) => r.id == id);
  }
}
