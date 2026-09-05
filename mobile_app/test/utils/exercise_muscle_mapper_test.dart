import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/utils/exercise_muscle_mapper.dart';

void main() {
  group('ExerciseMuscleMapper', () {
    test('maps Bench Press to chest primary and arms/shoulders secondary', () {
      final activation = ExerciseMuscleMapper.activationFor('Bench Press');

      expect(activation.primaryRegions, contains('chest'));
      expect(activation.secondaryRegions, contains('arms'));
      expect(activation.secondaryRegions, contains('shoulders'));
    });

    test('is case-insensitive and trims whitespace', () {
      final activation = ExerciseMuscleMapper.activationFor('  bench PRESS  ');

      expect(activation.primaryRegions, contains('chest'));
    });

    test('returns empty activation for unknown exercises', () {
      final activation = ExerciseMuscleMapper.activationFor('Moonwalk');

      expect(activation.primaryRegions, isEmpty);
      expect(activation.secondaryRegions, isEmpty);
    });

    test('only emits known muscle vector region ids', () {
      const knownIds = {
        'chest',
        'abs',
        'arms',
        'legs',
        'shoulders',
        'back',
      };

      for (final name in ExerciseMuscleMapper.knownExercises) {
        final activation = ExerciseMuscleMapper.activationFor(name);
        final all = [
          ...activation.primaryRegions,
          ...activation.secondaryRegions,
        ];
        expect(all, isNotEmpty, reason: 'empty mapping for $name');
        for (final id in all) {
          expect(knownIds, contains(id), reason: 'unknown id $id for $name');
        }
      }
    });
  });
}
