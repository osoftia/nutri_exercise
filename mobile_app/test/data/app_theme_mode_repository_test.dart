import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/local_app_theme_mode_repository.dart';
import 'package:nutri_mobile_app/core/database/database_helper.dart';
import 'package:nutri_mobile_app/core/database/database_schema.dart';
import 'package:nutri_mobile_app/core/theme/app_theme_mode.dart';
import 'package:nutri_mobile_app/core/state/app_theme_mode_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late Database db;
  late LocalAppThemeModeRepository repository;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DatabaseSchema.version,
        onCreate: DatabaseSchema.createAll,
      ),
    );
    repository = LocalAppThemeModeRepository(
      databaseHelper: DatabaseHelper(database: db),
    );
  });

  tearDown(() => db.close());

  test('loads technical blueprint by default and persists Apple Minimalist',
      () async {
    final controller = AppThemeModeController(repository: repository);
    await controller.load();
    expect(controller.mode, AppThemeMode.technicalBlueprint);

    await controller.setMode(AppThemeMode.appleMinimalist);

    final restored = AppThemeModeController(repository: repository);
    await restored.load();
    expect(restored.mode, AppThemeMode.appleMinimalist);
  });
}
