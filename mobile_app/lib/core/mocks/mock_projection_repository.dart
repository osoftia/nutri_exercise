import '../data/projection_repository.dart';
import '../models/projection_models.dart';
import '../models/user_profile.dart';

/// In-memory test double seeded with a deterministic generated plan.
class MockProjectionRepository implements ProjectionRepository {
  MockProjectionRepository({
    ProjectionPlan? plan,
    double startWeightKg = 70,
    FitnessGoal goal = FitnessGoal.muscleGain,
  }) : _plan = plan ??
            generateProjectionPlan(startWeightKg: startWeightKg, goal: goal);

  ProjectionPlan _plan;

  @override
  Future<ProjectionPlan> loadPlan() async => _plan;

  @override
  Future<void> savePlan(ProjectionPlan plan) async {
    _plan = plan;
  }
}
