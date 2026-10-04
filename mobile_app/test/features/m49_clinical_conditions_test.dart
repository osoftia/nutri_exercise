import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/clinical/clinical_condition.dart';
import 'package:nutri_mobile_app/core/mocks/mock_clinical_profile_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_notification_prefs_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_profile_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_symptom_repository.dart';
import 'package:nutri_mobile_app/core/state/clinical_profile_controller.dart';
import 'package:nutri_mobile_app/core/state/symptom_controller.dart';
import 'package:nutri_mobile_app/core/state/user_profile_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/pages/profile_page.dart';

void main() {
  Future<ClinicalProfileController> pumpProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final clinicalController = ClinicalProfileController(
      repository: MockClinicalProfileRepository(),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: ProfilePage(
          controller: UserProfileController(
            repository: MockProfileRepository(),
          ),
          symptomController: SymptomController(
            repository: MockSymptomRepository(),
          ),
          clinicalProfileController: clinicalController,
          notificationPrefsRepository: MockNotificationPrefsRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return clinicalController;
  }

  testWidgets('clinical and daily symptom sections start collapsed', (
    tester,
  ) async {
    await pumpProfile(tester);

    expect(
      find.byKey(const Key('profile_clinical_conditions_accordion')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('profile_symptoms_accordion')), findsOneWidget);
    expect(find.byKey(const Key('clinical_conditions_panel')), findsNothing);
    expect(find.byKey(const Key('symptom_tracker')), findsNothing);
  });

  testWidgets('mock case immediately selects high cholesterol', (tester) async {
    final controller = await pumpProfile(tester);
    await tester.tap(
      find.byKey(const Key('profile_clinical_conditions_accordion')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('clinical_conditions_panel')), findsOneWidget);
    final selector = find.byKey(const Key('clinical_mock_case_selector'));
    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester
        .tap(find.text('Case: High cholesterol — red meat vs oats').last);
    await tester.pumpAndSettle();

    expect(
      controller.profile.severityFor(ClinicalCondition.highCholesterol),
      ClinicalSeverity.high,
    );
    expect(find.byKey(const Key('clinical_condition_highCholesterol')),
        findsOneWidget);
  });

  testWidgets('manual condition and severity controls update the profile', (
    tester,
  ) async {
    final controller = await pumpProfile(tester);
    await tester.tap(
      find.byKey(const Key('profile_clinical_conditions_accordion')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('clinical_condition_diabetes')));
    await tester.pumpAndSettle();

    expect(
      controller.profile.severityFor(ClinicalCondition.diabetes),
      ClinicalSeverity.moderate,
    );
    expect(controller.profile.mockCase, ClinicalMockCase.none);

    await tester.tap(find.byKey(const Key('profile_symptoms_accordion')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('symptom_tracker')), findsOneWidget);
  });
}
