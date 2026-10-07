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

  test('persists precise error details and reads newest records first',
      () async {
    final older = ErrorLogEntry(
      timestamp: DateTime.utc(2026, 10, 5, 12),
      errorCode: '404',
      message: 'HTTP 404 Not Found',
      stackTrace: '#0 request (test.dart:10:2)',
      requestUrl: 'https://api.example.test/api/clinical/diagnosis',
      requestBody: '{"preferences":"vegan"}',
    );
    final newer = ErrorLogEntry(
      timestamp: DateTime.utc(2026, 10, 6, 12),
      errorCode: 'timeout',
      message: 'TimeoutException after 0:00:10',
      stackTrace: '#0 send (test.dart:20:2)',
      requestUrl: 'https://api.example.test/api/log/parse',
      requestBody: '{"text":"today lunch"}',
    );

    await repository.record(older);
    await repository.record(newer);

    final records = await repository.getAll();
    expect(records, hasLength(2));
    expect(records.first.errorCode, 'timeout');
    expect(records.first.message, newer.message);
    expect(records.first.stackTrace, newer.stackTrace);
    expect(records.first.timestamp, newer.timestamp);
    expect(records.first.requestUrl, newer.requestUrl);
    expect(records.first.requestBody, newer.requestBody);
    expect(records.last.errorCode, '404');
    expect(records.last.requestUrl, older.requestUrl);
    expect(records.last.requestBody, older.requestBody);
  });

  test('v16 migration adds request_body without losing previous error records',
      () async {
    await db.execute('DROP TABLE local_error_logs');
    await db.execute('''
      CREATE TABLE local_error_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        error_code TEXT NOT NULL,
        message TEXT NOT NULL,
        stack_trace TEXT NOT NULL,
        request_url TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.insert('local_error_logs', {
      'timestamp': DateTime.utc(2026, 10, 6).toIso8601String(),
      'error_code': '404',
      'message': 'HTTP 404 Not Found',
      'stack_trace': 'legacy stack',
      'request_url': 'https://api.example.test/missing',
    });

    await DatabaseSchema.upgrade(db, 16, DatabaseSchema.version);

    final columns = await db.rawQuery('PRAGMA table_info(local_error_logs)');
    expect(
      columns.map((column) => column['name']),
      containsAll([
        'id',
        'timestamp',
        'error_code',
        'message',
        'stack_trace',
        'request_url',
        'request_body',
      ]),
    );
    final rows = await db.query('local_error_logs');
    expect(rows.single['request_url'], 'https://api.example.test/missing');
    expect(rows.single['request_body'], '');
    expect(rows.single['message'], 'HTTP 404 Not Found');
  });
}
