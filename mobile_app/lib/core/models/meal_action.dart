/// A single meal quick-logged from a notification action button.
class MealAction {
  const MealAction({
    required this.date,
    required this.meal,
    required this.timeOfDay,
    this.createdAt,
  });

  /// The calendar date (`YYYY-MM-DD`) the meal was logged for.
  final String date;

  /// The meal name (e.g. "Pechuga con arroz").
  final String meal;

  /// The meal slot (`breakfast` | `lunch` | `dinner`).
  final String timeOfDay;

  final DateTime? createdAt;

  Map<String, Object?> toMap() => {
    'date': date,
    'meal': meal,
    'time_of_day': timeOfDay,
    'created_at': createdAt?.toIso8601String() ?? '',
  };

  static MealAction fromMap(Map<String, Object?> map) => MealAction(
    date: map['date'] as String,
    meal: map['meal'] as String,
    timeOfDay: (map['time_of_day'] as String?) ?? '',
    createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
  );
}