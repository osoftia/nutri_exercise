import '../i18n/app_language.dart';

/// Health conditions supported by the educational food-guidance rules.
enum ClinicalCondition {
  highCholesterol,
  diabetes,
  gout,
  hypertension,
}

extension ClinicalConditionLabels on ClinicalCondition {
  String labelFor(AppLanguage language) => switch ((this, language)) {
        (ClinicalCondition.highCholesterol, AppLanguage.english) =>
          'High cholesterol',
        (ClinicalCondition.highCholesterol, AppLanguage.spanish) =>
          'Colesterol alto',
        (ClinicalCondition.diabetes, AppLanguage.english) => 'Diabetes',
        (ClinicalCondition.diabetes, AppLanguage.spanish) => 'Diabetes',
        (ClinicalCondition.gout, AppLanguage.english) => 'Gout',
        (ClinicalCondition.gout, AppLanguage.spanish) => 'Gota',
        (ClinicalCondition.hypertension, AppLanguage.english) => 'Hypertension',
        (ClinicalCondition.hypertension, AppLanguage.spanish) => 'Hipertensión',
      };
}

/// User-selected urgency for the educational nutrient thresholds.
enum ClinicalSeverity { monitor, moderate, high }

extension ClinicalSeverityLabels on ClinicalSeverity {
  String labelFor(AppLanguage language) => switch ((this, language)) {
        (ClinicalSeverity.monitor, AppLanguage.english) => 'Monitor',
        (ClinicalSeverity.monitor, AppLanguage.spanish) => 'Observar',
        (ClinicalSeverity.moderate, AppLanguage.english) => 'Moderate',
        (ClinicalSeverity.moderate, AppLanguage.spanish) => 'Moderado',
        (ClinicalSeverity.high, AppLanguage.english) => 'High',
        (ClinicalSeverity.high, AppLanguage.spanish) => 'Alto',
      };
}

/// One-tap demo profiles for exercising the clinical food guidance.
enum ClinicalMockCase { none, highCholesterol, diabetes, gout, hypertension }

extension ClinicalMockCaseLabels on ClinicalMockCase {
  String labelFor(AppLanguage language) => switch ((this, language)) {
        (ClinicalMockCase.none, AppLanguage.english) => 'No demo case',
        (ClinicalMockCase.none, AppLanguage.spanish) =>
          'Sin caso de demostración',
        (ClinicalMockCase.highCholesterol, AppLanguage.english) =>
          'Case: High cholesterol — red meat vs oats',
        (ClinicalMockCase.highCholesterol, AppLanguage.spanish) =>
          'Caso: Colesterol alto — carnes rojas vs. avena',
        (ClinicalMockCase.diabetes, AppLanguage.english) =>
          'Case: Diabetes — sweet drink vs berries',
        (ClinicalMockCase.diabetes, AppLanguage.spanish) =>
          'Caso: Diabetes — bebida dulce vs. frutos rojos',
        (ClinicalMockCase.gout, AppLanguage.english) =>
          'Case: Gout — organ meat vs fruit',
        (ClinicalMockCase.gout, AppLanguage.spanish) =>
          'Caso: Gota — vísceras vs. fruta',
        (ClinicalMockCase.hypertension, AppLanguage.english) =>
          'Case: Hypertension — salty soup vs fresh oats',
        (ClinicalMockCase.hypertension, AppLanguage.spanish) =>
          'Caso: Hipertensión — sopa salada vs. avena',
      };
}
