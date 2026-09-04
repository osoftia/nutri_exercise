import 'package:flutter/foundation.dart';

import '../data/daily_log_repository.dart';
import '../models/daily_log.dart';
import '../models/log_parse_response.dart';
import '../services/log_parse_service.dart';

/// Owns the current day's free-text summary and notifies listeners on changes.
///
/// When a [LogParseService] is provided, [submit] also sends the text to the
/// backend AI parser (`POST /api/log/parse`) so the UI can surface the parsed
/// calories/macros after a successful save.
class DailyLogController extends ChangeNotifier {
  DailyLogController({
    required DailyLogRepository repository,
    LogParseService? parseService,
  }) : _repository = repository,
       _parseService = parseService;

  final DailyLogRepository _repository;
  final LogParseService? _parseService;

  String _date = DailyLog.dateKey(DateTime.now());
  String _text = '';
  bool _isLoading = false;
  bool _isParsing = false;
  String? _errorMessage;
  LogParseResponse? _parseResult;
  String? _parseError;

  /// The date key currently being edited.
  String get date => _date;

  /// The current summary text (empty when nothing saved yet).
  String get text => _text;

  bool get isLoading => _isLoading;

  /// Whether a backend parse request is in flight.
  bool get isParsing => _isParsing;

  String? get errorMessage => _errorMessage;

  /// The structured result of the last successful parse, or `null`.
  LogParseResponse? get parseResult => _parseResult;

  /// A human-readable parse failure message, or `null`.
  String? get parseError => _parseError;

  /// Loads the summary for [date] (defaults to today) and notifies.
  Future<void> load({String? date}) async {
    _date = date ?? DailyLog.dateKey(DateTime.now());
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final log = await _repository.getByDate(_date);
      _text = log?.text ?? '';
    } catch (_) {
      _errorMessage = 'Could not load your summary.';
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Persists a trimmed summary for the current date.
  ///
  /// Returns `false` when [text] is empty (and nothing is saved), otherwise
  /// `true` after a successful save.
  Future<bool> save(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    try {
      await _repository.save(DailyLog(date: _date, text: trimmed));
    } catch (_) {
      _errorMessage = 'Could not save your summary.';
      notifyListeners();
      return false;
    }
    _text = trimmed;
    notifyListeners();
    return true;
  }

  /// Persists the summary and, when a parser is configured, sends it to the
  /// backend for AI analysis.
  ///
  /// Returns `false` for empty input (nothing saved). On parse failure the
  /// summary is still saved locally and [parseError] is populated so the UI can
  /// surface a non-blocking warning.
  Future<bool> submit(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;

    _isParsing = true;
    _parseError = null;
    _parseResult = null;
    notifyListeners();

    final saved = await save(trimmed);

    final parseService = _parseService;
    if (parseService != null) {
      try {
        _parseResult = await parseService.parse(trimmed);
      } catch (_) {
        _parseError =
            'Could not reach the AI analysis service. Your log was saved.';
      }
    }

    _isParsing = false;
    notifyListeners();
    return saved;
  }
}
