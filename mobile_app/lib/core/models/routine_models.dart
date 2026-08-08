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
      sets: json['sets'] as int,
      reps: json['reps'] as String,
      restSeconds: json['restSeconds'] as int,
    );
  }
}

class WorkoutDay {
  const WorkoutDay({
    required this.id,
    required this.weekday,
    required this.focus,
    required this.exercises,
  });

  final int id;
  final String weekday;
  final String focus;
  final List<Exercise> exercises;

  factory WorkoutDay.fromJson(Map<String, dynamic> json) {
    return WorkoutDay(
      id: json['id'] as int,
      weekday: json['weekday'] as String,
      focus: json['focus'] as String,
      exercises:
          (json['exercises'] as List<dynamic>)
              .map(
                (exercise) =>
                    Exercise.fromJson(exercise as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}
