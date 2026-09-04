import 'package:flutter/foundation.dart';

import '../models/log_parse_response.dart';

/// Accumulates today's nutrition totals from AI-parsed daily logs and notifies
/// listeners whenever a new entry is added or the totals reset.
class DailyNutritionState extends ChangeNotifier {
  int _calories = 0;
  int _protein = 0;
  int _carbs = 0;
  int _fat = 0;

  int get calories => _calories;
  int get protein => _protein;
  int get carbs => _carbs;
  int get fat => _fat;

  /// Adds a parsed meal to today's totals (null macros contribute zero).
  void add(LogParseResponse result) {
    _calories += result.calories;
    _protein += result.protein ?? 0;
    _carbs += result.carbs ?? 0;
    _fat += result.fat ?? 0;
    notifyListeners();
  }

  /// Clears every total (e.g. on a new day).
  void reset() {
    _calories = 0;
    _protein = 0;
    _carbs = 0;
    _fat = 0;
    notifyListeners();
  }
}
