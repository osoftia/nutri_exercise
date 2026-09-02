import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';

/// A single conversational turn sent to the backend for context.
class ChatTurn {
  const ChatTurn({required this.role, required this.content});

  final String role;
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

/// The chat request did not complete within the configured [AiChatService.timeout].
class AiChatTimeoutException implements Exception {
  const AiChatTimeoutException();

  @override
  String toString() => 'The assistant is taking too long.';
}

/// The backend responded with a non-success HTTP status.
class AiChatHttpException implements Exception {
  const AiChatHttpException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'The assistant returned HTTP $statusCode.';
}

/// The backend response was not valid JSON or lacked a usable reply.
class AiChatParseException implements Exception {
  const AiChatParseException();

  @override
  String toString() => 'The assistant returned an invalid response.';
}

/// Sends a user prompt to the C# .NET API (`POST /api/ai/chat`) and parses the
/// assistant reply out of the JSON response.
class AiChatService {
  AiChatService({
    required this.baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 60),
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  final Duration timeout;

  /// Sends [message] (with optional [history] for context) and returns the
  /// assistant reply. Throws [AiChatTimeoutException], [AiChatHttpException] or
  /// [AiChatParseException] on failure.
  Future<String> sendMessage({
    required String message,
    List<ChatTurn> history = const [],
  }) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.aiChatPath}');

    final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': message,
              'history': history.map((turn) => turn.toJson()).toList(),
            }),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const AiChatTimeoutException();
    }

    if (response.statusCode != 200) {
      throw AiChatHttpException(response.statusCode);
    }

    try {
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        throw const AiChatParseException();
      }
      final reply = body['message'];
      if (reply is! String || reply.isEmpty) {
        throw const AiChatParseException();
      }
      return reply;
    } on AiChatParseException {
      rethrow;
    } catch (_) {
      throw const AiChatParseException();
    }
  }
}
