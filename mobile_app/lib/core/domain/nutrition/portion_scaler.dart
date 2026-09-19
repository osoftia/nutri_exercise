import '../../models/food_entry.dart';
import '../body_projection/nutrition_log.dart';

/// Pure portion math used by the quick-add gram dialog.
///
/// Preset quick-add foods are authored per [baseGrams] (100 g); a user-entered
/// gram amount proportionally scales their calories and macros before they are
/// logged. Scaling the calories is what drives the Tamagotchi stomach mass, so
/// the avatar reacts to the actual portion rather than the preset.
abstract final class PortionScaler {
  /// Reference weight every preset is authored against.
  static const double baseGrams = 100;

  /// Scales [base] to [grams], rounding each nutrient to the nearest whole unit.
  static FoodEntry scaleFood(FoodEntry base, double grams) {
    final factor = _factor(grams);
    return FoodEntry(
      name: base.name,
      calories: _scaleInt(base.calories, factor),
      proteinG: _scaleInt(base.proteinG, factor),
      carbsG: _scaleInt(base.carbsG, factor),
      fatG: _scaleInt(base.fatG, factor),
    );
  }

  /// Scales [base] to [grams], preserving its macros and annotating the portion.
  static LoggedFood scaleLogged(
    LoggedFood base,
    double grams, {
    String? time,
  }) {
    final factor = _factor(grams);
    return LoggedFood(
      name: base.name,
      portion: '${_formatGrams(grams)} g',
      calories: _scaleInt(base.calories, factor),
      proteinG: _scaleInt(base.proteinG, factor),
      carbsG: _scaleInt(base.carbsG, factor),
      fatG: _scaleInt(base.fatG, factor),
      time: time ?? base.time,
    );
  }

  static double _factor(double grams) {
    if (!grams.isFinite || grams <= 0) return 0;
    return grams / baseGrams;
  }

  static int _scaleInt(int value, double factor) => (value * factor).round();

  static String _formatGrams(double grams) {
    if (grams == grams.roundToDouble()) return grams.toInt().toString();
    return grams.toStringAsFixed(1);
  }
}
