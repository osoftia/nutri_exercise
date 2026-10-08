/// One successful backend exchange captured for local debugging and forensics.
///
/// Unlike [ErrorLogEntry], these records preserve the exact raw request and
/// response bodies that produced a valid payload, so the clinical AI workflow
/// can be audited without re-issuing the network call.
class SuccessLogEntry {
  const SuccessLogEntry({
    required this.timestamp,
    required this.requestUrl,
    required this.responseBody,
    this.statusCode = '200',
    this.label = '',
    this.requestBody = '',
    this.id,
  });

  final int? id;
  final DateTime timestamp;
  final String statusCode;
  final String label;
  final String requestUrl;
  final String requestBody;
  final String responseBody;

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'status_code': statusCode,
        'label': label,
        'request_url': requestUrl,
        'request_body': requestBody,
        'response_body': responseBody,
      };

  factory SuccessLogEntry.fromMap(Map<String, Object?> map) => SuccessLogEntry(
        id: map['id'] as int?,
        timestamp: DateTime.parse(map['timestamp'] as String),
        statusCode: map['status_code'] as String? ?? '200',
        label: map['label'] as String? ?? '',
        requestUrl: map['request_url'] as String? ?? '',
        requestBody: map['request_body'] as String? ?? '',
        responseBody: map['response_body'] as String? ?? '',
      );
}
