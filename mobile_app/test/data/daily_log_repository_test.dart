import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/local_daily_log_repository.dart';
import 'package:nutri_mobile_app/core/database/database_helper.dart';
import 'package:nutri_mobile_app/core/models/daily_log.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
  });

  late DatabaseHelper helper;

  setUp(() async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE daily_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date TEXT NOT NULL UNIQUE,
              text TEXT NOT NULL,
              parsed_json TEXT
            )
          ''');
        },
      ),
    );
    helper = DatabaseHelper(database: db);
  });

  group('LocalDailyLogRepository (SQLite)', () {
    test('returns null when no log exists for a date', () async {
      final repo = LocalDailyLogRepository(databaseHelper: helper);

      expect(await repo.getByDate('2026-09-03'), isNull);
    });

    test('persists a log and reads it back', () async {
      final repo = LocalDailyLogRepository(databaseHelper: helper);

      await repo.save(const DailyLog(date: '2026-09-03', text: 'Trained legs'));

      final restored = await repo.getByDate('2026-09-03');
      expect(restored?.date, '2026-09-03');
      expect(restored?.text, 'Trained legs');
    });

    test('upserts a single row per date, keeping the latest text', () async {
      final repo = LocalDailyLogRepository(databaseHelper: helper);

      await repo.save(const DailyLog(date: '2026-09-03', text: 'First'));
      await repo.save(const DailyLog(date: '2026-09-03', text: 'Second'));
      await repo.save(const DailyLog(date: '2026-09-04', text: 'Other day'));

      final restored = await repo.getByDate('2026-09-03');
      expect(restored?.text, 'Second');

      final other = await repo.getByDate('2026-09-04');
      expect(other?.text, 'Other day');
    });
  });
}
