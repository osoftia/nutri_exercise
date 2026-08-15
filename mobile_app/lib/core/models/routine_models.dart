import 'diet_models.dart';

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.sets,
    required this.reps,
    required this.restSeconds,
  });

  final int id;
  final String name;
  final String muscleGroup;
  final int sets;
  final String reps;
  final int restSeconds;

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as int,
      name: json['name'] as String,
      muscleGroup: json['muscleGroup'] as String,
      sets: (json['series'] ?? json['sets']) as int,
      reps: json['reps'] as String,
      restSeconds: json['restSeconds'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'muscleGroup': muscleGroup,
      'sets': sets,
      'reps': reps,
      'restSeconds': restSeconds,
    };
  }
}

class WorkoutDay {
  const WorkoutDay({
    required this.id,
    required this.weekday,
    required this.focus,
    required this.exercises,
    this.nutrition,
  });

  final int id;
  final String weekday;
  final String focus;
  final List<Exercise> exercises;
  final NutritionInfo? nutrition;

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    return WorkoutDay(
      id: json['id'] as int,
      weekday: (json['dayOfWeek'] ?? json['weekday']) as String,
      focus: (json['name'] ?? json['focus']) as String,
      exercises: (json['exercises'] as List<dynamic>)
          .map(
            (exercise) => Exercise.fromJson(exercise as Map<String, dynamic>),
          )
          .toList(),
      nutrition: json['nutrition'] == null
          ? null
          : NutritionInfo.fromJson(json['nutrition'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weekday': weekday,
      'focus': focus,
      'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
      if (nutrition != null) 'nutrition': nutrition!.toJson(),
    };
  }
}

class NutritionInfo {
  const NutritionInfo({
    required this.totalCalories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.meals,
  });

  final int totalCalories;
  final int protein;
  final int carbs;
  final int fat;
  final List<Meal> meals;

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      totalCalories: json['totalCalories'] as int,
      protein: json['protein'] as int,
      carbs: json['carbs'] as int,
      fat: json['fat'] as int,
      meals: (json['meals'] as List<dynamic>)
          .map((meal) => Meal.fromJson(meal as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCalories': totalCalories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'meals': meals.map((meal) => meal.toJson()).toList(),
    };
  }
}
