import '../models/ai_diagnosis.dart';

/// Offline persistence contract for generated clinical reports and preferences.
abstract interface class AiDiagnosisStore {
  Future<void> save(AiDiagnosisReport report);

  Future<AiDiagnosisReport?> latest();

  Future<List<AiDiagnosisReport>> all();

  Future<String> loadFoodPreferences();

  Future<void> saveFoodPreferences(String preferences);
}
