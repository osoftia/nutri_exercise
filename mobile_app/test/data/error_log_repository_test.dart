import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/local_error_log_repository.dart';
import 'package:nutri_mobile_app/core/database/database_helper.dart';
import 'package:nutri_mobile_app/core/database/database_schema.dart';
import 'package:nutri_mobile_app/core/models/error_log_entry.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late Database db;
  late LocalErrorLogRepository repository;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DatabaseSchema.version,
        onCreate: DatabaseSchema.createAll,
      ),
    );
    repository = LocalErrorLogRepository(
      databaseHelper: DatabaseHelper(database: db),
    );
  });

  tearDown(() => db.close());

  test('persists precise error details and reads newest records first', () async {
    final older = ErrorLogEntry(
      timestamp: DateTime.utc(2026, 10, 5, 12),
      errorCode: '404',
      message: 'HTTP 404 Not Found',
      stackTrace: '#0 request (test.dart:10:2)',
    );
    final newer = ErrorLogEntry(
      timestamp: DateTime.utc(2026, 10, 6, 12),
      errorCode: 'timeout',
      message: 'TimeoutException after 0:00:10',
      stackTrace: '#0 send (test.dart:20:2)',
    );

    await repository.record(older);
    await repository.record(newer);

    final records = await repository.getAll();
    expect(records, hasLength(2));
    expect(records.first.errorCode, 'timeout');
    expect(records.first.message, newer.message);
    expect(records.first.stackTrace, newer.stackTrace);
    expect(records.first.timestamp, newer.timestamp);
    expect(records.last.errorCode, '404');
  });

  test('v14 migration creates local_error_logs with required columns', () async {
    final legacyDb = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 14),
    );
    addTearDown(legacyDb.close);

    await DatabaseSchema.upgrade(legacyDb, 14, DatabaseSchema.version);

    final columns = await legacyDb.rawQuery('PRAGMA table_info(local_error_logs)');
    expect(
      columns.map((column) => column['name']),
      containsAll(['id', 'timestamp', 'error_code', 'message', 'stack_trace']),
    );
  });
}
