/// A single day's energy balance within the last-7-days window.
class WeeklyStat {
  const WeeklyStat({
    required this.date,
    this.consumed = 0,
    this.burned = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
  });

  final DateTime date;

  /// Calories consumed (from logged nutrition).
  final int consumed;

  /// Calories burned (estimated from logged exercises).
  final int burned;

  /// Grams of protein consumed on the day.
  final int protein;

  /// Grams of carbohydrates consumed on the day.
  final int carbs;

  /// Grams of fat consumed on the day.
  final int fat;

  /// Energy balance: positive = surplus, negative = deficit.
  int get balance => consumed - burned;
}