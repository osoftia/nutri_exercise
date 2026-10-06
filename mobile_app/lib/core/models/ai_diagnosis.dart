import 'dart:convert';

/// One meal entry in a tailored AI-generated menu.
class AiSuggestedMeal {
  const AiSuggestedMeal({required this.name, this.description = ''});

  final String name;
  final String description;

  factory AiSuggestedMeal.fromJson(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return AiSuggestedMeal(name: value.trim());
    }
    if (value is Map) {
      final name = value['name'] ?? value['meal'] ?? value['title'];
      if (name is String && name.trim().isNotEmpty) {
        final description = value['description'];
        return AiSuggestedMeal(
          name: name.trim(),
          description: description is String ? description.trim() : '',
        );
      }
    }
    throw const FormatException('A suggested meal must have a name.');
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description.isNotEmpty) 'description': description,
      };
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

  factory AiSuggestedMenu.fromJson(Map<String, dynamic> json) {
    final name = json['name'] ?? json['title'] ?? json['day'];
    final rawMeals = json['meals'];
    if (name is! String || name.trim().isEmpty || rawMeals is! List) {
      throw const FormatException('A suggested menu needs a name and meals.');
    }
    final day = json['day'];
    return AiSuggestedMenu(
      name: name.trim(),
      day: day is String ? day.trim() : '',
      meals: rawMeals.map(AiSuggestedMeal.fromJson).toList(growable: false),
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

  factory AiDiagnosisReport.fromJson(
    Map<String, dynamic> json, {
    required List<String> conditionIds,
    required String foodPreferences,
    required String language,
    DateTime? createdAt,
  }) {
    final title = json['title'];
    final summary = json['summary'];
    final considerations = json['considerations'];
    final rawMenus = json['menus'];
    if (title is! String ||
        title.trim().isEmpty ||
        summary is! String ||
        summary.trim().isEmpty ||
        considerations is! List ||
        rawMenus is! List) {
      throw const FormatException('Malformed clinical report response.');
    }
    final parsedConsiderations = considerations.map((item) {
      if (item is! String || item.trim().isEmpty) {
        throw const FormatException('Invalid report consideration.');
      }
      return item.trim();
    }).toList(growable: false);
    return AiDiagnosisReport(
      title: title.trim(),
      summary: summary.trim(),
      considerations: parsedConsiderations,
      conditionIds: List.unmodifiable(conditionIds),
      foodPreferences: foodPreferences,
      language: language,
      menus: rawMenus
          .map((menu) => AiSuggestedMenu.fromJson(menu as Map<String, dynamic>))
          .toList(growable: false),
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
