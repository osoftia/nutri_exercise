import 'package:flutter/foundation.dart';

import '../data/clinical_profile_repository.dart';
import '../domain/clinical/clinical_condition.dart';
import '../domain/clinical/clinical_condition_profile.dart';
import '../domain/clinical/clinical_food_evaluator.dart';
import '../domain/clinical/clinical_safety_verdict.dart';
import '../models/food_entry.dart';

/// Reactive owner of the active clinical conditions and food-guidance rules.
class ClinicalProfileController extends ChangeNotifier {
  ClinicalProfileController({
    required ClinicalProfileRepository repository,
    ClinicalFoodEvaluator evaluator = const ClinicalFoodEvaluator(),
    ClinicalConditionProfile initialProfile = const ClinicalConditionProfile(),
  })  : _repository = repository,
        _evaluator = evaluator,
        _profile = initialProfile;

  final ClinicalProfileRepository _repository;
  final ClinicalFoodEvaluator _evaluator;
  ClinicalConditionProfile _profile;
  bool _isLoaded = false;
  Future<void>? _loading;

  ClinicalConditionProfile get profile => _profile;
  bool get isLoaded => _isLoaded;
  bool get hasConditions => !_profile.isEmpty;

  Future<void> load() async {
    if (_isLoaded) return;
    final loading = _loading;
    if (loading != null) return loading;
    final operation = _loadProfile();
    _loading = operation;
    try {
      await operation;
    } finally {
      _loading = null;
    }
  }

  Future<void> _loadProfile() async {
    _profile = await _repository.load();
    _isLoaded = true;
    notifyListeners();
  }

  ClinicalSafetyVerdict evaluate(FoodEntry food) =>
      _evaluator.evaluate(food, _profile);

  ClinicalSafetyVerdict evaluateMeal(Iterable<FoodEntry> ingredients) =>
      _evaluator.evaluateMeal(ingredients, _profile);

  Future<void> setSeverity(
    ClinicalCondition condition,
    ClinicalSeverity severity,
  ) async {
    final conditions = Map<ClinicalCondition, ClinicalSeverity>.of(
      _profile.conditions,
    )..[condition] = severity;
    await _update(_profile.copyWith(
      conditions: conditions,
      mockCase: ClinicalMockCase.none,
    ));
  }

  Future<void> removeCondition(ClinicalCondition condition) async {
    final conditions = Map<ClinicalCondition, ClinicalSeverity>.of(
      _profile.conditions,
    )..remove(condition);
    await _update(_profile.copyWith(
      conditions: conditions,
      mockCase: ClinicalMockCase.none,
    ));
  }

  Future<void> clearConditions() async {
    await _update(const ClinicalConditionProfile());
  }

  Future<void> selectMockCase(ClinicalMockCase mockCase) async {
    final conditions = switch (mockCase) {
      ClinicalMockCase.none => const <ClinicalCondition, ClinicalSeverity>{},
      ClinicalMockCase.highCholesterol => const {
          ClinicalCondition.highCholesterol: ClinicalSeverity.high,
        },
      ClinicalMockCase.diabetes => const {
          ClinicalCondition.diabetes: ClinicalSeverity.moderate,
        },
      ClinicalMockCase.gout => const {
          ClinicalCondition.gout: ClinicalSeverity.moderate,
        },
      ClinicalMockCase.hypertension => const {
          ClinicalCondition.hypertension: ClinicalSeverity.moderate,
        },
    };
    await _update(
      ClinicalConditionProfile(conditions: conditions, mockCase: mockCase),
    );
  }

  Future<void> _update(ClinicalConditionProfile profile) async {
    _profile = profile;
    notifyListeners();
    await _repository.save(profile);
  }
}
