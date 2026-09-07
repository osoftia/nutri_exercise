import 'dart:convert';

/// A single day's logged nutrition totals and completed exercises, stored in
/// SQLite for the calendar history.
class DailyEntry {
  const DailyEntry({
    required this.date,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.exercises = const [],
  });

  /// The calendar date this entry belongs to, in `YYYY-MM-DD` form.
  final String date;

  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  /// Names of the exercises logged as completed on this day.
  final List<String> exercises;

  /// Whether nothing meaningful has been logged for this day.
  bool get isEmpty => calories == 0 && exercises.isEmpty;

  /// Formats a [DateTime] into the `YYYY-MM-DD` key used for persistence.
  static String dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  DailyEntry copyWith({
    String? date,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    List<String>? exercises,
  }) {
    return DailyEntry(
      date: date ?? this.date,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      exercises: exercises ?? this.exercises,
    );
  }

  /// Serializes to a SQLite row map.
  Map<String, Object?> toMap() => {
    'date': date,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'exercises_json': jsonEncode(exercises),
  };

  /// Restores a [DailyEntry] from a SQLite row map produced by [toMap].
  static DailyEntry fromMap(Map<String, Object?> map) => DailyEntry(
    date: map['date'] as String,
    calories: (map['calories'] as int?) ?? 0,
    protein: (map['protein'] as int?) ?? 0,
    carbs: (map['carbs'] as int?) ?? 0,
    fat: (map['fat'] as int?) ?? 0,
    exercises: _decodeExercises(map['exercises_json'] as String?),
  );

  static List<String> _decodeExercises(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded.whereType<String>().toList();
  }
}