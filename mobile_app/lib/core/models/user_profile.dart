/// Fitness goals available to the user profile.
enum FitnessGoal { muscleGain, fatLoss, maintain, endurance }

extension FitnessGoalLabel on FitnessGoal {
  /// Human-readable label shown in the Profile form/dropdown.
  String get label => switch (this) {
    FitnessGoal.muscleGain => 'Muscle Gain',
    FitnessGoal.fatLoss => 'Fat Loss',
    FitnessGoal.maintain => 'Maintain',
    FitnessGoal.endurance => 'Endurance',
  };
}

/// Personal details of the app user, persisted locally in a single SQLite row.
class UserProfile {
  const UserProfile({
    required this.name,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.goal,
  });

  /// Blank profile used to pre-fill a fresh form (nothing saved yet).
  ///
  /// Defaults to a sensible 60 kg / 1.70 m so BMI calculations and the avatar
  /// baseline are valid before the user saves their own profile.
  static const UserProfile empty = UserProfile(
    name: '',
    age: 0,
    weightKg: 60,
    heightCm: 170,
    goal: FitnessGoal.muscleGain,
  );

  final String name;
  final int age;
  final double weightKg;
  final double heightCm;
  final FitnessGoal goal;

  /// Serializes to a SQLite row map (single row, `id = 1`).
  Map<String, Object?> toMap() => {
    'id': 1,
    'name': name,
    'age': age,
    'weight_kg': weightKg,
    'height_cm': heightCm,
    'goal': goal.name,
  };

  /// Restores a [UserProfile] from a SQLite row map produced by [toMap].
  static UserProfile fromMap(Map<String, Object?> map) => UserProfile(
    name: map['name'] as String,
    age: map['age'] as int,
    weightKg: (map['weight_kg'] as num).toDouble(),
    heightCm: (map['height_cm'] as num).toDouble(),
    goal: FitnessGoal.values.firstWhere((g) => g.name == map['goal']),
  );
}