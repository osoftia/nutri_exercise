import '../data/daily_log_repository.dart';
import '../models/log_parse_response.dart';
import 'log_parse_service.dart';

/// Cache-first log parser.
///
/// Checks the local SQLite cache for an exact text match before calling the
/// backend AI parser, so repeated entries are resolved instantly without
/// burning an AI call.
class SmartLogger {
  SmartLogger({required this.repository, required this.parseService});

  final DailyLogRepository repository;
  final LogParseService parseService;

  /// Returns the cached [LogParseResponse] for an exact [text] match, or
  /// `null` when the cache has no entry for that text.
  Future<LogParseResponse?> cached(String text) =>
      repository.getByExactText(text);

  /// Parses [text] using the cache-first strategy: an exact match returns the
  /// cached result; otherwise the backend AI parser is called.
  Future<LogParseResponse> parse(String text) async {
    final cached = await repository.getByExactText(text);
    if (cached != null) return cached;
    return parseService.parse(text);
  }
}