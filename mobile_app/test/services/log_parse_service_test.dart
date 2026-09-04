import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutri_mobile_app/core/services/log_parse_service.dart';

void main() {
  test('parse POSTs rawText and returns the parsed response', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/log/parse');
      expect(jsonDecode(request.body), {'rawText': 'Ate chicken and rice'});
      return http.Response(
        jsonEncode({
          'calories': 500,
          'macros': {'protein': 40, 'carbs': 30, 'fat': 15},
          'muscleGroups': ['chest'],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = LogParseService(baseUrl: 'http://test', client: client);

    final result = await service.parse('Ate chicken and rice');

    expect(result.calories, 500);
    expect(result.protein, 40);
    expect(result.muscleGroups, ['chest']);
  });

  test('parse throws LogParseHttpException on a non-200 response', () async {
    final client = MockClient((_) async => http.Response('boom', 500));
    final service = LogParseService(baseUrl: 'http://test', client: client);

    await expectLater(
      service.parse('x'),
      throwsA(isA<LogParseHttpException>()),
    );
  });

  test('parse throws LogParseParseException on invalid JSON', () async {
    final client = MockClient((_) async => http.Response('not json', 200));
    final service = LogParseService(baseUrl: 'http://test', client: client);

    await expectLater(
      service.parse('x'),
      throwsA(isA<LogParseParseException>()),
    );
  });
}
