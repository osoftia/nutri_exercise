/// The kinds of daily symptoms the tracker records.
///
/// Kept in the model layer (alongside [SymptomLog]) so dictionaries can
/// localize them without the UI leaking symptom strings into hardcoded maps.
enum SymptomType {
  pain,
  discomfort,
  energy,
  stress;

  /// Parses a persisted symptom id, returning `null` for unknown values.
  static SymptomType? fromId(String? id) {
    if (id == null) return null;
    for (final type in SymptomType.values) {
      if (type.name == id) return type;
    }
    return null;
  }
}

/// A single severity reading for one [SymptomType] on a given day.
///
/// [level] is a `0..3` severity (none / mild / moderate / severe). Level `0`
/// means "not logged", so a day with no rows is equivalent to all-zero levels.
class SymptomLog {
  const SymptomLog({
    required this.date,
    required this.symptom,
    required this.level,
  });

  /// Lowest severity (not logged).
  static const int minLevel = 0;

  /// Highest severity.
  static const int maxLevel = 3;

  /// The calendar date this reading belongs to, in `YYYY-MM-DD` form.
  final String date;

  /// The symptom being tracked.
  final SymptomType symptom;

  /// Severity in `[minLevel, maxLevel]`.
  final int level;

  /// Formats a [DateTime] into the `YYYY-MM-DD` key used for persistence.
  static String dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Serializes to a SQLite row map.
  Map<String, Object?> toMap() => {
    'date': date,
    'symptom': symptom.name,
    'level': level,
  };

  /// Restores a [SymptomLog] from a SQLite row map produced by [toMap].
  ///
  /// Unknown symptom ids fall back to [SymptomType.pain] so a legacy or corrupt
  /// row can never crash the tracker.
  static SymptomLog fromMap(Map<String, Object?> map) => SymptomLog(
    date: map['date'] as String,
    symptom: SymptomType.fromId(map['symptom'] as String?) ?? SymptomType.pain,
    level: ((map['level'] as int?) ?? minLevel).clamp(minLevel, maxLevel),
  );
}
