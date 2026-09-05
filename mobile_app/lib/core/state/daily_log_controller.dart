import 'package:flutter/foundation.dart';

import '../data/daily_log_repository.dart';
import '../models/daily_log.dart';
import '../models/log_parse_response.dart';
import '../services/smart_logger.dart';

/// Owns the current day's free-text summary and notifies listeners on changes.
///
/// When a [SmartLogger] is provided, [submit] resolves the text through the
/// cache-first logger (local SQLite cache → backend AI parser) and persists the
/// parsed result alongside the raw text.
class DailyLogController extends ChangeNotifier {
  DailyLogController({
    required DailyLogRepository repository,
    SmartLogger? smartLogger,
  }) : _repository = repository,
       _smartLogger = smartLogger;

  final DailyLogRepository _repository;
  final SmartLogger? _smartLogger;

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

  /// Whether a parse request is in flight.
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

  /// Returns the most recent distinct raw texts for autocomplete suggestions.
  Future<List<String>> loadSuggestions() => _repository.getAllTexts();

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

  /// Persists the summary and, when a [SmartLogger] is configured, resolves it
  /// through the cache-first logger (local cache → backend AI parser).
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

    final smartLogger = _smartLogger;
    if (smartLogger != null) {
      try {
        final parsed = await smartLogger.parse(trimmed);
        _parseResult = parsed;
        await _repository.saveWithParse(
          DailyLog(date: _date, text: trimmed),
          parsed,
        );
        _text = trimmed;
      } catch (_) {
        _parseError =
            'Could not reach the AI analysis service. Your log was saved.';
        await save(trimmed);
      }
    } else {
      await save(trimmed);
    }

    _isParsing = false;
    notifyListeners();
    return _parseResult != null || _smartLogger == null;
  }
}