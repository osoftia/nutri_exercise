import 'package:flutter/material.dart';

enum FitnessGoal {
  loseWeight,
  buildMuscle,
  maintain,
  endurance;

  String get label => switch (this) {
    loseWeight => 'Lose Weight',
    buildMuscle => 'Build Muscle',
    maintain => 'Maintain',
    endurance => 'Endurance',
  };

  String get apiValue => switch (this) {
    loseWeight => 'lose_weight',
    buildMuscle => 'build_muscle',
    maintain => 'maintain',
    endurance => 'endurance',
  };

  IconData get icon => switch (this) {
    loseWeight => Icons.monitor_weight_outlined,
    buildMuscle => Icons.fitness_center,
    maintain => Icons.balance_outlined,
    endurance => Icons.directions_run,
  };
}

enum FitnessLevel {
  beginner,
  intermediate,
  advanced;

  String get label => switch (this) {
    beginner => 'Beginner',
    intermediate => 'Intermediate',
    advanced => 'Advanced',
  };

  String get apiValue => name;

  IconData get icon => switch (this) {
    beginner => Icons.looks_one,
    intermediate => Icons.looks_two,
    advanced => Icons.looks_3,
  };

  String get description => switch (this) {
    beginner => 'New to training or returning after a long break.',
    intermediate => 'Consistent training for 6+ months.',
    advanced => '2+ years of structured programming.',
  };
}

class WizardData {
  const WizardData({
    required this.age,
    required this.goal,
    required this.fitnessLevel,
    required this.availableDays,
  });

  final int age;
  final FitnessGoal goal;
  final FitnessLevel fitnessLevel;
  final int availableDays;

  /// Builds the preference string consumed by
  /// `RoutineRepository.generateRoutine(String)`.
  ///
  /// Example outputs:
  ///   "Age: 28, Goal: build_muscle, Level: intermediate, Days: 4"
  ///   "Age: 35, Goal: lose_weight, Level: beginner, Days: 3"
  String toPreferencesString() {
    return 'Age: $age, '
        'Goal: ${goal.apiValue}, '
        'Level: ${fitnessLevel.apiValue}, '
        'Days: $availableDays';
  }

  /// Immutable copy-with for step updates.
  WizardData copyWith({
    int? age,
    FitnessGoal? goal,
    FitnessLevel? fitnessLevel,
    int? availableDays,
  }) {
    return WizardData(
      age: age ?? this.age,
      goal: goal ?? this.goal,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      availableDays: availableDays ?? this.availableDays,
    );
  }
}
