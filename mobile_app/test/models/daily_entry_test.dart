import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/models/daily_entry.dart';

void main() {
  group('DailyEntry', () {
    test('serializes to a SQLite row map and back', () {
      const entry = DailyEntry(
        date: '2026-09-03',
        calories: 2100,
        protein: 140,
        carbs: 220,
        fat: 70,
        exercises: ['Bench Press', 'Squat'],
      );

      final restored = DailyEntry.fromMap(entry.toMap());

      expect(restored.date, '2026-09-03');
      expect(restored.calories, 2100);
      expect(restored.protein, 140);
      expect(restored.carbs, 220);
      expect(restored.fat, 70);
      expect(restored.exercises, ['Bench Press', 'Squat']);
    });

    test('restores empty defaults from a sparse row', () {
      final restored = DailyEntry.fromMap({'date': '2026-09-03'});

      expect(restored.calories, 0);
      expect(restored.exercises, isEmpty);
      expect(restored.isEmpty, isTrue);
    });

    test('copyWith replaces only the given fields', () {
      const entry = DailyEntry(
        date: '2026-09-03',
        calories: 1000,
        exercises: ['Curl'],
      );

      final updated = entry.copyWith(calories: 1500, exercises: ['Curl', 'Squat']);

      expect(updated.calories, 1500);
      expect(updated.exercises, ['Curl', 'Squat']);
      expect(updated.protein, entry.protein);
    });
  });
}