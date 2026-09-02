import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/services/ai_chat_service.dart';
import 'package:nutri_mobile_app/core/state/ai_chat_controller.dart';

class _FakeAiChatService implements AiChatService {
  _FakeAiChatService(this._handler);

  final Future<String> Function(String message, List<ChatTurn> history)
  _handler;
  final List<List<ChatTurn>> sentHistories = [];

  @override
  String get baseUrl => 'http://fake';

  @override
  Duration get timeout => const Duration(seconds: 1);

  @override
  Future<String> sendMessage({
    required String message,
    List<ChatTurn> history = const [],
  }) {
    sentHistories.add(history);
    return _handler(message, history);
  }
}

void main() {
  group('AiChatController.send', () {
    test('appends the user and assistant messages on success', () async {
      final controller = AiChatController(
        service: _FakeAiChatService((message, history) async => 'A reply'),
      );

      await controller.send('Push pull 4 days');

      expect(controller.status, AiChatStatus.success);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.messages, hasLength(2));
      expect(controller.messages[0].text, 'Push pull 4 days');
      expect(controller.messages[0].isUser, isTrue);
      expect(controller.messages[1].text, 'A reply');
      expect(controller.messages[1].isUser, isFalse);
    });

    test('forwards the previous turns as conversation history', () async {
      final service = _FakeAiChatService(
        (message, history) async => 'A reply',
      );
      final controller = AiChatController(service: service);

      await controller.send('Push pull 4 days');
      await controller.send('Add a leg day');

      expect(service.sentHistories, hasLength(2));
      expect(service.sentHistories.first, isEmpty);
      expect(service.sentHistories.last, hasLength(2));
      expect(service.sentHistories.last[0].role, 'user');
      expect(service.sentHistories.last[0].content, 'Push pull 4 days');
      expect(service.sentHistories.last[1].role, 'assistant');
      expect(service.sentHistories.last[1].content, 'A reply');
    });

    test('maps a timeout to the retry copy and the error state', () async {
      final controller = AiChatController(
        service: _FakeAiChatService(
          (message, history) async => throw const AiChatTimeoutException(),
        ),
      );

      await controller.send('Push pull 4 days');

      expect(controller.status, AiChatStatus.error);
      expect(
        controller.errorMessage,
        'The assistant is taking too long. Please try again.',
      );
      expect(controller.messages, hasLength(1));
      expect(controller.messages.first.isUser, isTrue);
    });

    test('maps any other failure to the unavailable copy', () async {
      final controller = AiChatController(
        service: _FakeAiChatService(
          (message, history) async => throw const AiChatHttpException(500),
        ),
      );

      await controller.send('Push pull 4 days');

      expect(controller.status, AiChatStatus.error);
      expect(
        controller.errorMessage,
        'The assistant is unavailable right now.',
      );
    });

    test('ignores an empty message', () async {
      final controller = AiChatController(
        service: _FakeAiChatService((message, history) async => 'A reply'),
      );

      await controller.send('   ');

      expect(controller.messages, isEmpty);
      expect(controller.status, AiChatStatus.idle);
    });

    test('ignores a second send while a request is in flight', () async {
      final completer = Completer<String>();
      final controller = AiChatController(
        service: _FakeAiChatService((message, history) => completer.future),
      );

      final first = controller.send('First');
      await controller.send('Second');

      expect(controller.messages.map((m) => m.text), ['First']);

      completer.complete('Reply');
      await first;

      expect(controller.messages.map((m) => m.text), ['First', 'Reply']);
    });
  });

  group('AiChatController local actions', () {
    test('appendUserMessage adds a user bubble without a request', () {
      final controller = AiChatController(
        service: _FakeAiChatService((message, history) async => 'A reply'),
      );

      controller.appendUserMessage('Hello');

      expect(controller.messages, hasLength(1));
      expect(controller.messages.first.text, 'Hello');
      expect(controller.messages.first.isUser, isTrue);
      expect(controller.isLoading, isFalse);
    });

    test('appendErrorMessage records the error copy and error state', () {
      final controller = AiChatController(
        service: _FakeAiChatService((message, history) async => 'A reply'),
      );

      controller.appendErrorMessage('AI service unavailable right now.');

      expect(controller.status, AiChatStatus.error);
      expect(controller.errorMessage, 'AI service unavailable right now.');
      expect(controller.isLoading, isFalse);
    });
  });
}
