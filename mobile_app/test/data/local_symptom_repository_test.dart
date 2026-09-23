import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/local_symptom_repository.dart';
import 'package:nutri_mobile_app/core/database/database_helper.dart';
import 'package:nutri_mobile_app/core/models/symptom_log.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late DatabaseHelper helper;

  setUp(() async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE symptom_logs (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date TEXT NOT NULL,
              symptom TEXT NOT NULL,
              level INTEGER NOT NULL,
              UNIQUE(date, symptom)
            )
          ''');
        },
      ),
    );
    helper = DatabaseHelper(database: db);
  });

  tearDown(() async {
    await helper.database.then((db) => db.close());
  });

  group('LocalSymptomRepository (M45 Task 2)', () {
    test('returns no rows for an unlogged day', () async {
      final repository = LocalSymptomRepository(databaseHelper: helper);
      expect(await repository.getForDate('2026-09-21'), isEmpty);
    });

    test('persists and reloads a symptom reading', () async {
      final repository = LocalSymptomRepository(databaseHelper: helper);

      await repository.save(
        const SymptomLog(
          date: '2026-09-21',
          symptom: SymptomType.pain,
          level: 2,
        ),
      );

      final logs = await repository.getForDate('2026-09-21');
      expect(logs, hasLength(1));
      expect(logs.single.symptom, SymptomType.pain);
      expect(logs.single.level, 2);
    });

    test('upserts the same date + symptom instead of duplicating', () async {
      final repository = LocalSymptomRepository(databaseHelper: helper);

      await repository.save(
        const SymptomLog(
          date: '2026-09-21',
          symptom: SymptomType.energy,
          level: 1,
        ),
      );
      await repository.save(
        const SymptomLog(
          date: '2026-09-21',
          symptom: SymptomType.energy,
          level: 3,
        ),
      );

      final logs = await repository.getForDate('2026-09-21');
      expect(logs, hasLength(1));
      expect(logs.single.level, 3);
    });

    test('keeps distinct symptoms for the same day', () async {
      final repository = LocalSymptomRepository(databaseHelper: helper);

      await repository.save(
        const SymptomLog(
          date: '2026-09-21',
          symptom: SymptomType.pain,
          level: 1,
        ),
      );
      await repository.save(
        const SymptomLog(
          date: '2026-09-21',
          symptom: SymptomType.stress,
          level: 2,
        ),
      );

      final logs = await repository.getForDate('2026-09-21');
      expect(logs.map((log) => log.symptom).toSet(), {
        SymptomType.pain,
        SymptomType.stress,
      });
    });

    test('getAll returns every stored reading', () async {
      final repository = LocalSymptomRepository(databaseHelper: helper);

      await repository.save(
        const SymptomLog(
          date: '2026-09-20',
          symptom: SymptomType.pain,
          level: 1,
        ),
      );
      await repository.save(
        const SymptomLog(
          date: '2026-09-21',
          symptom: SymptomType.energy,
          level: 3,
        ),
      );

      expect(await repository.getAll(), hasLength(2));
    });
  });
}
