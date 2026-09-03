/// A single free-text daily summary ("what I ate and trained today").
class DailyLog {
  const DailyLog({required this.date, required this.text});

  /// The calendar date this entry belongs to, in `YYYY-MM-DD` form.
  final String date;

  /// The user's free-text summary.
  final String text;

  /// Formats a [DateTime] into the `YYYY-MM-DD` key used for persistence.
  static String dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Serializes to a SQLite row map (mirrors [UserProfile.toMap]).
  Map<String, Object?> toMap() => {'date': date, 'text': text};

  /// Restores a [DailyLog] from a SQLite row map produced by [toMap].
  static DailyLog fromMap(Map<String, Object?> map) => DailyLog(
    date: map['date'] as String,
    text: map['text'] as String,
  );
}
