/// A single day's energy balance within the last-7-days window.
class WeeklyStat {
  const WeeklyStat({
    required this.date,
    this.consumed = 0,
    this.burned = 0,
  });

  final DateTime date;

  /// Calories consumed (from logged nutrition).
  final int consumed;

  /// Calories burned (estimated from logged exercises).
  final int burned;

  /// Energy balance: positive = surplus, negative = deficit.
  int get balance => consumed - burned;
}