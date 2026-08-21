import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_profile_repository.dart';
import 'package:nutri_mobile_app/core/models/user_profile.dart';

void main() {
  group('MockProfileRepository', () {
    test('returns null when no profile has been saved', () async {
      final repo = MockProfileRepository();

      expect(await repo.getProfile(), isNull);
    });

    test('returns the saved profile after saveProfile', () async {
      final repo = MockProfileRepository();

      const profile = UserProfile(
        name: 'Jane Doe',
        age: 28,
        weightKg: 65,
        heightCm: 170,
        goal: FitnessGoal.muscleGain,
      );
      await repo.saveProfile(profile);

      final restored = await repo.getProfile();
      expect(restored?.name, 'Jane Doe');
      expect(restored?.age, 28);
      expect(restored?.weightKg, 65);
      expect(restored?.goal, FitnessGoal.muscleGain);
    });

    test('can be seeded with an existing profile', () async {
      const profile = UserProfile(
        name: 'Seed',
        age: 30,
        weightKg: 80,
        heightCm: 180,
        goal: FitnessGoal.maintain,
      );
      final repo = MockProfileRepository(profile: profile);

      expect((await repo.getProfile())?.name, 'Seed');
    });
  });
}