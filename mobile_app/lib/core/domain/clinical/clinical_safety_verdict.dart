import 'clinical_condition.dart';

/// Overall food evaluation, from actionable concern to missing details.
enum ClinicalVerdictLevel { safe, warning, beneficial, unassessed }

extension ClinicalVerdictLabels on ClinicalVerdictLevel {
  String get label => switch (this) {
        ClinicalVerdictLevel.safe => 'Within selected guidance',
        ClinicalVerdictLevel.warning => 'Warning',
        ClinicalVerdictLevel.beneficial => 'Supportive',
        ClinicalVerdictLevel.unassessed => 'Needs nutrition detail',
      };

  String get labelEs => switch (this) {
        ClinicalVerdictLevel.safe => 'Dentro de la guía seleccionada',
        ClinicalVerdictLevel.warning => 'Advertencia',
        ClinicalVerdictLevel.beneficial => 'Puede favorecer',
        ClinicalVerdictLevel.unassessed => 'Faltan datos nutricionales',
      };
}

/// One condition-specific finding and its plain-language explanation.
class ClinicalFinding {
  const ClinicalFinding({
    required this.condition,
    required this.level,
    required this.reason,
  });

  final ClinicalCondition condition;
  final ClinicalVerdictLevel level;
  final String reason;
}

/// Aggregate evaluation for a single food or portion.
class ClinicalSafetyVerdict {
  const ClinicalSafetyVerdict({
    required this.level,
    this.findings = const [],
  });

  final ClinicalVerdictLevel level;
  final List<ClinicalFinding> findings;
}
