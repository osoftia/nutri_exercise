import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_projection_repository.dart';
import 'package:nutri_mobile_app/core/models/projection_models.dart';
import 'package:nutri_mobile_app/core/models/user_profile.dart';

void main() {
  group('MockProjectionRepository', () {
    test('loadPlan returns a generated muscle-gain plan by default', () async {
      final repo = MockProjectionRepository();
      final plan = await repo.loadPlan();

      expect(plan.milestones.map((m) => m.month), [0, 1, 3, 6]);
      expect(plan.goal, FitnessGoal.muscleGain);
    });

    test('savePlan persists a custom plan for subsequent loads', () async {
      final repo = MockProjectionRepository();
      final plan = generateProjectionPlan(
        startWeightKg: 80,
        goal: FitnessGoal.fatLoss,
      );
      await repo.savePlan(plan);

      final reloaded = await repo.loadPlan();
      expect(reloaded.startWeightKg, 80);
      expect(reloaded.goal, FitnessGoal.fatLoss);
    });
  });
}
