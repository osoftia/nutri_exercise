import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/i18n/app_language.dart';
import 'package:nutri_mobile_app/core/domain/i18n/localization_scope.dart';
import 'package:nutri_mobile_app/core/mocks/mock_body_detail_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_language_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_nutrition_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_profile_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_projection_repository.dart';
import 'package:nutri_mobile_app/core/services/rule_based_muscle_gap_advisor.dart';
import 'package:nutri_mobile_app/core/state/body_detail_controller.dart';
import 'package:nutri_mobile_app/core/state/language_controller.dart';
import 'package:nutri_mobile_app/core/state/nutrition_controller.dart';
import 'package:nutri_mobile_app/core/state/projection_controller.dart';
import 'package:nutri_mobile_app/core/state/user_profile_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/pages/nutrition_page.dart';
import 'package:nutri_mobile_app/ui/pages/profile_page.dart';
import 'package:nutri_mobile_app/ui/pages/routines_page.dart';

LanguageController? _activeController;

/// Pumps [child] inside a live language scope that rebuilds on switch.
Future<LanguageController> _pumpLocalized(
  WidgetTester tester,
  Widget Function(BuildContext) child,
) async {
  tester.view.physicalSize = const Size(1000, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final controller = LanguageController(repository: MockLanguageRepository());
  _activeController = controller;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => LocalizationScope(
          language: controller.language,
          child: child(context),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return controller;
}

Future<void> _switchToSpanish(WidgetTester tester) async {
  await _activeController!.setLanguage(AppLanguage.spanish);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Nutrition tab localizes its labels on switch', (tester) async {
    await _pumpLocalized(
      tester,
      (_) => NutritionPage(
        controller: NutritionController(
          repository: MockNutritionRepository(),
        ),
      ),
    );

    expect(find.text('Nutrition'), findsOneWidget);
    expect(find.text('Quick Add'), findsOneWidget);
    expect(find.text('Calories'), findsWidgets);

    await _switchToSpanish(tester);

    expect(find.text('Nutrición'), findsOneWidget);
    expect(find.text('Añadir rápido'), findsOneWidget);
    expect(find.text('Calorías'), findsWidgets);
    expect(find.text('Nutrition'), findsNothing);
  });

  testWidgets('Routines tab localizes its labels on switch', (tester) async {
    await _pumpLocalized(
      tester,
      (_) => RoutinesPage(
        controller: ProjectionController(
          repository: MockProjectionRepository(),
        ),
        detailController: BodyDetailController(
          repository: MockBodyDetailRepository(),
          advisor: const RuleBasedMuscleGapAdvisor(),
        ),
      ),
    );

    expect(find.text('Body Projection'), findsOneWidget);

    await _switchToSpanish(tester);

    expect(find.text('Rutinas'), findsWidgets);
    expect(find.text('Proyección corporal'), findsOneWidget);
    expect(find.text('Body Projection'), findsNothing);
  });

  testWidgets('Profile tab localizes its form labels on switch', (tester) async {
    final language = LanguageController(repository: MockLanguageRepository());
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: ListenableBuilder(
          listenable: language,
          builder: (context, _) => LocalizationScope(
            language: language.language,
            child: ProfilePage(
              controller: UserProfileController(
                repository: MockProfileRepository(),
              ),
              languageController: language,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Save Profile'), findsOneWidget);

    await language.setLanguage(AppLanguage.spanish);
    await tester.pumpAndSettle();

    expect(find.text('Guardar perfil'), findsOneWidget);
    expect(find.text('Save Profile'), findsNothing);

    // M47: the language switcher now lives inside System Settings; expanding it
    // reveals the localized heading.
    await tester.tap(find.byKey(const Key('profile_settings_accordion')));
    await tester.pumpAndSettle();
    expect(find.text('Idioma'), findsOneWidget);
  });

  testWidgets('validation messages localize on switch', (tester) async {
    final language = LanguageController(repository: MockLanguageRepository());
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: ListenableBuilder(
          listenable: language,
          builder: (context, _) => LocalizationScope(
            language: language.language,
            child: ProfilePage(
              controller: UserProfileController(
                repository: MockProfileRepository(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('profile_name_field')),
      '',
    );
    await tester.ensureVisible(find.byKey(const Key('profile_save_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile_save_button')));
    await tester.pumpAndSettle();
    expect(find.text('Name is required'), findsOneWidget);

    await language.setLanguage(AppLanguage.spanish);
    await tester.pumpAndSettle();

    // Re-submitting re-runs the validator, now with the Spanish dictionary.
    await tester.tap(find.byKey(const Key('profile_save_button')));
    await tester.pumpAndSettle();

    expect(find.text('Nombre es obligatorio'), findsOneWidget);
    expect(find.text('Name is required'), findsNothing);
  });
}
