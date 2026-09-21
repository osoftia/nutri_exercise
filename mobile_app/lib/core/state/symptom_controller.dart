import 'package:flutter/foundation.dart';

import '../data/symptom_repository.dart';
import '../models/symptom_log.dart';

/// Owns the current day's symptom severities and persists every change.
class SymptomController extends ChangeNotifier {
  /// Creates a controller for [date] (defaults to today).
  SymptomController({required this.repository, DateTime? date})
    : _date = date ?? DateTime.now();

  /// Persistence backing the controller.
  final SymptomRepository repository;

  final Map<SymptomType, int> _levels = {
    for (final type in SymptomType.values) type: SymptomLog.minLevel,
  };
  DateTime _date;
  bool _loaded = false;

  /// The day currently being tracked.
  DateTime get date => _date;

  /// Whether [load] has completed at least once.
  bool get isLoaded => _loaded;

  /// The severity recorded for [type] (`0..3`).
  int levelOf(SymptomType type) => _levels[type] ?? SymptomLog.minLevel;

  /// Whether any symptom has a non-zero severity today.
  bool get hasAnyLogged => _levels.values.any((level) => level > 0);

  /// The symptoms logged with a non-zero severity, in enum order.
  List<SymptomType> get loggedTypes =>
      SymptomType.values.where((type) => levelOf(type) > 0).toList();

  /// Loads the readings for [date] (or the current day when omitted).
  Future<void> load({DateTime? date}) async {
    if (date != null) _date = date;
    final logs = await repository.getForDate(SymptomLog.dateKey(_date));
    for (final type in SymptomType.values) {
      _levels[type] = SymptomLog.minLevel;
    }
    for (final log in logs) {
      _levels[log.symptom] = log.level.clamp(
        SymptomLog.minLevel,
        SymptomLog.maxLevel,
      );
    }
    _loaded = true;
    notifyListeners();
  }

  /// Sets [type]'s severity (clamped to `0..3`) and persists it.
  Future<void> setLevel(SymptomType type, int level) async {
    final clamped = level.clamp(SymptomLog.minLevel, SymptomLog.maxLevel);
    _levels[type] = clamped;
    notifyListeners();
    await repository.save(
      SymptomLog(date: SymptomLog.dateKey(_date), symptom: type, level: clamped),
    );
  }

  /// Advances [type] to its next severity, wrapping `3 -> 0`.
  Future<int> cycle(SymptomType type) async {
    final next =
        (levelOf(type) + 1) % (SymptomLog.maxLevel - SymptomLog.minLevel + 1);
    await setLevel(type, next);
    return next;
  }
}
