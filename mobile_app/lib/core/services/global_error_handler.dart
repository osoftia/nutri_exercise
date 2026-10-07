import 'dart:async';
import 'dart:io';

import '../data/error_log_repository.dart';
import '../models/error_log_entry.dart';

/// An HTTP status error represented independently of any networking package.
class AppHttpStatusException implements Exception {
  const AppHttpStatusException(this.statusCode, this.reasonPhrase);

  final int statusCode;
  final String reasonPhrase;

  @override
  String toString() => 'HTTP $statusCode $reasonPhrase';
}

/// Coordinates local forensic logging and sanitized user-facing alerts.
class GlobalErrorHandler {
  GlobalErrorHandler({
    required ErrorLogRepository repository,
    required void Function(String message) showAlert,
    DateTime Function()? clock,
  })  : _repository = repository,
        _showAlert = showAlert,
        _clock = clock ?? DateTime.now;

  final ErrorLogRepository _repository;
  final void Function(String message) _showAlert;
  final DateTime Function() _clock;

  Future<void> capture(
    Object error,
    StackTrace stackTrace, {
    Uri? requestUri,
  }) async {
    final code = _errorCode(error);
    final entry = ErrorLogEntry(
      timestamp: _clock().toUtc(),
      errorCode: code,
      message: error.toString(),
      stackTrace: stackTrace.toString(),
      requestUrl: requestUri?.toString() ?? '',
    );
    try {
      _showAlert(_friendlyMessage(code));
    } catch (_) {
      // An unavailable ScaffoldMessenger must not hide or replace the error.
    }
    try {
      await _repository.record(entry);
    } catch (_) {
      // Forensics storage is best-effort and must not mask the original error.
    }
  }

  static String _errorCode(Object error) {
    if (error is AppHttpStatusException) return '${error.statusCode}';
    final type = error.runtimeType.toString().toLowerCase();
    final message = error.toString();
    final httpMatch =
        RegExp(r'HTTP\s+(\d{3})', caseSensitive: false).firstMatch(message);
    final statusMatch = RegExp(r'status code\s+(\d{3})', caseSensitive: false)
        .firstMatch(message);
    final status = httpMatch?.group(1) ?? statusMatch?.group(1);
    if (status != null) return status;
    if (error is TimeoutException || type.contains('timeout')) return 'timeout';
    if (error is SocketException ||
        type.contains('network') ||
        type.contains('socket') ||
        type.contains('unreachable')) {
      return 'network';
    }
    if (error is FormatException || type.contains('parse')) return 'parse';
    return 'error';
  }

  static String _friendlyMessage(String code) {
    if (code == 'network') {
      return 'En este momento no hay conexión, intente más tarde.';
    }
    if (code == 'timeout') {
      return 'La solicitud tardó demasiado. Inténtelo de nuevo más tarde.';
    }
    final status = int.tryParse(code);
    if (status != null && status >= 500) {
      return 'El servicio no está disponible ahora. Inténtelo más tarde.';
    }
    return 'Ha ocurrido un error. Inténtelo de nuevo.';
  }
}

/// App-wide access point used by network services and repositories.
class ErrorHandlerRegistry {
  ErrorHandlerRegistry._();

  static GlobalErrorHandler? current;

  static Future<void> capture(
    Object error,
    StackTrace stackTrace, {
    Uri? requestUri,
  }) async {
    await current?.capture(error, stackTrace, requestUri: requestUri);
  }
}
