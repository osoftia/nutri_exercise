import 'package:flutter/foundation.dart';

import '../services/ai_chat_service.dart';

/// Lifecycle of a single AI chat exchange.
enum AiChatStatus { idle, loading, success, error }

/// A single bubble in the AI chat transcript.
class AiChatMessage {
  const AiChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

/// Owns the AI chat transcript and the state of the current request.
///
/// The UI listens to this controller and rebuilds on every transition so the
/// loading indicator, the assistant reply and any error are rendered from a
/// single source of truth.
class AiChatController extends ChangeNotifier {
  AiChatController({required AiChatService service}) : _service = service;

  final AiChatService _service;

  final List<AiChatMessage> _messages = [];
  AiChatStatus _status = AiChatStatus.idle;
  String? _errorMessage;

  List<AiChatMessage> get messages => List.unmodifiable(_messages);
  AiChatStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AiChatStatus.loading;

  /// Sends [text] to the backend: appends the user bubble, enters the loading
  /// state, then records the assistant reply or a mapped error.
  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isLoading) return;

    final history = _messages
        .map(
          (message) => ChatTurn(
            role: message.isUser ? 'user' : 'assistant',
            content: message.text,
          ),
        )
        .toList();

    _messages.add(AiChatMessage(text: trimmed, isUser: true));
    _status = AiChatStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final reply = await _service.sendMessage(
        message: trimmed,
        history: history,
      );
      _messages.add(AiChatMessage(text: reply, isUser: false));
      _status = AiChatStatus.success;
    } on AiChatTimeoutException {
      _errorMessage = 'The assistant is taking too long. Please try again.';
      _status = AiChatStatus.error;
    } catch (_) {
      _errorMessage = 'The assistant is unavailable right now.';
      _status = AiChatStatus.error;
    }
    notifyListeners();
  }

  /// Appends a user bubble without a network round-trip (used when the
  /// connectivity guard stops the request before it starts).
  void appendUserMessage(String text) {
    _messages.add(AiChatMessage(text: text, isUser: true));
    notifyListeners();
  }

  /// Records a local failure (e.g. the connectivity guard threw) as an error.
  void appendErrorMessage(String message) {
    _errorMessage = message;
    _status = AiChatStatus.error;
    notifyListeners();
  }
}
