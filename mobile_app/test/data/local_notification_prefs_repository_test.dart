import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/local_notification_prefs_repository.dart';
import 'package:nutri_mobile_app/core/database/database_helper.dart';
import 'package:nutri_mobile_app/core/models/notification_pref.dart';
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
            CREATE TABLE routines (
              id INTEGER PRIMARY KEY,
              weekday TEXT NOT NULL,
              focus TEXT NOT NULL,
              exercises_json TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE notification_prefs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              pref_key TEXT NOT NULL UNIQUE,
              enabled INTEGER NOT NULL
            )
          ''');
        },
      ),
    );
    helper = DatabaseHelper(database: db);
  });

  group('LocalNotificationPrefsRepository (SQLite)', () {
    test('defaults to disabled when no row exists', () async {
      final repo = LocalNotificationPrefsRepository(databaseHelper: helper);

      expect(
        await repo.isEnabled(NotificationPrefType.exerciseAlerts),
        isFalse,
      );
      expect(
        await repo.isEnabled(NotificationPrefType.dailyIntakeReminders),
        isFalse,
      );
    });

    test('persists enabled state and reads it back', () async {
      final repo = LocalNotificationPrefsRepository(databaseHelper: helper);

      await repo.setEnabled(NotificationPrefType.exerciseAlerts, true);
      await repo.setEnabled(NotificationPrefType.foodAlerts, true);

      expect(
        await repo.isEnabled(NotificationPrefType.exerciseAlerts),
        isTrue,
      );
      expect(await repo.isEnabled(NotificationPrefType.foodAlerts), isTrue);
      expect(
        await repo.isEnabled(NotificationPrefType.dailyIntakeReminders),
        isFalse,
      );
    });

    test('updates an existing pref row instead of duplicating', () async {
      final repo = LocalNotificationPrefsRepository(databaseHelper: helper);

      await repo.setEnabled(NotificationPrefType.exerciseAlerts, true);
      await repo.setEnabled(NotificationPrefType.exerciseAlerts, false);

      expect(
        await repo.isEnabled(NotificationPrefType.exerciseAlerts),
        isFalse,
      );
    });
  });
}