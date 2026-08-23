import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/models/projection_models.dart';
import 'package:nutri_mobile_app/core/models/user_profile.dart';

void main() {
  group('generateProjectionPlan', () {
    test('produces baseline plus 1/3/6 month milestones', () {
      final plan = generateProjectionPlan(
        startWeightKg: 70,
        goal: FitnessGoal.muscleGain,
      );

      expect(plan.milestones.map((m) => m.month), [0, 1, 3, 6]);
      expect(plan.startWeightKg, 70);
    });

    test('baseline milestone is neutral', () {
      final plan = generateProjectionPlan(
        startWeightKg: 70,
        goal: FitnessGoal.muscleGain,
      );
      final baseline = plan.milestoneFor(0)!;
      expect(baseline.shoulderFactor, 0.5);
      expect(baseline.waistFactor, 0.5);
      expect(baseline.weightKg, 70);
    });

    test('muscle gain broadens shoulders to the max at 6 months', () {
      final plan = generateProjectionPlan(
        startWeightKg: 70,
        goal: FitnessGoal.muscleGain,
      );
      final month6 = plan.milestoneFor(6)!;

      expect(month6.shoulderFactor, 1.0);
      expect(month6.waistFactor, lessThan(0.5));
      expect(month6.weightKg, closeTo(76.0, 0.0001));
      expect(month6.shoulderFactor, greaterThan(plan.milestoneFor(3)!.shoulderFactor));
    });

    test('fat loss slims the waist to the min at 6 months', () {
      final plan = generateProjectionPlan(
        startWeightKg: 80,
        goal: FitnessGoal.fatLoss,
      );
      final month6 = plan.milestoneFor(6)!;

      expect(month6.waistFactor, 0.25);
      expect(month6.waistFactor, lessThan(plan.milestoneFor(3)!.waistFactor));
      expect(month6.weightKg, closeTo(73.0, 0.0001));
    });

    test('milestoneFor returns null for unknown months', () {
      final plan = generateProjectionPlan(
        startWeightKg: 70,
        goal: FitnessGoal.maintain,
      );
      expect(plan.milestoneFor(2), isNull);
    });
  });
}
