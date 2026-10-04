import '../../models/food_entry.dart';
import 'clinical_condition.dart';
import 'clinical_condition_profile.dart';
import 'clinical_safety_verdict.dart';

/// Deterministic nutrient-threshold guidance for the user's selected conditions.
///
/// The rules use the supplied per-serving nutrient estimates only. Missing
/// inputs are reported as unassessed rather than being treated as zero or safe.
class ClinicalFoodEvaluator {
  const ClinicalFoodEvaluator();

  ClinicalSafetyVerdict evaluate(
    FoodEntry food,
    ClinicalConditionProfile profile,
  ) {
    if (profile.isEmpty) {
      return const ClinicalSafetyVerdict(level: ClinicalVerdictLevel.safe);
    }

    final findings = <ClinicalFinding>[
      for (final condition in ClinicalCondition.values)
        if (profile.severityFor(condition) case final severity?)
          _evaluateCondition(food, condition, severity),
    ];
    final levels = findings.map((finding) => finding.level).toSet();
    final level = levels.contains(ClinicalVerdictLevel.warning)
        ? ClinicalVerdictLevel.warning
        : levels.contains(ClinicalVerdictLevel.unassessed)
            ? ClinicalVerdictLevel.unassessed
            : levels.contains(ClinicalVerdictLevel.beneficial)
                ? ClinicalVerdictLevel.beneficial
                : ClinicalVerdictLevel.safe;
    return ClinicalSafetyVerdict(level: level, findings: findings);
  }

  /// Evaluates an assembled meal by summing its per-ingredient nutrient data.
  ///
  /// A nutrient is considered unknown when any ingredient omits it, preventing
  /// an incomplete meal from being marked safe by treating missing data as 0.
  ClinicalSafetyVerdict evaluateMeal(
    Iterable<FoodEntry> ingredients,
    ClinicalConditionProfile profile,
  ) {
    final foods = ingredients.toList(growable: false);
    if (foods.isEmpty) {
      return const ClinicalSafetyVerdict(
        level: ClinicalVerdictLevel.unassessed,
      );
    }
    double? total(double? Function(FoodEntry food) select) {
      if (foods.any((food) => select(food) == null)) return null;
      return foods.fold<double>(0, (sum, food) {
        final amount = select(food);
        return sum + (amount ?? 0);
      });
    }

    final totalCarbs = foods.fold<int>(0, (sum, food) => sum + food.carbsG);
    final glycemicIndex =
        foods.any((food) => food.carbsG > 0 && food.glycemicIndex == null) ||
                totalCarbs == 0
            ? null
            : foods.fold<double>(0, (sum, food) {
                  final index = food.glycemicIndex;
                  return sum + (index == null ? 0 : index * food.carbsG);
                }) /
                totalCarbs;

    return evaluate(
      FoodEntry(
        name: foods.map((food) => food.name).join(' + '),
        calories: foods.fold(0, (sum, food) => sum + food.calories),
        proteinG: foods.fold(0, (sum, food) => sum + food.proteinG),
        carbsG: totalCarbs,
        fatG: foods.fold(0, (sum, food) => sum + food.fatG),
        saturatedFatG: total((food) => food.saturatedFatG),
        sugarsG: total((food) => food.sugarsG),
        fiberG: total((food) => food.fiberG),
        glycemicIndex: glycemicIndex,
        purinesMg: total((food) => food.purinesMg),
        sodiumMg: total((food) => food.sodiumMg),
      ),
      profile,
    );
  }

  ClinicalFinding _evaluateCondition(
    FoodEntry food,
    ClinicalCondition condition,
    ClinicalSeverity severity,
  ) {
    return switch (condition) {
      ClinicalCondition.highCholesterol => _cholesterol(food, severity),
      ClinicalCondition.diabetes => _diabetes(food, severity),
      ClinicalCondition.gout => _gout(food, severity),
      ClinicalCondition.hypertension => _hypertension(food, severity),
    };
  }

  ClinicalFinding _cholesterol(FoodEntry food, ClinicalSeverity severity) {
    final saturatedFat = food.saturatedFatG;
    if (saturatedFat == null) {
      return _unknown(
        ClinicalCondition.highCholesterol,
        'Saturated-fat data is not available for cholesterol guidance.',
      );
    }
    final warningLimit = switch (severity) {
      ClinicalSeverity.monitor => 8.0,
      ClinicalSeverity.moderate => 5.0,
      ClinicalSeverity.high => 3.0,
    };
    if (saturatedFat >= warningLimit) {
      return ClinicalFinding(
        condition: ClinicalCondition.highCholesterol,
        level: ClinicalVerdictLevel.warning,
        reason:
            'High saturated fat (${_amount(saturatedFat)} g) may work against cholesterol goals.',
      );
    }
    if ((food.fiberG ?? 0) >= 5 && saturatedFat <= 2) {
      return ClinicalFinding(
        condition: ClinicalCondition.highCholesterol,
        level: ClinicalVerdictLevel.beneficial,
        reason:
            'Fiber-rich and low in saturated fat; fiber can support cholesterol goals.',
      );
    }
    return ClinicalFinding(
      condition: ClinicalCondition.highCholesterol,
      level: ClinicalVerdictLevel.safe,
      reason:
          'Saturated fat (${_amount(saturatedFat)} g) is below the selected caution threshold.',
    );
  }

