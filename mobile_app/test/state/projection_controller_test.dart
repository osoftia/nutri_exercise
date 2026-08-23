import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_projection_repository.dart';
import 'package:nutri_mobile_app/core/models/user_profile.dart';
import 'package:nutri_mobile_app/core/state/projection_controller.dart';

void main() {
  late ProjectionController controller;

  setUp(() {
    controller = ProjectionController(
      repository: MockProjectionRepository(),
    );
  });

  group('ProjectionController', () {
    test('load populates the plan and starts on the baseline', () async {
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.load();

      expect(controller.selectedMonth, 0);
      expect(controller.shoulderFactor, 0.5);
      expect(controller.waistFactor, 0.5);
      expect(controller.plan, isNotNull);
      expect(notifications, greaterThan(0));
    });

    test('selectMonth changes the milestone factors and notifies', () async {
      await controller.load();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.selectMonth(6);

      expect(controller.selectedMonth, 6);
      expect(controller.shoulderFactor, 1.0);
      expect(controller.waistFactor, lessThan(0.5));
      expect(notifications, 1);
    });

    test('fat loss plan slims the waist at 6 months', () async {
      final fatLoss = ProjectionController(
        repository: MockProjectionRepository(goal: FitnessGoal.fatLoss),
      );
      await fatLoss.load();

      fatLoss.selectMonth(6);
      expect(fatLoss.waistFactor, 0.25);
      expect(fatLoss.shoulderFactor, greaterThan(0.5));
    });
  });
}
