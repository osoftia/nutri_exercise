import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/models/user_profile.dart';

void main() {
  group('UserProfile model', () {
    test('constructs with all fields', () {
      const profile = UserProfile(
        name: 'Jane Doe',
        age: 28,
        weightKg: 65,
        heightCm: 170,
        goal: FitnessGoal.muscleGain,
      );

      expect(profile.name, 'Jane Doe');
      expect(profile.age, 28);
      expect(profile.weightKg, 65);
      expect(profile.heightCm, 170);
      expect(profile.goal, FitnessGoal.muscleGain);
    });

    test('empty profile uses blank defaults', () {
      expect(UserProfile.empty.name, '');
      expect(UserProfile.empty.goal, FitnessGoal.muscleGain);
    });

    test('toMap/fromMap round-trips', () {
      const profile = UserProfile(
        name: 'Jane Doe',
        age: 28,
        weightKg: 65.5,
        heightCm: 170,
        goal: FitnessGoal.fatLoss,
      );

      final restored = UserProfile.fromMap(profile.toMap());

      expect(restored.name, profile.name);
      expect(restored.age, profile.age);
      expect(restored.weightKg, profile.weightKg);
      expect(restored.heightCm, profile.heightCm);
      expect(restored.goal, profile.goal);
    });

    test('FitnessGoal labels are human readable', () {
      expect(FitnessGoal.muscleGain.label, 'Muscle Gain');
      expect(FitnessGoal.fatLoss.label, 'Fat Loss');
      expect(FitnessGoal.maintain.label, 'Maintain');
      expect(FitnessGoal.endurance.label, 'Endurance');
    });
  });
}