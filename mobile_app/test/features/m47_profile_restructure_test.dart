import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/domain/i18n/app_language.dart';
import 'package:nutri_mobile_app/core/domain/i18n/localization_scope.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_notification_prefs_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_language_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_nutrition_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_profile_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_symptom_repository.dart';
import 'package:nutri_mobile_app/core/services/notification_service.dart';
import 'package:nutri_mobile_app/core/state/language_controller.dart';
import 'package:nutri_mobile_app/core/state/nutrition_controller.dart';
import 'package:nutri_mobile_app/core/state/symptom_controller.dart';
import 'package:nutri_mobile_app/core/state/user_profile_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/pages/nutrition_page.dart';
import 'package:nutri_mobile_app/ui/pages/profile_page.dart';

class _SpyNotificationService extends NotificationService {
  int mealNotifications = 0;
  int nightlyCalls = 0;

  @override
  Future<void> showReactiveMealNotification({
    required DailyEntryRepository repository,
    required int recovered,
  }) async {
    mealNotifications++;
  }

  @override
  Future<void> showNightlyCheckInTest() async {
    nightlyCalls++;
  }
}

void main() {
  group('M47 profile restructuring', () {
    Future<void> pumpProfile(WidgetTester tester, NotificationService svc) async {
      tester.view.physicalSize = const Size(1000, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: LocalizationScope(
            language: AppLanguage.spanish,
            child: ProfilePage(
              controller: UserProfileController(
                repository: MockProfileRepository(),
              ),
              languageController: LanguageController(
                repository: MockLanguageRepository(),
              ),
              symptomController: SymptomController(
                repository: MockSymptomRepository(),
                date: DateTime(2026, 9, 21),
              ),
              notificationPrefsRepository: MockNotificationPrefsRepository(),
              notificationService: svc,
              dailyEntryRepository: MockDailyEntryRepository(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders user settings, system settings and tests accordions', (
      tester,
    ) async {
      await pumpProfile(tester, _SpyNotificationService());

      expect(find.byKey(const Key('profile_user_settings_accordion')), findsOneWidget);
      expect(find.byKey(const Key('profile_symptoms_accordion')), findsOneWidget);
      expect(find.byKey(const Key('profile_settings_accordion')), findsOneWidget);
      expect(find.byKey(const Key('profile_tests_accordion')), findsOneWidget);

      expect(find.text('Ajustes de Usuario'), findsOneWidget);
      expect(find.text('Ajustes de Sistema'), findsOneWidget);
      expect(find.text('Pruebas'), findsOneWidget);
      // The symptom subtitle is hidden while collapsed (title-only pattern).
      expect(
        find.text('Mantén pulsado un icono para ver qué registra'),
        findsNothing,
      );
    });

    testWidgets('user settings accordion hosts the profile form', (tester) async {
      await pumpProfile(tester, _SpyNotificationService());

      // User Settings starts expanded.
      final field = find.byKey(const Key('profile_name_field'));
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      expect(field, findsOneWidget);
      expect(find.byKey(const Key('profile_save_button')), findsOneWidget);

      // Collapsing hides the form again (title-only collapsed state).
      await tester.tap(find.byKey(const Key('profile_user_settings_accordion')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile_name_field')), findsNothing);
    });

    testWidgets('language sits at the very bottom of system settings', (
      tester,
    ) async {
      await pumpProfile(tester, _SpyNotificationService());

      await tester.tap(find.byKey(const Key('profile_settings_accordion')));
      await tester.pumpAndSettle();

      // The language switcher title is localized ("Idioma" in Spanish).
      final languageLabel = find.text('Idioma');
      expect(languageLabel, findsOneWidget);

      final languageY = tester.getCenter(languageLabel).dy;
      final toggles = find.byKey(const Key('settings_toggle_exercise_alerts'));
      await tester.ensureVisible(toggles);
      await tester.pumpAndSettle();
      expect(tester.getCenter(toggles).dy, lessThan(languageY));
    });

    testWidgets('Pruebas section hosts the meal test notification', (
      tester,
    ) async {
      final svc = _SpyNotificationService();
      await pumpProfile(tester, svc);

      await tester.tap(find.byKey(const Key('profile_tests_accordion')));
      await tester.pumpAndSettle();

      final button = find.byKey(const Key('settings_meal_test_button'));
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pump();
      expect(svc.mealNotifications, 1);
    });
  });

  group('M47 nutrition tab has no notification triggers', () {
    testWidgets('the notification test buttons were removed', (tester) async {
      tester.view.physicalSize = const Size(1000, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: NutritionPage(
            controller: NutritionController(
              repository: MockNutritionRepository(),
            ),
            dailyEntryRepository: MockDailyEntryRepository(),
            notificationService: _SpyNotificationService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('exercise_not_button')), findsNothing);
      expect(find.byKey(const Key('test_notifications_button')), findsNothing);
      expect(find.byKey(const Key('nightly_check_in_test_button')), findsNothing);
      expect(find.byKey(const Key('reactive_notifications_toggle')), findsNothing);
    });
  });
}
