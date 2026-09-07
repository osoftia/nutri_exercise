import 'package:flutter/foundation.dart';

import '../data/daily_entry_repository.dart';
import '../models/daily_entry.dart';

/// Owns the calendar-history entries and notifies listeners on changes.
///
/// Loads every stored [DailyEntry] from the repository and exposes them to the
/// calendar view, including save (upsert) and delete operations for the editor.
class DailyEntryController extends ChangeNotifier {
  DailyEntryController({required DailyEntryRepository repository})
    : _repository = repository;

  final DailyEntryRepository _repository;

  List<DailyEntry> _entries = [];
  bool _isLoading = false;
  String? _error;

  /// Every stored entry.
  List<DailyEntry> get entries => List.unmodifiable(_entries);

  /// The set of dates (YYYY-MM-DD) that have at least one entry.
  Set<String> get datesWithEntries =>
      _entries.map((entry) => entry.date).toSet();

  bool get isLoading => _isLoading;

  String? get error => _error;

  /// Loads every entry from the repository and notifies.
  Future<void> loadAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _entries = await _repository.getAll();
    } catch (_) {
      _error = 'Could not load your history.';
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Upserts [entry] and refreshes. Returns `false` on failure.
  Future<bool> save(DailyEntry entry) async {
    try {
      await _repository.save(entry);
    } catch (_) {
      _error = 'Could not save the entry.';
      notifyListeners();
      return false;
    }
    await loadAll();
    return true;
  }

  /// Deletes the entry for [date] and refreshes. Returns `false` on failure.
  Future<bool> delete(String date) async {
    try {
      await _repository.delete(date);
    } catch (_) {
      _error = 'Could not delete the entry.';
      notifyListeners();
      return false;
    }
    await loadAll();
    return true;
  }
}