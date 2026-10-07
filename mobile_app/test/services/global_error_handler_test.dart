import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutri_mobile_app/core/data/error_log_repository.dart';
import 'package:nutri_mobile_app/core/services/ai_chat_service.dart';
import 'package:nutri_mobile_app/core/models/error_log_entry.dart';
import 'package:nutri_mobile_app/core/services/global_error_handler.dart';

class _MemoryErrorLogRepository implements ErrorLogRepository {
  final List<ErrorLogEntry> entries = [];

  @override
  Future<List<ErrorLogEntry>> getAll() async => entries.reversed.toList();

  @override
  Future<void> record(ErrorLogEntry entry) async => entries.add(entry);
}

void main() {
  late _MemoryErrorLogRepository repository;
  late List<String> alerts;
  late GlobalErrorHandler handler;

  setUp(() {
    repository = _MemoryErrorLogRepository();
    alerts = [];
    handler = GlobalErrorHandler(
      repository: repository,
      showAlert: alerts.add,
    );
  });

  test('records the exact HTTP status and shows a sanitized friendly alert',
      () async {
    final error = AppHttpStatusException(404, 'Not Found');
    final stack = StackTrace.current;

    await handler.capture(
      error,
      stack,
      requestUri: Uri.parse('https://api.example.test/clinical/diagnosis'),
    );

    expect(repository.entries.single.errorCode, '404');
    expect(repository.entries.single.message, 'HTTP 404 Not Found');
    expect(repository.entries.single.stackTrace, stack.toString());
    expect(repository.entries.single.requestUrl,
        'https://api.example.test/clinical/diagnosis');
    expect(alerts.single, contains('Ha ocurrido un error'));
    expect(alerts.single, isNot(contains('404')));
  });

  test('classifies network errors, timeouts, and malformed JSON', () async {
    await handler.capture(
        const SocketException('Connection refused'), StackTrace.current);
    await handler.capture(
        TimeoutException('Request exceeded 10 seconds'), StackTrace.current);
    await handler.capture(const FormatException('Unexpected token at offset 3'),
        StackTrace.current);

    expect(repository.entries.map((entry) => entry.errorCode), [
      'network',
      'timeout',
      'parse',
    ]);
    expect(alerts[0], contains('no hay conexión'));
    expect(alerts[1], contains('tardó demasiado'));
    expect(alerts[2], contains('Ha ocurrido un error'));
  });

  test('server errors use the temporary-unavailable alert', () async {
    await handler.capture(
      const AppHttpStatusException(503, 'Service Unavailable'),
      StackTrace.current,
    );

    expect(repository.entries.single.errorCode, '503');
    expect(alerts.single, contains('servicio no está disponible'));
  });

  test('AI HTTP boundary forwards raw server failures to the global handler',
      () async {
    ErrorHandlerRegistry.current = handler;
    addTearDown(() => ErrorHandlerRegistry.current = null);
    final service = AiChatService(
      baseUrl: 'https://api.example.test',
      client: MockClient((_) async =>
          http.Response('missing', 404, reasonPhrase: 'Not Found')),
    );

    await expectLater(
      service.sendMessage(message: 'hello'),
      throwsA(isA<AiChatHttpException>()),
    );

    expect(repository.entries.single.errorCode, '404');
    expect(repository.entries.single.message, 'HTTP 404 Not Found');
    expect(repository.entries.single.requestUrl,
        'https://api.example.test/api/aiproxy/chat');
    expect(alerts.single, contains('Ha ocurrido un error'));
  });

  test('network failures retain the exact target URL', () async {
    ErrorHandlerRegistry.current = handler;
    addTearDown(() => ErrorHandlerRegistry.current = null);
    final service = AiChatService(
      baseUrl: 'http://10.0.2.2:5039',
      client: MockClient(
          (_) async => throw const SocketException('Connection refused')),
    );

    await expectLater(
      service.sendMessage(message: 'hello'),
      throwsA(isA<AiChatNetworkException>()),
    );

    expect(repository.entries.single.errorCode, 'network');
    expect(repository.entries.single.requestUrl,
        'http://10.0.2.2:5039/api/aiproxy/chat');
    expect(alerts.single, contains('no hay conexión'));
  });
}
