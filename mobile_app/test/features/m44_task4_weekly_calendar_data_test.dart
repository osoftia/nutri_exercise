import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/popups/exercise_completion.dart';
import 'package:nutri_mobile_app/core/mocks/mock_body_detail_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/models/daily_entry.dart';
import 'package:nutri_mobile_app/core/state/workout_completion_controller.dart';
import 'package:nutri_mobile_app/core/utils/weekly_stats.dart';

const _benchPress = CompletedExercise(
  name: 'Bench Press',
  plannedSets: 4,
  completedSets: 4,
  reps: 8,
  loadKg: 60,
);

void main() {
  final now = DateTime(2026, 9, 7, 14, 30);

  group('M44 weekly summary honours the persisted burn', () {
    test('uses the recorded burned value over the exercise estimate', () {
      final stats = computeWeeklyStats(
        [
          const DailyEntry(
            date: '2026-09-07',
            calories: 1200,
            exercises: ['A', 'B', 'C'],
            burned: 500,
          ),
        ],
        now: now,
      );

      expect(stats.last.burned, 500);
    });

    test('falls back to the estimate when no burn was recorded', () {
      final stats = computeWeeklyStats(
        [
          const DailyEntry(
            date: '2026-09-07',
            calories: 1200,
            exercises: ['A', 'B', 'C'],
          ),
        ],
        now: now,
      );

      expect(stats.last.burned, 3 * caloriesBurnedPerExercise);
    });
  });

  group('M44 confirming a workout writes the calendar entry', () {
    test('confirm upserts today with exercise names and burned calories', () async {
      final today = DailyEntry.dateKey(DateTime.now());
      final entries = MockDailyEntryRepository({
        today: DailyEntry(
          date: today,
          calories: 1800,
          protein: 120,
          carbs: 180,
          fat: 60,
        ),
      });
      final controller = WorkoutCompletionController(
        repository: MockBodyDetailRepository(),
        dailyEntries: entries,
      );

      await controller.confirm(const [_benchPress]);

      final saved = (await entries.getByDate(today))!;
      expect(saved.exercises, ['Bench Press']);
      expect(saved.burned, 250);
      // Nutrition already recorded for the day is preserved.
      expect(saved.calories, 1800);
      expect(saved.protein, 120);
    });

    test('undo clears the day\'s exercises and burned calories', () async {
      final today = DailyEntry.dateKey(DateTime.now());
      final entries = MockDailyEntryRepository();
      final controller = WorkoutCompletionController(
        repository: MockBodyDetailRepository(),
        dailyEntries: entries,
      );

      await controller.confirm(const [_benchPress]);
      await controller.undo();

      final saved = (await entries.getByDate(today))!;
      expect(saved.exercises, isEmpty);
      expect(saved.burned, 0);
    });

    test('the confirmed day feeds the weekly summary and calendar markers',
        () async {
      final today = DailyEntry.dateKey(DateTime.now());
      final entries = MockDailyEntryRepository();
      final controller = WorkoutCompletionController(
        repository: MockBodyDetailRepository(),
        dailyEntries: entries,
      );

      await controller.confirm(const [_benchPress]);

      final all = await entries.getAll();
      expect(all.map((entry) => entry.date), contains(today));

      final stats = computeWeeklyStats(all);
      expect(stats.last.date, DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      ));
      expect(stats.last.burned, 250);
    });
  });
}