  ClinicalFinding _diabetes(FoodEntry food, ClinicalSeverity severity) {
    final sugar = food.sugarsG;
    final glycemicIndex = food.glycemicIndex;
    if (sugar == null && glycemicIndex == null) {
      return _unknown(
        ClinicalCondition.diabetes,
        'Sugar and glycemic-index data are not available for diabetes guidance.',
      );
    }
    final sugarLimit = switch (severity) {
      ClinicalSeverity.monitor => 20.0,
      ClinicalSeverity.moderate => 15.0,
      ClinicalSeverity.high => 10.0,
    };
    final glycemicLimit = switch (severity) {
      ClinicalSeverity.monitor => 75.0,
      ClinicalSeverity.moderate => 70.0,
      ClinicalSeverity.high => 60.0,
    };
    if ((sugar != null && sugar >= sugarLimit) ||
        (glycemicIndex != null && glycemicIndex >= glycemicLimit)) {
      final detail = sugar != null && sugar >= sugarLimit
          ? 'sugar (${_amount(sugar)} g)'
          : 'glycemic index (${_amount(glycemicIndex!)} )';
      return ClinicalFinding(
        condition: ClinicalCondition.diabetes,
        level: ClinicalVerdictLevel.warning,
        reason: 'High $detail may make blood-glucose management harder.',
      );
    }
    if (sugar != null &&
        sugar <= 10 &&
        (glycemicIndex == null || glycemicIndex <= 55) &&
        (food.fiberG ?? 0) >= 5) {
      return const ClinicalFinding(
        condition: ClinicalCondition.diabetes,
        level: ClinicalVerdictLevel.beneficial,
        reason:
            'Lower sugar with fiber and a low glycemic index can support steadier glucose response.',
      );
    }
    return ClinicalFinding(
      condition: ClinicalCondition.diabetes,
      level: ClinicalVerdictLevel.safe,
      reason: sugar != null
          ? 'Sugar (${_amount(sugar)} g) is below the selected caution threshold.'
          : 'Glycemic index (${_amount(glycemicIndex!)} ) is below the selected caution threshold.',
    );
  }

  ClinicalFinding _gout(FoodEntry food, ClinicalSeverity severity) {
    final purines = food.purinesMg;
    if (purines == null) {
      return _unknown(
        ClinicalCondition.gout,
        'Purine data is not available for gout guidance.',
      );
    }
    final warningLimit = switch (severity) {
      ClinicalSeverity.monitor => 250.0,
      ClinicalSeverity.moderate => 150.0,
      ClinicalSeverity.high => 100.0,
    };
    if (purines >= warningLimit) {
      return ClinicalFinding(
        condition: ClinicalCondition.gout,
        level: ClinicalVerdictLevel.warning,
        reason:
            'High purine estimate (${_amount(purines)} mg) may be a gout trigger.',
      );
    }
    if (purines <= 50) {
      return ClinicalFinding(
        condition: ClinicalCondition.gout,
        level: ClinicalVerdictLevel.beneficial,
        reason:
            'Low purine estimate (${_amount(purines)} mg) is generally a more supportive choice for gout.',
      );
    }
    return ClinicalFinding(
      condition: ClinicalCondition.gout,
      level: ClinicalVerdictLevel.safe,
      reason:
          'Purine estimate (${_amount(purines)} mg) is below the selected caution threshold.',
    );
  }

  ClinicalFinding _hypertension(FoodEntry food, ClinicalSeverity severity) {
    final sodium = food.sodiumMg;
    if (sodium == null) {
      return _unknown(
        ClinicalCondition.hypertension,
        'Sodium data is not available for blood-pressure guidance.',
      );
    }
    final warningLimit = switch (severity) {
      ClinicalSeverity.monitor => 700.0,
      ClinicalSeverity.moderate => 600.0,
      ClinicalSeverity.high => 350.0,
    };
    if (sodium >= warningLimit) {
      return ClinicalFinding(
        condition: ClinicalCondition.hypertension,
        level: ClinicalVerdictLevel.warning,
        reason:
            'High sodium (${_amount(sodium)} mg) can work against blood-pressure goals.',
      );
    }
    if (sodium <= 140) {
      return ClinicalFinding(
        condition: ClinicalCondition.hypertension,
        level: ClinicalVerdictLevel.beneficial,
        reason:
            'Low sodium (${_amount(sodium)} mg) can support a lower-sodium eating pattern.',
      );
    }
    return ClinicalFinding(
      condition: ClinicalCondition.hypertension,
      level: ClinicalVerdictLevel.safe,
      reason:
          'Sodium (${_amount(sodium)} mg) is below the selected caution threshold.',
    );
  }

  ClinicalFinding _unknown(ClinicalCondition condition, String reason) =>
      ClinicalFinding(
        condition: condition,
        level: ClinicalVerdictLevel.unassessed,
        reason: reason,
      );

  static String _amount(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}
