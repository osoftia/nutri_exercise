import '../mocks/mock_routine_payload.dart';
import '../models/routine_models.dart';

/// Best-effort extraction of structured [Exercise]s from the free-form AI
/// description returned by the backend.
///
/// The C# backend currently returns the generated routine as prose in
/// `Routine.Description`. This parser matches exercise names against a
/// canonical catalog built from the mock payload so that persisted routines
/// carry muscle-group metadata even when the API does not emit structured
/// exercises.
List<Exercise> parseDescriptionToExercises(String text) {
  final lower = text.toLowerCase();
  final matched = <Exercise>[];
  final seen = <String>{};
  for (final exercise in _catalog) {
    final name = exercise.name.toLowerCase();
    if (seen.add(name) && lower.contains(name)) {
      matched.add(exercise);
    }
  }
  return matched;
}

/// Canonical exercise library built once from the mock API payload.
final List<Exercise> _catalog = _buildCatalog();

List<Exercise> _buildCatalog() {
  final catalog = <Exercise>[];
  final seen = <String>{};
  for (final day in mockRoutineApiPayload) {
    final exercises = day['exercises'];
    if (exercises is! List) continue;
    for (final raw in exercises) {
      if (raw is! Map<String, dynamic>) continue;
      final exercise = Exercise.fromJson(raw);
      if (seen.add(exercise.name.toLowerCase())) {
        catalog.add(exercise);
      }
    }
  }
  return catalog;
}