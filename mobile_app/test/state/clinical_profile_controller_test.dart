import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/clinical/clinical_condition.dart';
import 'package:nutri_mobile_app/core/mocks/mock_clinical_profile_repository.dart';
import 'package:nutri_mobile_app/core/state/clinical_profile_controller.dart';

void main() {
  group('ClinicalProfileController', () {
    test('loads and persists selected conditions', () async {
      final repository = MockClinicalProfileRepository();
      final controller = ClinicalProfileController(repository: repository);
      await controller.load();

      await controller.setSeverity(
        ClinicalCondition.gout,
        ClinicalSeverity.high,
      );

      expect(controller.profile.severityFor(ClinicalCondition.gout),
          ClinicalSeverity.high);
      expect(
        (await repository.load()).severityFor(ClinicalCondition.gout),
        ClinicalSeverity.high,
      );
    });

    test('mock case applies conditions and emits reactive updates', () async {
      final controller = ClinicalProfileController(
        repository: MockClinicalProfileRepository(),
      );
      var notifications = 0;
      controller.addListener(() => notifications++);
      await controller.load();
      notifications = 0;

      await controller.selectMockCase(ClinicalMockCase.highCholesterol);

      expect(controller.profile.mockCase, ClinicalMockCase.highCholesterol);
      expect(controller.hasConditions, isTrue);
      expect(
        controller.profile.severityFor(ClinicalCondition.highCholesterol),
        ClinicalSeverity.high,
      );
      expect(notifications, greaterThan(0));
    });

    test('manual severity change clears mock-case selection', () async {
      final controller = ClinicalProfileController(
        repository: MockClinicalProfileRepository(),
      );
      await controller.selectMockCase(ClinicalMockCase.highCholesterol);

      await controller.setSeverity(
        ClinicalCondition.highCholesterol,
        ClinicalSeverity.moderate,
      );

      expect(controller.profile.mockCase, ClinicalMockCase.none);
      expect(
        controller.profile.severityFor(ClinicalCondition.highCholesterol),
        ClinicalSeverity.moderate,
      );
    });

    test('clearing conditions restores a blank clinical profile', () async {
      final controller = ClinicalProfileController(
        repository: MockClinicalProfileRepository(),
      );
      await controller.selectMockCase(ClinicalMockCase.gout);

      await controller.clearConditions();

      expect(controller.hasConditions, isFalse);
      expect(controller.profile.mockCase, ClinicalMockCase.none);
    });
  });
}
