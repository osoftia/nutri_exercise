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
    required int userId,
  }) {
    final conditions = profile.conditions.entries
        .map((entry) => '${entry.key.name}:${entry.value.name}')
        .join(',');
    return AiDiagnosisRequest(
      preferences: foodPreferences.trim(),
      conditions: conditions,
      userId: userId,
    );
  }

  Map<String, dynamic> toJson() => {
        'preferences': preferences,
        'conditions': conditions,
        'userId': userId,
      };
}
