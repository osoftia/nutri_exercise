/// Structured result returned by the backend's AI log parser
/// (`POST /api/log/parse`) for a free-text daily summary.
///
/// Assumed JSON shape (reconcile with the backend if it differs):
/// ```json
/// {
///   "calories": 650,
///   "macros": { "protein": 45, "carbs": 55, "fat": 18 },
///   "muscleGroups": ["chest", "shoulders"]
/// }
/// ```
class LogParseResponse {
  const LogParseResponse({
    required this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.muscleGroups = const [],
  });

  final int calories;

  /// Protein in grams (nullable when the backend omitted it).
  final int? protein;

  /// Carbs in grams (nullable when the backend omitted it).
  final int? carbs;

  /// Fat in grams (nullable when the backend omitted it).
  final int? fat;

  /// Muscle groups mentioned in the summary (lower-case ids).
  final List<String> muscleGroups;

  factory LogParseResponse.fromJson(Map<String, dynamic> json) {
    final macros = json['macros'];
    final macrosMap = macros is Map<String, dynamic>
        ? macros
        : const <String, dynamic>{};

    return LogParseResponse(
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: _readInt(macrosMap['protein']),
      carbs: _readInt(macrosMap['carbs']),
      fat: _readInt(macrosMap['fat']),
      muscleGroups: (json['muscleGroups'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
    );
  }

  /// Serializes back to the JSON shape produced by [fromJson] so parsed results
  /// can be cached in SQLite.
  Map<String, dynamic> toJson() => {
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'muscleGroups': muscleGroups,
  };

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }
}
