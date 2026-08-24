import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_nutrition_repository.dart';
import 'package:nutri_mobile_app/core/models/nutrition_state.dart';

void main() {
  group('MockNutritionRepository', () {
    test('loadToday returns the seeded baseline', () async {
      final repo = MockNutritionRepository();
      final state = await repo.loadToday();

      expect(state.targetCalories, 2000);
      expect(state.consumedCalories, 1000);
      expect(state.proteinG, 30);
      expect(state.carbsG, 80);
      expect(state.fatG, 20);
      expect(state.entries, isEmpty);
      expect(state.weeklyCalories, hasLength(7));
    });

    test('saveToday persists state for subsequent loads', () async {
      final repo = MockNutritionRepository();
      final baseline = await repo.loadToday();

      final updated = NutritionState(
        targetCalories: baseline.targetCalories,
        consumedCalories: 1650,
        proteinG: baseline.proteinG,
        carbsG: baseline.carbsG,
        fatG: baseline.fatG,
        entries: baseline.entries,
        weeklyCalories: baseline.weeklyCalories,
        macroTargets: baseline.macroTargets,
      );
      await repo.saveToday(updated);

      final reloaded = await repo.loadToday();
      expect(reloaded.consumedCalories, 1650);
    });
  });
}
