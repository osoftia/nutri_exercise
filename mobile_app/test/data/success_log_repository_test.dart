import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/local_success_log_repository.dart';
import 'package:nutri_mobile_app/core/database/database_helper.dart';
import 'package:nutri_mobile_app/core/database/database_schema.dart';
import 'package:nutri_mobile_app/core/models/success_log_entry.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late Database db;
  late LocalSuccessLogRepository repository;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: DatabaseSchema.version,
        onCreate: DatabaseSchema.createAll,
      ),
    );
    repository = LocalSuccessLogRepository(
      databaseHelper: DatabaseHelper(database: db),
    );
  });

  tearDown(() => db.close());

  test('persists raw successful responses with URL and timestamp newest first',
      () async {
    final older = SuccessLogEntry(
      timestamp: DateTime.utc(2026, 10, 5, 12),
      statusCode: '200',
      label: 'clinical_diagnosis',
      requestUrl: 'https://api.example.test/api/clinical/diagnosis',
      requestBody: '{"preferences":"vegan"}',
      responseBody: '{"diagnosticReport":"Eat more fiber"}',
    );
    final newer = SuccessLogEntry(
      timestamp: DateTime.utc(2026, 10, 6, 12),
      statusCode: '201',
      label: 'log_parse',
      requestUrl: 'https://api.example.test/api/log/parse',
      requestBody: '{"text":"today lunch"}',
      responseBody: '{"calories":250}',
    );

    await repository.record(older);
    await repository.record(newer);

    final records = await repository.getAll();
    expect(records, hasLength(2));
    expect(records.first.statusCode, '201');
    expect(records.first.label, 'log_parse');
    expect(records.first.requestUrl, newer.requestUrl);
    expect(records.first.requestBody, newer.requestBody);
    expect(records.first.responseBody, newer.responseBody);
    expect(records.first.timestamp, newer.timestamp);
    expect(records.last.statusCode, '200');
    expect(records.last.requestUrl, older.requestUrl);
    expect(records.last.responseBody, older.responseBody);
  });

  test('v19 migration adds local_success_logs without losing error records',
      () async {
    await db.execute('DROP TABLE IF EXISTS local_success_logs');
    await db.insert('local_error_logs', {
      'timestamp': DateTime.utc(2026, 10, 6).toIso8601String(),
      'error_code': '500',
      'message': 'legacy error',
      'stack_trace': 'legacy stack',
    });

    await DatabaseSchema.upgrade(db, 19, DatabaseSchema.version);

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    expect(
      tables.map((table) => table['name']),
      contains('local_success_logs'),
    );
    final columns = await db.rawQuery('PRAGMA table_info(local_success_logs)');
    expect(
      columns.map((column) => column['name']),
      containsAll([
        'id',
        'timestamp',
        'status_code',
        'label',
        'request_url',
        'request_body',
        'response_body',
      ]),
    );
    final errors = await db.query('local_error_logs');
    expect(errors.single['message'], 'legacy error');
  });
}
