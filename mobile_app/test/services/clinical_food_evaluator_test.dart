import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/clinical/clinical_condition.dart';
import 'package:nutri_mobile_app/core/domain/clinical/clinical_condition_profile.dart';
import 'package:nutri_mobile_app/core/domain/clinical/clinical_food_evaluator.dart';
import 'package:nutri_mobile_app/core/domain/clinical/clinical_safety_verdict.dart';
import 'package:nutri_mobile_app/core/models/food_entry.dart';

void main() {
  const evaluator = ClinicalFoodEvaluator();

  ClinicalConditionProfile profile(
    ClinicalCondition condition, {
    ClinicalSeverity severity = ClinicalSeverity.moderate,
  }) =>
      ClinicalConditionProfile(conditions: {condition: severity});

  group('ClinicalFoodEvaluator', () {
    test('flags saturated fat for high cholesterol', () {
      final verdict = evaluator.evaluate(
        const FoodEntry(
          name: 'Creamy burger',
          calories: 600,
          saturatedFatG: 8,
        ),
        profile(ClinicalCondition.highCholesterol),
      );

      expect(verdict.level, ClinicalVerdictLevel.warning);
      expect(verdict.findings.single.reason, contains('saturated fat'));
      expect(verdict.findings.single.reason, contains('cholesterol'));
    });

    test('marks a high-fiber low-saturated-fat food beneficial', () {
      final verdict = evaluator.evaluate(
        const FoodEntry(
          name: 'Oatmeal',
          calories: 150,
          saturatedFatG: 1,
          fiberG: 7,
        ),
        profile(ClinicalCondition.highCholesterol),
      );

      expect(verdict.level, ClinicalVerdictLevel.beneficial);
      expect(verdict.findings.single.reason, contains('fiber'));
    });

    test('flags high sugar and glycemic index for diabetes', () {
      final verdict = evaluator.evaluate(
        const FoodEntry(
          name: 'Sweet drink',
          calories: 180,
          sugarsG: 24,
          glycemicIndex: 78,
        ),
        profile(ClinicalCondition.diabetes, severity: ClinicalSeverity.high),
      );

      expect(verdict.level, ClinicalVerdictLevel.warning);
      expect(verdict.findings.single.reason,
          anyOf(contains('sugar'), contains('glycemic')));
    });

    test('flags high purines for gout', () {
      final verdict = evaluator.evaluate(
        const FoodEntry(name: 'Organ meat', calories: 220, purinesMg: 220),
        profile(ClinicalCondition.gout),
      );

      expect(verdict.level, ClinicalVerdictLevel.warning);
      expect(verdict.findings.single.reason, contains('purine'));
    });

    test('flags high sodium for hypertension', () {
      final verdict = evaluator.evaluate(
        const FoodEntry(name: 'Instant soup', calories: 90, sodiumMg: 900),
        profile(ClinicalCondition.hypertension),
      );

      expect(verdict.level, ClinicalVerdictLevel.warning);
      expect(verdict.findings.single.reason, contains('sodium'));
    });

    test('recognizes low-purine and low-sodium supportive foods', () {
      final verdict = evaluator.evaluate(
        const FoodEntry(
          name: 'Fresh fruit',
          calories: 80,
          purinesMg: 20,
          sodiumMg: 30,
        ),
        ClinicalConditionProfile(
          conditions: {
            ClinicalCondition.gout: ClinicalSeverity.moderate,
            ClinicalCondition.hypertension: ClinicalSeverity.moderate,
          },
        ),
      );

      expect(verdict.level, ClinicalVerdictLevel.beneficial);
      expect(verdict.findings, hasLength(2));
      expect(
        verdict.findings.every(
          (finding) => finding.level == ClinicalVerdictLevel.beneficial,
        ),
        isTrue,
      );
    });

    test('does not call missing condition-specific data safe', () {
      final verdict = evaluator.evaluate(
        const FoodEntry(name: 'Unlabelled food', calories: 300),
        profile(ClinicalCondition.diabetes),
      );

      expect(verdict.level, ClinicalVerdictLevel.unassessed);
      expect(verdict.findings.single.reason, contains('not available'));
    });

    test('a warning takes priority over beneficial findings', () {
      final verdict = evaluator.evaluate(
        const FoodEntry(
          name: 'Fiber-rich salty food',
          calories: 300,
          saturatedFatG: 8,
          fiberG: 8,
          purinesMg: 20,
        ),
        ClinicalConditionProfile(
          conditions: {
            ClinicalCondition.highCholesterol: ClinicalSeverity.moderate,
            ClinicalCondition.gout: ClinicalSeverity.moderate,
          },
        ),
      );

      expect(verdict.level, ClinicalVerdictLevel.warning);
      expect(
        verdict.findings
            .any((finding) => finding.level == ClinicalVerdictLevel.beneficial),
        isTrue,
      );
      expect(
        verdict.findings
            .any((finding) => finding.level == ClinicalVerdictLevel.warning),
        isTrue,
      );
    });

    test('severity adjusts the warning threshold', () {
      const food = FoodEntry(
        name: 'Cheese',
        calories: 110,
        saturatedFatG: 4,
      );

      expect(
        evaluator
            .evaluate(food, profile(ClinicalCondition.highCholesterol))
            .level,
        ClinicalVerdictLevel.safe,
      );
      expect(
        evaluator
            .evaluate(
              food,
              profile(
                ClinicalCondition.highCholesterol,
                severity: ClinicalSeverity.high,
              ),
            )
            .level,
        ClinicalVerdictLevel.warning,
      );
    });

    test('returns a neutral safe verdict when no conditions are selected', () {
      final verdict = evaluator.evaluate(
        const FoodEntry(name: 'Any food', calories: 100),
        const ClinicalConditionProfile(),
      );

      expect(verdict.level, ClinicalVerdictLevel.safe);
      expect(verdict.findings, isEmpty);
    });
  });
}
