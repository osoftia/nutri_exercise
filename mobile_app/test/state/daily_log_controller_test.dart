import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_log_repository.dart';
import 'package:nutri_mobile_app/core/services/log_parse_service.dart';
import 'package:nutri_mobile_app/core/state/daily_log_controller.dart';

void main() {
  group('DailyLogController', () {
    test('load populates the text from the repository', () async {
      final repo = MockDailyLogRepository(
        seed: {'2026-09-03': 'Trained chest'},
      );
      final controller = DailyLogController(repository: repo);

      await controller.load(date: '2026-09-03');

      expect(controller.text, 'Trained chest');
    });

    test('load with no saved log leaves the text empty', () async {
      final repo = MockDailyLogRepository();
      final controller = DailyLogController(repository: repo);

      await controller.load(date: '2026-09-03');

      expect(controller.text, '');
    });

    test('save persists a trimmed summary and returns true', () async {
      final repo = MockDailyLogRepository();
      final controller = DailyLogController(repository: repo);
      await controller.load(date: '2026-09-03');

      final saved = await controller.save('  Ate chicken and rice  ');

      expect(saved, isTrue);
      expect(controller.text, 'Ate chicken and rice');
      expect((await repo.getByDate('2026-09-03'))?.text, 'Ate chicken and rice');
    });

    test('save rejects an empty summary', () async {
      final repo = MockDailyLogRepository();
      final controller = DailyLogController(repository: repo);
      await controller.load(date: '2026-09-03');

      final saved = await controller.save('   ');

      expect(saved, isFalse);
      expect(await repo.getByDate('2026-09-03'), isNull);
    });
  });

  group('DailyLogController submit', () {
    LogParseService parseService(String body, int status) => LogParseService(
      baseUrl: 'http://test',
      client: MockClient((_) async => http.Response(body, status)),
    );

    test('parses and saves, exposing the parsed result', () async {
      final repo = MockDailyLogRepository();
      final controller = DailyLogController(
        repository: repo,
        parseService: parseService(
          jsonEncode({
            'calories': 400,
            'macros': {'protein': 30, 'carbs': 20, 'fat': 10},
          }),
          200,
        ),
      );
      await controller.load(date: '2026-09-03');

      final saved = await controller.submit('Ate chicken');

      expect(saved, isTrue);
      expect(controller.parseResult?.calories, 400);
      expect(controller.parseResult?.protein, 30);
      expect(controller.parseError, isNull);
      expect((await repo.getByDate('2026-09-03'))?.text, 'Ate chicken');
    });

    test('still saves locally when the backend is unreachable', () async {
      final repo = MockDailyLogRepository();
      final controller = DailyLogController(
        repository: repo,
        parseService: parseService('boom', 500),
      );
      await controller.load(date: '2026-09-03');

      final saved = await controller.submit('Ate chicken');

      expect(saved, isTrue);
      expect(controller.parseResult, isNull);
      expect(controller.parseError, isNotNull);
      expect((await repo.getByDate('2026-09-03'))?.text, 'Ate chicken');
    });

    test('rejects an empty summary without parsing', () async {
      final repo = MockDailyLogRepository();
      final controller = DailyLogController(
        repository: repo,
        parseService: parseService('{}', 200),
      );
      await controller.load(date: '2026-09-03');

      final saved = await controller.submit('   ');

      expect(saved, isFalse);
      expect(controller.parseResult, isNull);
      expect(await repo.getByDate('2026-09-03'), isNull);
    });
  });
}
