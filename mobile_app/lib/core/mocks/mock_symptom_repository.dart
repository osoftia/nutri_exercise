import '../data/symptom_repository.dart';
import '../models/symptom_log.dart';

/// In-memory [SymptomRepository] used by tests and mock builds.
class MockSymptomRepository implements SymptomRepository {
  MockSymptomRepository([List<SymptomLog>? seed]) : _store = [...?seed];

  final List<SymptomLog> _store;

  @override
  Future<List<SymptomLog>> getForDate(String date) async =>
      _store.where((log) => log.date == date).toList();

  @override
  Future<List<SymptomLog>> getAll() async => List.unmodifiable(_store);

  @override
  Future<void> save(SymptomLog log) async {
    _store.removeWhere(
      (existing) =>
          existing.date == log.date && existing.symptom == log.symptom,
    );
    _store.add(log);
  }
}
