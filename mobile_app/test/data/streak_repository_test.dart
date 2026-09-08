import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/local_daily_log_repository.dart';
import 'package:nutri_mobile_app/core/database/database_helper.dart';
import 'package:nutri_mobile_app/core/models/daily_entry.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late DatabaseHelper helper;
  late LocalDailyLogRepository repo;

  String dayKey(int daysAgo) {
    final day = DateTime.now().subtract(Duration(days: daysAgo));
    return DailyEntry.dateKey(day);
  }

  setUp(() async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        singleInstance: false,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE daily_entries (
              date TEXT PRIMARY KEY,
              calories INTEGER NOT NULL,
              protein INTEGER NOT NULL,
              carbs INTEGER NOT NULL,
              fat INTEGER NOT NULL,
              exercises_json TEXT NOT NULL,
              healthy_meals INTEGER NOT NULL DEFAULT 0
            )
          ''');
        },
      ),
    );
    helper = DatabaseHelper(database: db);
    repo = LocalDailyLogRepository(databaseHelper: helper);
  });

  Future<void> seed(DailyEntry entry) => helper.upsertDailyEntry(entry);

  group('LocalDailyLogRepository.currentStreak', () {
    test('returns 0 with no activity', () async {
      expect(await repo.currentStreak(), 0);
    });

    test('counts three consecutive active days', () async {
      await seed(DailyEntry(date: dayKey(0), exercises: const ['Squat']));
      await seed(DailyEntry(date: dayKey(1), healthyMeals: 1));
      await seed(DailyEntry(date: dayKey(2), exercises: const ['Bench Press']));

      expect(await repo.currentStreak(), 3);
    });

    test('a gap resets the streak', () async {
      await seed(DailyEntry(date: dayKey(0), exercises: const ['Squat']));
      // dayKey(1) has no activity.
      await seed(DailyEntry(date: dayKey(2), exercises: const ['Squat']));

      expect(await repo.currentStreak(), 1);
    });

    test('calories alone do not extend the streak', () async {
      await seed(DailyEntry(date: dayKey(0), calories: 2000));
      await seed(DailyEntry(date: dayKey(1), exercises: const ['Squat']));

      expect(await repo.currentStreak(), 1);
    });

    test('an inactive today still counts yesterday onward', () async {
      await seed(DailyEntry(date: dayKey(1), healthyMeals: 1));
      await seed(DailyEntry(date: dayKey(2), exercises: const ['Squat']));

      expect(await repo.currentStreak(), 2);
    });
  });
}