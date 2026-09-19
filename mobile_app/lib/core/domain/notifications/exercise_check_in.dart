import 'dart:convert';

import '../popups/exercise_completion.dart';

/// Structured payload carried by the daily workout check-in notification.
///
/// The notification action buttons only carry a `String` payload, so the
/// planned exercises (with sets, reps and load) are JSON-encoded here and
/// decoded again by the background/foreground handlers. This gives the
/// notification path full parity with the in-app manual check-in.
class ExerciseCheckIn {
  /// Creates a check-in from [exercises].
  const ExerciseCheckIn({required this.exercises});

  /// The JSON `type` tag that identifies this payload.
  static const String typeTag = 'exercise_check_in';

  /// The exercises carried by the payload.
  final List<CompletedExercise> exercises;

  /// Whether the payload has no exercises.
  bool get isEmpty => exercises.isEmpty;

  /// Summed completed sets.
  int get totalSets {
    var total = 0;
    for (final exercise in exercises) {
      total += exercise.completedSets;
    }
    return total;
  }

  /// Builds a one-set completion for every name.
  ///
  /// Used as a fallback when the notification carried no structured payload
  /// (e.g. an older scheduled reminder).
  factory ExerciseCheckIn.fromNames(Iterable<String> names) {
    return ExerciseCheckIn(
      exercises: [
        for (final name in names)
          CompletedExercise(
            name: name,
            plannedSets: 1,
            completedSets: 1,
            reps: 1,
            loadKg: 0,
          ),
      ],
    );
  }

  /// Encodes this check-in to a JSON string.
  String encode() => jsonEncode({
        'type': typeTag,
        'exercises': [
          for (final exercise in exercises)
            {
              'name': exercise.name,
              'plannedSets': exercise.plannedSets,
              'completedSets': exercise.completedSets,
              'reps': exercise.reps,
              'loadKg': exercise.loadKg,
            },
        ],
      });

  /// Parses [raw] into a check-in, returning `null` for any malformed or
  /// foreign payload so callers can fall back gracefully.
  static ExerciseCheckIn? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return null;
    }
    if (decoded is! Map) return null;
    if (decoded['type'] != typeTag) return null;

    final list = decoded['exercises'];
    if (list is! List) return null;

    final exercises = <CompletedExercise>[];
    for (final item in list) {
      if (item is! Map) return null;
      final name = item['name'];
      if (name is! String) return null;
      exercises.add(
        CompletedExercise(
          name: name,
          plannedSets: _readInt(item['plannedSets']) ?? 1,
          completedSets: _readInt(item['completedSets']) ?? 1,
          reps: _readInt(item['reps']) ?? 1,
          loadKg: _readDouble(item['loadKg']) ?? 0,
        ),
      );
    }

    return ExerciseCheckIn(exercises: exercises);
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  static double? _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is ExerciseCheckIn && _listEquals(other.exercises, exercises);

  @override
  int get hashCode => Object.hashAll(exercises);

  @override
  String toString() => 'ExerciseCheckIn(${exercises.length} exercises)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
