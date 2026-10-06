import '../domain/clinical/clinical_condition_profile.dart';

/// Typed request contract for the clinical nutrition report endpoint.
class AiDiagnosisRequest {
  const AiDiagnosisRequest({
    required this.conditions,
    required this.foodPreferences,
    required this.language,
  });

  final List<Map<String, String>> conditions;
  final String foodPreferences;
  final String language;

  factory AiDiagnosisRequest.fromProfile({
    required ClinicalConditionProfile profile,
    required String foodPreferences,
    required String language,
  }) {
    final conditions = profile.conditions.entries
        .map(
          (entry) => {
            'id': entry.key.name,
            'severity': entry.value.name,
          },
        )
        .toList(growable: false);
    return AiDiagnosisRequest(
      conditions: conditions,
      foodPreferences: foodPreferences.trim(),
      language: language,
    );
  }

  Map<String, dynamic> toJson() => {
        'conditions': conditions,
        'foodPreferences': foodPreferences,
        'language': language,
      };
}
