enum MealType { breakfast, lunch, dinner, snack }

class Meal {
  const Meal({
    required this.id,
    required this.name,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final int id;
  final String name;
  final MealType mealType;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'] as int,
      name: json['name'] as String,
      mealType: MealType.values.byName(json['mealType'] as String),
      calories: json['calories'] as int,
      protein: json['protein'] as int,
      carbs: json['carbs'] as int,
      fat: json['fat'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mealType': mealType.name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}

class DailyMenu {
  const DailyMenu({
    required this.id,
    required this.date,
    required this.totalCalories,
    required this.meals,
  });

  final int id;
  final String date;
  final int totalCalories;
  final List<Meal> meals;

  factory DailyMenu.fromJson(Map<String, dynamic> json) {
    return DailyMenu(
      id: json['id'] as int,
      date: json['date'] as String,
      totalCalories: json['totalCalories'] as int,
      meals: (json['meals'] as List<dynamic>)
          .map((meal) => Meal.fromJson(meal as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'totalCalories': totalCalories,
      'meals': meals.map((meal) => meal.toJson()).toList(),
    };
  }
}
