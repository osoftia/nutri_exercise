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
    this.healthy,
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

  /// Explicit food-quality flag from the parser. When `null`, [isHealthy]
  /// falls back to a macro heuristic.
  final bool? healthy;

  /// Whether the meal counts as "healthy" for gamification.
  ///
  /// An explicit parser flag wins; otherwise a meal is healthy when it is
  /// high-protein (>= 20 g) and low-fat (<= 30 g).
  bool get isHealthy {
    final explicit = healthy;
    if (explicit != null) return explicit;
    final p = protein;
    if (p == null || p < 20) return false;
    final f = fat;
    return f == null || f <= 30;
  }

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
      healthy: json['healthy'] as bool?,
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
    if (healthy != null) 'healthy': healthy,
  };

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }
}
