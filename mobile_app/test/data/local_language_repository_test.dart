import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/local_language_repository.dart';
import 'package:nutri_mobile_app/core/database/database_helper.dart';
import 'package:nutri_mobile_app/core/domain/i18n/app_language.dart';
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
            CREATE TABLE app_settings (
              setting_key TEXT PRIMARY KEY,
              setting_value TEXT NOT NULL
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

  group('LocalLanguageRepository (i18n Task 2)', () {
    test('returns null before anything is stored', () async {
      final repository = LocalLanguageRepository(databaseHelper: helper);
      expect(await repository.get(), isNull);
    });

    test('persists and reloads the selected language', () async {
      final repository = LocalLanguageRepository(databaseHelper: helper);

      await repository.save(AppLanguage.spanish);
      expect(await repository.get(), AppLanguage.spanish);

      await repository.save(AppLanguage.english);
      expect(await repository.get(), AppLanguage.english);
    });

    test('round-trips through the controller across instances', () async {
      final first = LocalLanguageRepository(databaseHelper: helper);
      await first.save(AppLanguage.spanish);

      final second = LocalLanguageRepository(databaseHelper: helper);
      expect(await second.get(), AppLanguage.spanish);
    });

    test('ignores an unknown stored code', () async {
      await helper.upsertSetting(LocalLanguageRepository.settingKey, 'zz');
      final repository = LocalLanguageRepository(databaseHelper: helper);
      expect(await repository.get(), isNull);
    });
  });
}
