import '../models/projection_models.dart';

/// Contract for reading and persisting the long-term body projection plan.
abstract interface class ProjectionRepository {
  /// Returns the stored plan (seeding a generated one when none exists).
  Future<ProjectionPlan> loadPlan();

  /// Persists the given plan.
  Future<void> savePlan(ProjectionPlan plan);
}
