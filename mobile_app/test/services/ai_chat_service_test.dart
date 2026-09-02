import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutri_mobile_app/core/services/ai_chat_service.dart';

void main() {
  group('ChatTurn', () {
    test('serializes role and content to JSON', () {
      const turn = ChatTurn(role: 'user', content: 'Push pull 4 days');

      expect(turn.toJson(), {
        'role': 'user',
        'content': 'Push pull 4 days',
      });
    });
  });

  group('AiChatService exceptions', () {
    test('AiChatTimeoutException exposes a readable message', () {
      expect(
        const AiChatTimeoutException().toString(),
        'The assistant is taking too long.',
      );
    });

    test('AiChatHttpException includes the status code', () {
      expect(
        const AiChatHttpException(500).toString(),
        'The assistant returned HTTP 500.',
      );
    });

    test('AiChatParseException exposes a readable message', () {
      expect(
        const AiChatParseException().toString(),
        'The assistant returned an invalid response.',
      );
    });
  });

  group('AiChatService.sendMessage', () {
    test('defaults to an internal HTTP client and a 60 second timeout', () {
      final service = AiChatService(baseUrl: 'http://test');

      expect(service.baseUrl, 'http://test');
      expect(service.timeout, const Duration(seconds: 60));
    });

    test('POSTs to /api/ai/chat and returns the assistant message', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'id': '7f1e9c2b-3a4d-4e5f-8a6b-0c1d2e3f4a5b',
            'message': 'Here is your routine',
            'model': 'llama3',
            'createdAt': '2026-09-02T10:15:30Z',
          }),
          200,
        );
      });
      final service = AiChatService(
        baseUrl: 'http://192.168.1.10:5039',
        client: client,
      );

      final reply = await service.sendMessage(message: 'Push pull 4 days');

      expect(reply, 'Here is your routine');
      expect(captured.method, 'POST');
      expect(captured.url.path, '/api/ai/chat');
      expect(captured.headers['Content-Type'], 'application/json');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['message'], 'Push pull 4 days');
      expect(body['history'], isEmpty);
    });

    test('includes the conversation history in the request body', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode({'message': 'ok'}), 200);
      });
      final service = AiChatService(baseUrl: 'http://test', client: client);

      await service.sendMessage(
        message: 'Add a leg day',
        history: const [
          ChatTurn(role: 'user', content: 'Push pull 4 days'),
          ChatTurn(role: 'assistant', content: 'Here is a split'),
        ],
      );

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      final history = body['history'] as List<dynamic>;
      expect(history, hasLength(2));
      expect(history[0], {'role': 'user', 'content': 'Push pull 4 days'});
      expect(history[1], {'role': 'assistant', 'content': 'Here is a split'});
    });

    test('throws AiChatHttpException on a 500 response', () async {
      final client = MockClient(
        (request) async => http.Response(
          jsonEncode({'error': 'The assistant is unavailable right now.'}),
          500,
        ),
      );
      final service = AiChatService(baseUrl: 'http://test', client: client);

      await expectLater(
        service.sendMessage(message: 'Push pull 4 days'),
        throwsA(
          isA<AiChatHttpException>()
              .having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });

    test('throws AiChatTimeoutException when the response exceeds the timeout',
        () async {
      final never = Completer<http.Response>();
      final client = MockClient((request) => never.future);
      final service = AiChatService(
        baseUrl: 'http://test',
        client: client,
        timeout: const Duration(milliseconds: 1),
      );

      await expectLater(
        service.sendMessage(message: 'Push pull 4 days'),
        throwsA(isA<AiChatTimeoutException>()),
      );
    });

    test('throws AiChatParseException on an invalid JSON body', () async {
      final client = MockClient(
        (request) async => http.Response('not-json', 200),
      );
      final service = AiChatService(baseUrl: 'http://test', client: client);

      await expectLater(
        service.sendMessage(message: 'Push pull 4 days'),
        throwsA(isA<AiChatParseException>()),
      );
    });

    test('throws AiChatParseException when the body is not a JSON object',
        () async {
      final client = MockClient(
        (request) async => http.Response('["a", "b"]', 200),
      );
      final service = AiChatService(baseUrl: 'http://test', client: client);

      await expectLater(
        service.sendMessage(message: 'Push pull 4 days'),
        throwsA(isA<AiChatParseException>()),
      );
    });

    test('throws AiChatParseException when the message field is missing',
        () async {
      final client = MockClient(
        (request) async => http.Response(jsonEncode({'model': 'llama3'}), 200),
      );
      final service = AiChatService(baseUrl: 'http://test', client: client);

      await expectLater(
        service.sendMessage(message: 'Push pull 4 days'),
        throwsA(isA<AiChatParseException>()),
      );
    });

    test('throws AiChatParseException when the message field is empty',
        () async {
      final client = MockClient(
        (request) async => http.Response(jsonEncode({'message': ''}), 200),
      );
      final service = AiChatService(baseUrl: 'http://test', client: client);

      await expectLater(
        service.sendMessage(message: 'Push pull 4 days'),
        throwsA(isA<AiChatParseException>()),
      );
    });
  });
}
