import '../domain/clinical/clinical_condition_profile.dart';

/// Typed request contract for the clinical nutrition report endpoint.
class AiDiagnosisRequest {
  const AiDiagnosisRequest({
    required this.preferences,
    required this.conditions,
    required this.userId,
  });

  final String preferences;
  final String conditions;
  final int userId;

  factory AiDiagnosisRequest.fromProfile({
    required ClinicalConditionProfile profile,
    required String foodPreferences,
    required String language,
    required int userId,
  }) {
    final conditions = profile.conditions.entries
        .map((entry) => '${entry.key.name}:${entry.value.name}')
        .join(',');
    return AiDiagnosisRequest(
      preferences: _preferencesForLanguage(foodPreferences, language),
      conditions: conditions,
      userId: userId,
    );
  }

  static String _preferencesForLanguage(String preferences, String language) {
    final isSpanish = language.toLowerCase().startsWith('es');
    final instruction =
        isSpanish ? 'Responde en español.' : 'Respond in English.';
    final trimmed = preferences.trim();
    final preferenceLabel =
        isSpanish ? 'Preferencias de comida' : 'Food preferences';
    return trimmed.isEmpty
        ? instruction
        : '$instruction $preferenceLabel: $trimmed';
  }

  Map<String, dynamic> toJson() => {
        'preferences': preferences,
        'conditions': conditions,
        'userId': userId,
      };
}
