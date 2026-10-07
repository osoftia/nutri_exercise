import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/services/ai_chat_service.dart';
import 'package:nutri_mobile_app/core/data/local_http_timeout_settings_repository.dart';
import 'package:nutri_mobile_app/core/database/database_helper.dart';
import 'package:nutri_mobile_app/core/database/database_schema.dart';
import 'package:nutri_mobile_app/core/services/http_timeout_configuration.dart';
import 'package:nutri_mobile_app/core/state/http_timeout_settings_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late Database db;
  late LocalHttpTimeoutSettingsRepository repository;

  setUp(() async {
    HttpTimeoutConfiguration.reset();
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DatabaseSchema.version,
        onCreate: DatabaseSchema.createAll,
      ),
    );
    repository = LocalHttpTimeoutSettingsRepository(
      databaseHelper: DatabaseHelper(database: db),
    );
  });

  tearDown(() => db.close());

  test('restores and persists the shared timeout setting', () async {
    final controller = HttpTimeoutSettingsController(repository: repository);
    await controller.load();
    expect(controller.timeoutSeconds, HttpTimeoutConfiguration.defaultSeconds);
    expect(HttpTimeoutConfiguration.currentTimeout.inSeconds,
        HttpTimeoutConfiguration.defaultSeconds);

    await controller.setTimeoutSeconds(35);
    expect(controller.timeoutSeconds, 35);
    expect(HttpTimeoutConfiguration.currentTimeout.inSeconds, 35);
    expect(
      AiChatService(baseUrl: 'https://api.example.test').timeout.inSeconds,
      35,
    );

    final restored = HttpTimeoutSettingsController(repository: repository);
    await restored.load();
    expect(restored.timeoutSeconds, 35);
  });

  test('only accepts timeout choices between 10 and 60 seconds', () async {
    final controller = HttpTimeoutSettingsController(repository: repository);
    await controller.load();

    await expectLater(controller.setTimeoutSeconds(9), throwsRangeError);
    await expectLater(controller.setTimeoutSeconds(61), throwsRangeError);
  });
}
