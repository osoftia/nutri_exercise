import 'user_profile.dart';

/// A single milestone in a long-term body projection plan.
class ProjectionMilestone {
  const ProjectionMilestone({
    required this.month,
    required this.weightKg,
    required this.shoulderFactor,
    required this.waistFactor,
    required this.focus,
  });

  /// Months from now: `0` (current baseline), `1`, `3` or `6`.
  final int month;
  final double weightKg;

  /// `0..1` — `0` narrow, `0.5` baseline, `1` broad shoulders.
  final double shoulderFactor;

  /// `0..1` — `0` slim, `0.5` baseline, `1` wide waist.
  final double waistFactor;

  /// Human-readable training phase.
  final String focus;

  Map<String, Object?> toMap({required int planId}) => {
    'plan_id': planId,
    'month': month,
    'weight_kg': weightKg,
    'shoulder_factor': shoulderFactor,
    'waist_factor': waistFactor,
    'focus': focus,
  };

  static ProjectionMilestone fromMap(Map<String, Object?> map) =>
      ProjectionMilestone(
        month: map['month'] as int,
        weightKg: (map['weight_kg'] as num).toDouble(),
        shoulderFactor: (map['shoulder_factor'] as num).toDouble(),
        waistFactor: (map['waist_factor'] as num).toDouble(),
        focus: map['focus'] as String,
      );
}

/// A 6-month recommended routine plan: a baseline plus 1/3/6-month milestones.
class ProjectionPlan {
  const ProjectionPlan({
    required this.startWeightKg,
    required this.goal,
    required this.milestones,
  });

  final double startWeightKg;
  final FitnessGoal goal;
  final List<ProjectionMilestone> milestones;

  ProjectionMilestone? milestoneFor(int month) {
    for (final m in milestones) {
      if (m.month == month) return m;
    }
    return null;
  }
}

/// Pure projection engine: turns (start weight, goal) into milestone rows.
ProjectionPlan generateProjectionPlan({
  required double startWeightKg,
  required FitnessGoal goal,
}) {
  final shoulders = <double>[];
  final waists = <double>[];
  final deltas = <double>[];
  final focuses = <String>[];

  switch (goal) {
    case FitnessGoal.muscleGain:
      shoulders.addAll([0.60, 0.75, 1.00]);
      waists.addAll([0.47, 0.44, 0.40]);
      deltas.addAll([1.5, 3.5, 6.0]);
      focuses.addAll(['Foundation', 'Hypertrophy', 'Peak Build']);
    case FitnessGoal.fatLoss:
      shoulders.addAll([0.50, 0.52, 0.55]);
      waists.addAll([0.42, 0.34, 0.25]);
      deltas.addAll([-1.5, -4.0, -7.0]);
      focuses.addAll(['Cut', 'Leaning', 'Shred']);
    case FitnessGoal.maintain:
      shoulders.addAll([0.50, 0.50, 0.50]);
      waists.addAll([0.50, 0.49, 0.48]);
      deltas.addAll([0.0, 0.0, 0.0]);
      focuses.addAll(['Maintain', 'Maintain', 'Maintain']);
    case FitnessGoal.endurance:
      shoulders.addAll([0.52, 0.55, 0.58]);
      waists.addAll([0.48, 0.46, 0.44]);
      deltas.addAll([-0.5, -1.5, -3.0]);
      focuses.addAll(['Base', 'Stamina', 'Conditioning']);
  }

  const months = [1, 3, 6];
  final milestones = <ProjectionMilestone>[
    ProjectionMilestone(
      month: 0,
      weightKg: startWeightKg,
      shoulderFactor: 0.5,
      waistFactor: 0.5,
      focus: 'Current',
    ),
    for (var i = 0; i < months.length; i++)
      ProjectionMilestone(
        month: months[i],
        weightKg: startWeightKg + deltas[i],
        shoulderFactor: shoulders[i],
        waistFactor: waists[i],
        focus: focuses[i],
      ),
  ];

  return ProjectionPlan(
    startWeightKg: startWeightKg,
    goal: goal,
    milestones: milestones,
  );
}
