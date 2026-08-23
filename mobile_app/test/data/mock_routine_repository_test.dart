import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_routine_repository.dart';

void main() {
  group('MockRoutineRepository', () {
    test('getWeeklyRoutine returns the three seeded days', () async {
      final repo = MockRoutineRepository();
      final days = await repo.getWeeklyRoutine();

      expect(days, hasLength(3));
      expect(days.map((d) => d.weekday), ['Monday', 'Wednesday', 'Friday']);
      expect(days.first.exercises, isNotEmpty);
    });

    test('generateRoutine returns text containing the preferences', () async {
      final repo = MockRoutineRepository();
      final text = await repo.generateRoutine('push pull split');

      expect(text, contains('push pull split'));
      expect(text, contains('Bench Press'));
    });
  });
}
