import '../database/database_helper.dart';
import '../models/projection_models.dart';
import '../models/user_profile.dart';
import 'projection_repository.dart';

/// SQLite-backed [ProjectionRepository]. Seeds a generated plan when the
/// database has none yet.
class LocalProjectionRepository implements ProjectionRepository {
  LocalProjectionRepository({
    DatabaseHelper? databaseHelper,
    this.startWeightKg = 70,
    this.goal = FitnessGoal.muscleGain,
  }) : _databaseHelper = databaseHelper ?? DatabaseHelper();

  final DatabaseHelper _databaseHelper;
  final double startWeightKg;
  final FitnessGoal goal;
  bool _seeded = false;

  @override
  Future<ProjectionPlan> loadPlan() async {
    await _seedIfNeeded();
    final planRow = await _databaseHelper.getProjectionPlan();
    final milestones = await _databaseHelper.getProjectionMilestones();
    return ProjectionPlan(
      startWeightKg: (planRow!['start_weight_kg'] as num).toDouble(),
      goal: FitnessGoal.values.firstWhere((g) => g.name == planRow['goal']),
      milestones: milestones.map(ProjectionMilestone.fromMap).toList(),
    );
  }

  @override
  Future<void> savePlan(ProjectionPlan plan) async {
    await _databaseHelper.saveProjectionPlan(plan);
    _seeded = true;
  }

  Future<void> _seedIfNeeded() async {
    if (_seeded) return;
    final existing = await _databaseHelper.getProjectionPlan();
    if (existing == null) {
      await savePlan(
        generateProjectionPlan(startWeightKg: startWeightKg, goal: goal),
      );
    }
    _seeded = true;
  }
}
