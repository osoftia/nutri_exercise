import 'dart:convert';

Map<String, dynamic> _stringKeyedMap(Object? value) {
  if (value is! Map) return const {};
  final map = <String, dynamic>{};
  for (final entry in value.entries) {
    if (entry.key is String) map[entry.key as String] = entry.value;
  }
  return map;
}

List<Object?> _jsonList(Object? value) {
  if (value is List) return value.cast<Object?>();
  if (value is Map) return [value];
  if (value is String && value.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) return decoded.cast<Object?>();
      if (decoded is Map) return [decoded];
    } on FormatException {
      return [value];
    }
    return [value];
  }
  return const [];
}

String _text(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  if (value is num) return '$value';
  if (value is Map) {
    final map = _stringKeyedMap(value);
    for (final key in const ['text', 'content', 'message', 'description']) {
      final candidate = map[key];
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
  }
  return fallback;
}

int _integerValue(Object? value) {
  if (value is num) return value.round();
  if (value is String) return num.tryParse(value.trim())?.round() ?? 0;
  return 0;
}

/// One meal entry in a tailored AI-generated menu.
class MealSuggestion {
  const MealSuggestion({
    required this.name,
    this.description = '',
    this.calories = 0,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
  });

  final String name;
  final String description;
  final int calories;
  final int proteinG;
  final int carbsG;
  final int fatG;

  factory MealSuggestion.fromJson(Object? value, {String language = 'en'}) {
    if (value is String && value.trim().isNotEmpty) {
      return MealSuggestion(name: value.trim());
    }
    final map = _stringKeyedMap(value);
    return MealSuggestion(
      // Bind to the backend value exactly: when it omits a name, keep it empty
      // instead of injecting generic educational placeholder copy.
      name: _text(
        map['name'] ??
            map['meal'] ??
            map['title'] ??
            map['mealName'] ??
            map['foodName'],
      ),
      description: _text(map['description'] ?? map['details'] ?? map['notes']),
      calories: _integerValue(map['calories'] ?? map['caloriesKcal']),
      proteinG: _integerValue(map['proteinG'] ?? map['protein']),
      carbsG: _integerValue(map['carbsG'] ?? map['carbs']),
      fatG: _integerValue(map['fatG'] ?? map['fat']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description.isNotEmpty) 'description': description,
        'calories': calories,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
      };
}

/// Backwards-compatible name used by the app's nutrition view.
class AiSuggestedMeal extends MealSuggestion {
  const AiSuggestedMeal({
    required super.name,
    super.description,
    super.calories,
    super.proteinG,
    super.carbsG,
    super.fatG,
  });

  factory AiSuggestedMeal.fromJson(Object? value, {String language = 'en'}) {
    final meal = MealSuggestion.fromJson(value, language: language);
    return AiSuggestedMeal(
      name: meal.name,
      description: meal.description,
      calories: meal.calories,
      proteinG: meal.proteinG,
      carbsG: meal.carbsG,
      fatG: meal.fatG,
    );
  }
}

/// One generated menu in a report's suggested weekly plan.
class AiSuggestedMenu {
  const AiSuggestedMenu({
    required this.name,
    this.day = '',
    required this.meals,
    this.id,
    this.diagnosisId,
  });

  final int? id;
  final int? diagnosisId;
  final String name;
  final String day;
  final List<AiSuggestedMeal> meals;

  factory AiSuggestedMenu.fromJson(Object? value, {String language = 'en'}) {
    final json = _stringKeyedMap(value);
    final day = _text(json['day']);
    final menuName = _text(json['name'] ?? json['title'] ?? day);
    final rawMeals =
        _jsonList(json['meals'] ?? json['suggestions'] ?? json['items']);
    return AiSuggestedMenu(
      name: menuName,
      day: day,
      meals: [
        for (final meal in rawMeals)
          if (meal != null) AiSuggestedMeal.fromJson(meal, language: language),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'day': day,
        'meals': meals.map((meal) => meal.toJson()).toList(),
      };
}

/// Structured educational report and its associated locally cached menus.
class AiDiagnosisReport {
  const AiDiagnosisReport({
    required this.title,
    required this.summary,
    required this.considerations,
    required this.conditionIds,
    required this.foodPreferences,
    required this.language,
    required this.menus,
    required this.createdAt,
    this.responseJson = '',
    this.id,
  });

  final int? id;
  final DateTime createdAt;
  final String title;
  final String summary;
  final List<String> considerations;
  final List<String> conditionIds;
  final String foodPreferences;
  final String language;
  final List<AiSuggestedMenu> menus;

  /// Exact successful JSON body returned by the clinical diagnosis service.
  final String responseJson;

  factory AiDiagnosisReport.fromJson(
    Map<String, dynamic> json, {
    required List<String> conditionIds,
    required String foodPreferences,
    required String language,
    String responseJson = '',
    DateTime? createdAt,
  }) {
    // Exact backend binding: prefer the documented `diagnosticReport` and
    // `mealSuggestions` payload keys, and never substitute generic educational
    // placeholder copy when a field is absent.
    final rawDiagnostic = json['diagnosticReport'];
    final diagnosticMap = rawDiagnostic is Map
        ? _stringKeyedMap(rawDiagnostic)
        : const <String, dynamic>{};
    final title = _text(
      json['title'] ??
          json['diagnosisTitle'] ??
          json['name'] ??
          diagnosticMap['title'],
    );
    final summary = _text(
      rawDiagnostic is String && rawDiagnostic.trim().isNotEmpty
          ? rawDiagnostic
          : (diagnosticMap['summary'] ??
              diagnosticMap['report'] ??
              diagnosticMap['diagnosis']),
      fallback: _text(
        json['summary'] ??
            json['diagnosis'] ??
            json['description'] ??
            json['message'],
      ),
    );
    final rawConsiderations = json['considerations'] ??
        json['recommendations'] ??
        json['notes'] ??
        diagnosticMap['considerations'];
    final considerations =
        rawConsiderations is String && _jsonList(rawConsiderations).isEmpty
            ? [rawConsiderations]
            : _jsonList(rawConsiderations);
    final parsedConsiderations = <String>[
      for (final item in considerations)
        if (_text(item).isNotEmpty) _text(item),
    ];
    final mealSuggestions = _jsonList(json['mealSuggestions']);
    final rawMenus = mealSuggestions.isNotEmpty
        ? <Object?>[
            {
              'name': _text(json['mealSuggestionsTitle']),
              'day': '',
              'meals': mealSuggestions,
            },
          ]
        : _jsonList(
            json['menus'] ?? json['suggestedMenus'] ?? json['weeklyMenus'],
          );
    return AiDiagnosisReport(
      title: title.trim(),
      summary: summary.trim(),
      considerations: parsedConsiderations,
      conditionIds: List.unmodifiable(conditionIds),
      foodPreferences: foodPreferences,
      language: language,
      menus: rawMenus
          .where((menu) => menu != null)
          .map((menu) => AiSuggestedMenu.fromJson(menu, language: language))
          .toList(growable: false),
      responseJson: responseJson,
      createdAt: createdAt ?? DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'summary': summary,
        'considerations': considerations,
        'conditionIds': conditionIds,
        'foodPreferences': foodPreferences,
        'language': language,
        'menus': menus.map((menu) => menu.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  /// Decodes JSON lists stored in SQLite without leaking mutable collections.
  static List<String> decodeStringList(String raw) =>
      (jsonDecode(raw) as List<dynamic>).cast<String>();
}
