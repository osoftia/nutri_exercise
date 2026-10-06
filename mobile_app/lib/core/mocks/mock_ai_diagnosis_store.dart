import '../data/ai_diagnosis_store.dart';
import '../models/ai_diagnosis.dart';

/// In-memory report store for dev flavors and isolated UI tests.
class MockAiDiagnosisStore implements AiDiagnosisStore {
  final List<AiDiagnosisReport> _reports = [];
  String _foodPreferences = '';

  @override
  Future<List<AiDiagnosisReport>> all() async =>
      List.unmodifiable(_reports.reversed);

  @override
  Future<AiDiagnosisReport?> latest() async =>
      _reports.isEmpty ? null : _reports.last;

  @override
  Future<String> loadFoodPreferences() async => _foodPreferences;

  @override
  Future<void> save(AiDiagnosisReport report) async {
    _reports.add(report);
  }

  @override
  Future<void> saveFoodPreferences(String preferences) async {
    _foodPreferences = preferences.trim();
  }
}
