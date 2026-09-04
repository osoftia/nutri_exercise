import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../models/log_parse_response.dart';

/// The parse request did not complete within the configured timeout.
class LogParseTimeoutException implements Exception {
  const LogParseTimeoutException();

  @override
  String toString() => 'The log parser is taking too long.';
}

/// The backend could not be reached (connection refused / no network).
class LogParseNetworkException implements Exception {
  const LogParseNetworkException();

  @override
  String toString() => 'The log parser is unreachable.';
}

/// The backend responded with a non-success HTTP status.
class LogParseHttpException implements Exception {
  const LogParseHttpException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'The log parser returned HTTP $statusCode.';
}

/// The backend response was not valid JSON or lacked the expected fields.
class LogParseParseException implements Exception {
  const LogParseParseException();

  @override
  String toString() => 'The log parser returned an invalid response.';
}

/// Sends a free-text daily summary to the C# .NET API
/// (`POST /api/log/parse`) and parses the structured result
/// (calories, macros, muscle groups) out of the JSON response.
class LogParseService {
  LogParseService({
    required this.baseUrl,
    http.Client? client,
    this.timeout = const Duration(seconds: 60),
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  final Duration timeout;

  /// Posts [rawText] and returns the parsed [LogParseResponse].
  ///
  /// Throws [LogParseTimeoutException], [LogParseNetworkException],
  /// [LogParseHttpException] or [LogParseParseException] on failure. Network and
  /// timeout failures are logged to the console with the exact error.
  Future<LogParseResponse> parse(String rawText) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.logParsePath}');

    final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'rawText': rawText}),
          )
          .timeout(timeout);
    } on TimeoutException catch (e) {
      debugPrint('API Error: $e');
      throw const LogParseTimeoutException();
    } on SocketException catch (e) {
      debugPrint('API Error: $e');
      throw const LogParseNetworkException();
    } catch (e) {
      debugPrint('API Error: $e');
      throw const LogParseNetworkException();
    }

    if (response.statusCode != 200) {
      throw LogParseHttpException(response.statusCode);
    }

    try {
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        throw const LogParseParseException();
      }
      return LogParseResponse.fromJson(body);
    } on LogParseParseException {
      rethrow;
    } catch (_) {
      throw const LogParseParseException();
    }
  }
}
