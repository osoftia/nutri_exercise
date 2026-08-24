import '../models/routine_models.dart';

/// Contract for the Settings screen's saved-record management (view/edit/delete).
abstract interface class SettingsRepository {
  /// Returns all saved routine records.
  Future<List<WorkoutDay>> getRecords();

  /// Updates the focus area of the record with [id].
  Future<void> updateRecordFocus(int id, String focus);

  /// Deletes the record with [id].
  Future<void> deleteRecord(int id);
}
