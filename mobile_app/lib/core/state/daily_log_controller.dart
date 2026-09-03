import 'package:flutter/foundation.dart';

import '../data/daily_log_repository.dart';
import '../models/daily_log.dart';

/// Owns the current day's free-text summary and notifies listeners on changes.
class DailyLogController extends ChangeNotifier {
  DailyLogController({required DailyLogRepository repository})
    : _repository = repository;

  final DailyLogRepository _repository;

  String _date = DailyLog.dateKey(DateTime.now());
  String _text = '';
  bool _isLoading = false;
  String? _errorMessage;

  /// The date key currently being edited.
  String get date => _date;

  /// The current summary text (empty when nothing saved yet).
  String get text => _text;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

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
}
