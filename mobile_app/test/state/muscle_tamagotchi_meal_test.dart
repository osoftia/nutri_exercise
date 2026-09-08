import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/models/log_parse_response.dart';
import 'package:nutri_mobile_app/core/state/muscle_tamagotchi_state.dart';

void main() {
  group('LogParseResponse.isHealthy', () {
    test('high protein with low fat is healthy', () {
      const meal = LogParseResponse(calories: 500, protein: 40, fat: 10);

      expect(meal.isHealthy, isTrue);
    });

    test('low protein with high fat is unhealthy', () {
      const meal = LogParseResponse(calories: 900, protein: 5, fat: 60);

      expect(meal.isHealthy, isFalse);
    });

    test('an explicit healthy flag wins over the heuristic', () {
      const meal = LogParseResponse(
        calories: 300,
        protein: 2,
        fat: 40,
        healthy: true,
      );

      expect(meal.isHealthy, isTrue);
    });

    test('a parsed explicit flag round-trips through JSON', () {
      const meal = LogParseResponse(calories: 400, healthy: false);
      final restored = LogParseResponse.fromJson(meal.toJson());

      expect(restored.isHealthy, isFalse);
    });
  });

  group('MuscleTamagotchiState.applyMeal', () {
    test('healthy meals grow the arms, legs and chest vectors', () {
      final state = MuscleTamagotchiState();
      const meal = LogParseResponse(calories: 500, protein: 40, fat: 10);

      state.applyMeal(meal);

      for (final group in [
        MuscleTamagotchiGroup.arms,
        MuscleTamagotchiGroup.legs,
        MuscleTamagotchiGroup.chest,
      ]) {
        expect(state.massOf(group), greaterThan(MuscleTamagotchiState.baseline));
      }
      expect(state.coreFullness, 0.0);
      expect(state.coreIsBloating, isFalse);
    });

    test('unhealthy meals increase stomach bloat, not muscle', () {
      final state = MuscleTamagotchiState();
      const meal = LogParseResponse(calories: 900, protein: 5, fat: 60);

      state.applyMeal(meal);

      expect(state.coreFullness, greaterThan(0.0));
      expect(state.coreIsBloating, isTrue);
      expect(
        state.massOf(MuscleTamagotchiGroup.arms),
        MuscleTamagotchiState.baseline,
      );
    });
  });
}