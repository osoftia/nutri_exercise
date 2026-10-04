/// A single food logged for the current day, with the detail the blueprint
/// popup needs (portion, calories, macros and wall-clock time).
class LoggedFood {
  /// Creates a logged food entry.
  const LoggedFood({
    required this.name,
    required this.portion,
    required this.calories,
    this.proteinG = 0,
    this.carbsG = 0,
    this.fatG = 0,
    this.saturatedFatG,
    this.sugarsG,
    this.fiberG,
    this.glycemicIndex,
    this.purinesMg,
    this.sodiumMg,
    required this.time,
  });

  /// Display name of the food.
  final String name;

  /// Human-readable portion (e.g. `200 g`, `1 bowl`).
  final String portion;

  /// Energy in kilocalories.
  final int calories;

  /// Protein in grams.
  final int proteinG;

  /// Carbohydrates in grams.
  final int carbsG;

  /// Fat in grams.
  final int fatG;

  /// Optional condition-relevant nutrition estimates for the logged portion.
  final double? saturatedFatG;
  final double? sugarsG;
  final double? fiberG;
  final double? glycemicIndex;
  final double? purinesMg;
  final double? sodiumMg;

  /// Wall-clock time the food was logged (`HH:mm`).
  final String time;

  /// Returns a copy with the provided fields replaced.
  LoggedFood copyWith({
    String? name,
    String? portion,
    int? calories,
    int? proteinG,
    int? carbsG,
    int? fatG,
    double? saturatedFatG,
    double? sugarsG,
    double? fiberG,
    double? glycemicIndex,
    double? purinesMg,
    double? sodiumMg,
    String? time,
  }) {
    return LoggedFood(
      name: name ?? this.name,
      portion: portion ?? this.portion,
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      saturatedFatG: saturatedFatG ?? this.saturatedFatG,
      sugarsG: sugarsG ?? this.sugarsG,
      fiberG: fiberG ?? this.fiberG,
      glycemicIndex: glycemicIndex ?? this.glycemicIndex,
      purinesMg: purinesMg ?? this.purinesMg,
      sodiumMg: sodiumMg ?? this.sodiumMg,
      time: time ?? this.time,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is LoggedFood &&
      other.name == name &&
      other.portion == portion &&
      other.calories == calories &&
      other.proteinG == proteinG &&
      other.carbsG == carbsG &&
      other.fatG == fatG &&
      other.saturatedFatG == saturatedFatG &&
      other.sugarsG == sugarsG &&
      other.fiberG == fiberG &&
      other.glycemicIndex == glycemicIndex &&
      other.purinesMg == purinesMg &&
      other.sodiumMg == sodiumMg &&
      other.time == time;

  @override
  int get hashCode => Object.hash(
        name,
        portion,
        calories,
        proteinG,
        carbsG,
        fatG,
        saturatedFatG,
        sugarsG,
        fiberG,
        glycemicIndex,
        purinesMg,
        sodiumMg,
        time,
      );

  @override
  String toString() => 'LoggedFood($name, $portion, $calories kcal)';
}

/// Immutable snapshot of a day's food log plus its derived totals.
class DailyFoodLog {
  /// Creates a food log for [date] containing [entries].
  const DailyFoodLog({this.date = '', this.entries = const []});

  /// The calendar date this log belongs to (`YYYY-MM-DD`), if known.
  final String date;

  /// The foods logged for the day.
  final List<LoggedFood> entries;

  /// Whether nothing was logged.
  bool get isEmpty => entries.isEmpty;

  /// Summed calories of every entry.
  int get totalCalories => _sum((food) => food.calories);

  /// Summed protein in grams.
  int get totalProteinG => _sum((food) => food.proteinG);

  /// Summed carbohydrates in grams.
  int get totalCarbsG => _sum((food) => food.carbsG);

  /// Summed fat in grams.
  int get totalFatG => _sum((food) => food.fatG);

  int _sum(int Function(LoggedFood food) pick) {
    var total = 0;
    for (final food in entries) {
      total += pick(food);
    }
    return total;
  }

  /// Returns a copy with the provided fields replaced.
  DailyFoodLog copyWith({String? date, List<LoggedFood>? entries}) =>
      DailyFoodLog(date: date ?? this.date, entries: entries ?? this.entries);

  @override
  bool operator ==(Object other) =>
      other is DailyFoodLog &&
      other.date == date &&
      _listEquals(other.entries, entries);

  @override
  int get hashCode => Object.hash(date, Object.hashAll(entries));

  @override
  String toString() => 'DailyFoodLog($date, ${entries.length} entries)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
