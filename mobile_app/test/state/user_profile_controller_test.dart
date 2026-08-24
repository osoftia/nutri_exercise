import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_profile_repository.dart';
import 'package:nutri_mobile_app/core/models/user_profile.dart';
import 'package:nutri_mobile_app/core/state/user_profile_controller.dart';

void main() {
  group('UserProfileController', () {
    test('load populates the profile from the repository and notifies', () async {
      const profile = UserProfile(
        name: 'Jane Doe',
        age: 28,
        weightKg: 65,
        heightCm: 170,
        goal: FitnessGoal.muscleGain,
      );
      final repo = MockProfileRepository(profile: profile);
      final controller = UserProfileController(repository: repo);
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.load();

      expect(controller.profile?.name, 'Jane Doe');
      expect(notifications, greaterThan(0));
    });

    test('load with no saved profile leaves the profile null', () async {
      final repo = MockProfileRepository();
      final controller = UserProfileController(repository: repo);

      await controller.load();

      expect(controller.profile, isNull);
    });

    test('save persists to the repository and notifies', () async {
      final repo = MockProfileRepository();
      final controller = UserProfileController(repository: repo);
      var notifications = 0;
      controller.addListener(() => notifications++);

      const profile = UserProfile(
        name: 'Jane Doe',
        age: 28,
        weightKg: 65,
        heightCm: 170,
        goal: FitnessGoal.fatLoss,
      );
      await controller.save(profile);

      expect(controller.profile?.name, 'Jane Doe');
      expect(controller.profile?.goal, FitnessGoal.fatLoss);
      expect((await repo.getProfile())?.goal, FitnessGoal.fatLoss);
      expect(notifications, greaterThan(0));
    });
  });
}