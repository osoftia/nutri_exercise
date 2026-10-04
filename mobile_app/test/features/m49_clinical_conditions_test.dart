import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/clinical/clinical_condition.dart';
import 'package:nutri_mobile_app/core/domain/clinical/clinical_condition_profile.dart';
import 'package:nutri_mobile_app/core/data/body_detail_seed.dart';
import 'package:nutri_mobile_app/core/mocks/mock_body_detail_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_clinical_profile_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_nutrition_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_notification_prefs_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_profile_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_symptom_repository.dart';
import 'package:nutri_mobile_app/core/state/clinical_profile_controller.dart';
import 'package:nutri_mobile_app/core/state/body_detail_controller.dart';
import 'package:nutri_mobile_app/core/state/nutrition_controller.dart';
import 'package:nutri_mobile_app/core/state/symptom_controller.dart';
import 'package:nutri_mobile_app/core/state/user_profile_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/pages/profile_page.dart';
import 'package:nutri_mobile_app/ui/pages/nutrition_page.dart';
import 'package:nutri_mobile_app/core/services/rule_based_muscle_gap_advisor.dart';
import 'package:nutri_mobile_app/ui/molecules/body_food_detail_sheet.dart';

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

  testWidgets(
      'nutrition search reacts to mock case changes with red/green tags', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final clinicalController = ClinicalProfileController(
      repository: MockClinicalProfileRepository(),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: NutritionPage(
            controller: NutritionController(
              repository: MockNutritionRepository(),
            ),
            clinicalProfileController: clinicalController,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('clinical_food_Red Meat Steak')), findsNothing);
    await clinicalController.selectMockCase(ClinicalMockCase.highCholesterol);
    await tester.pumpAndSettle();

    expect(find.text('Warning'), findsWidgets);
    expect(find.text('Supportive'), findsWidgets);
    await tester.enterText(
      find.byKey(const Key('clinical_food_search_field')),
      'steak',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('quick_add_Red Meat Steak')), findsOneWidget);
    expect(find.byKey(const Key('quick_add_Oatmeal & Berries')), findsNothing);
  });

  testWidgets('quick-add warning updates for the entered serving size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final clinicalController = ClinicalProfileController(
      repository: MockClinicalProfileRepository(
        initialProfile: const ClinicalConditionProfile(
          conditions: {
            ClinicalCondition.highCholesterol: ClinicalSeverity.high,
          },
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: NutritionPage(
            controller: NutritionController(
              repository: MockNutritionRepository(),
            ),
            clinicalProfileController: clinicalController,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('quick_add_Red Meat Steak')));
    await tester.tap(find.byKey(const Key('quick_add_Red Meat Steak')));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('quick_add_clinical_guidance')),
        matching: find.text('Warning'),
      ),
      findsOneWidget,
    );
    await tester.enterText(
        find.byKey(const Key('quick_add_grams_field')), '25');
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('quick_add_clinical_guidance')),
        matching: find.text('Within selected guidance'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('logged-food detail shows condition-specific food guidance', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final clinicalController = ClinicalProfileController(
      repository: MockClinicalProfileRepository(
        initialProfile: const ClinicalConditionProfile(
          conditions: {
            ClinicalCondition.highCholesterol: ClinicalSeverity.high,
          },
        ),
      ),
    );
    final bodyController = BodyDetailController(
      repository: MockBodyDetailRepository(foodLog: bodyFoodLogSeed),
      advisor: const RuleBasedMuscleGapAdvisor(),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: BodyFoodDetailSheet(
            controller: bodyController,
            clinicalProfileController: clinicalController,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('food_clinical_safety_Oatmeal & Berries')),
        findsOneWidget);
    expect(find.byKey(const Key('food_clinical_safety_Grilled Chicken Bowl')),
        findsOneWidget);
    expect(find.text('Supportive'), findsWidgets);
    expect(find.text('Warning'), findsWidgets);
  });
}
