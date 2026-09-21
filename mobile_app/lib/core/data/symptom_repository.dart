import '../models/symptom_log.dart';

/// Contract for reading and persisting daily symptom readings.
abstract interface class SymptomRepository {
  /// Returns every logged symptom for [date].
  Future<List<SymptomLog>> getForDate(String date);

  /// Returns every stored symptom reading.
  Future<List<SymptomLog>> getAll();

  /// Persists (upserts) one symptom reading for its date.
  Future<void> save(SymptomLog log);
}
