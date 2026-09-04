import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/models/log_parse_response.dart';

void main() {
  group('LogParseResponse', () {
    test('parses the full backend shape', () {
      final result = LogParseResponse.fromJson({
        'calories': 650,
        'macros': {'protein': 45, 'carbs': 55, 'fat': 18},
        'muscleGroups': ['chest', 'shoulders'],
      });

      expect(result.calories, 650);
      expect(result.protein, 45);
      expect(result.carbs, 55);
      expect(result.fat, 18);
      expect(result.muscleGroups, ['chest', 'shoulders']);
    });

    test('tolerates missing macros and muscle groups', () {
      final result = LogParseResponse.fromJson({'calories': 120});

      expect(result.calories, 120);
      expect(result.protein, isNull);
      expect(result.carbs, isNull);
      expect(result.fat, isNull);
      expect(result.muscleGroups, isEmpty);
    });

    test('coerces numeric values to ints', () {
      final result = LogParseResponse.fromJson({
        'calories': 500.0,
        'macros': {'protein': 40.0},
      });

      expect(result.calories, 500);
      expect(result.protein, 40);
    });
  });
}
