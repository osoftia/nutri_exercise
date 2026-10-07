/// One technical failure captured for local debugging and forensics.
class ErrorLogEntry {
  const ErrorLogEntry({
    required this.timestamp,
    required this.errorCode,
    required this.message,
    required this.stackTrace,
    this.requestUrl = '',
    this.requestBody = '',
    this.id,
  });

  final int? id;
  final DateTime timestamp;
  final String errorCode;
  final String message;
  final String stackTrace;
  final String requestUrl;
  final String requestBody;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'error_code': errorCode,
        'message': message,
        'stack_trace': stackTrace,
        'request_url': requestUrl,
        'request_body': requestBody,
      };

  factory ErrorLogEntry.fromMap(Map<String, Object?> map) => ErrorLogEntry(
        id: map['id'] as int?,
        timestamp: DateTime.parse(map['timestamp'] as String),
        errorCode: map['error_code'] as String,
        message: map['message'] as String,
        stackTrace: map['stack_trace'] as String,
        requestUrl: map['request_url'] as String? ?? '',
        requestBody: map['request_body'] as String? ?? '',
      );
}
