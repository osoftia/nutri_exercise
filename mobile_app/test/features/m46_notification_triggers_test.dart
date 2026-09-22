import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_notification_prefs_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_nutrition_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_profile_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_symptom_repository.dart';
import 'package:nutri_mobile_app/core/services/notification_service.dart';
import 'package:nutri_mobile_app/core/state/nutrition_controller.dart';
import 'package:nutri_mobile_app/core/state/symptom_controller.dart';
import 'package:nutri_mobile_app/core/state/user_profile_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/pages/nutrition_page.dart';
import 'package:nutri_mobile_app/ui/pages/profile_page.dart';

class _RecordingPlatform extends FlutterLocalNotificationsPlatform {
  int? lastId;
  String? lastTitle;
  String? lastBody;

  @override
  Future<void> show(
    int id,
    String? title,
    String? body, {
    String? payload,
  }) async {
    lastId = id;
    lastTitle = title;
    lastBody = body;
  }
}

class _SpyNotificationService extends NotificationService {
  int nightlyCalls = 0;
  int exerciseCalls = 0;

  @override
  Future<void> showNightlyCheckInTest() async {
    nightlyCalls++;
  }

  @override
  Future<void> showExerciseReminderTest({String? payload}) async {
    exerciseCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('M46 nightly check-in test trigger (service)', () {
    test('shows the nightly check-in notification immediately', () async {
      final platform = _RecordingPlatform();
      FlutterLocalNotificationsPlatform.instance = platform;
      // Route the plugin's `show` through the platform interface (the Android
      // branch resolves to a platform-specific implementation instead).
      debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await NotificationService().showNightlyCheckInTest();

      expect(platform.lastId, NotificationService.nightlyCheckInTestId);
      expect(platform.lastTitle, NotificationService.nightlyCheckInTitle);
      expect(platform.lastBody, isNotEmpty);
    });
  });

  group('M46 quick-test trigger in the Nutrition section', () {
    testWidgets('tapping the nightly test button fires the test', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final service = _SpyNotificationService();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: NutritionPage(
            controller: NutritionController(
              repository: MockNutritionRepository(),
            ),
            dailyEntryRepository: MockDailyEntryRepository(),
            notificationService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = find.byKey(const Key('nightly_check_in_test_button'));
      expect(button, findsOneWidget);
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pump();

      expect(service.nightlyCalls, 1);
    });
  });

  group('M46 quick-test trigger in the Profile settings section', () {
    testWidgets('the settings panel exposes both test triggers', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final service = _SpyNotificationService();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: ProfilePage(
            controller: UserProfileController(
              repository: MockProfileRepository(),
            ),
            symptomController: SymptomController(
              repository: MockSymptomRepository(),
              date: DateTime(2026, 9, 21),
            ),
            notificationPrefsRepository: MockNotificationPrefsRepository(),
            notificationService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('profile_settings_accordion')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings_nightly_test_button')));
      await tester.pump();
      expect(service.nightlyCalls, 1);

      await tester.tap(find.byKey(const Key('settings_exercise_not_button')));
      await tester.pump();
      expect(service.exerciseCalls, 1);
    });
  });
}
