import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_notification_prefs_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_profile_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_symptom_repository.dart';
import 'package:nutri_mobile_app/core/models/notification_pref.dart';
import 'package:nutri_mobile_app/core/state/symptom_controller.dart';
import 'package:nutri_mobile_app/core/state/user_profile_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/pages/profile_page.dart';

void main() {
  Future<MockNotificationPrefsRepository> pumpProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final prefs = MockNotificationPrefsRepository();
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
          notificationPrefsRepository: prefs,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return prefs;
  }

  group('M46 profile accordion sections', () {
    testWidgets('renders both symptom and settings accordion headers', (
      tester,
    ) async {
      await pumpProfile(tester);

      expect(
        find.byKey(const Key('profile_symptoms_accordion')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('profile_settings_accordion')),
        findsOneWidget,
      );
      // Collapsed by default: bodies are not laid out.
      expect(find.byKey(const Key('symptom_tracker')), findsNothing);
      expect(
        find.byKey(const Key('settings_toggle_exercise_alerts')),
        findsNothing,
      );
    });

    testWidgets('expanding Daily Symptoms reveals the symptom tracker', (
      tester,
    ) async {
      await pumpProfile(tester);

      await tester.tap(find.byKey(const Key('profile_symptoms_accordion')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('symptom_tracker')), findsOneWidget);
      expect(find.byKey(const Key('symptom_pain')), findsOneWidget);
    });

    testWidgets('expanding Settings reveals toggles that persist', (
      tester,
    ) async {
      final prefs = await pumpProfile(tester);

      await tester.tap(find.byKey(const Key('profile_settings_accordion')));
      await tester.pumpAndSettle();

      final toggle = find.byKey(const Key('settings_toggle_exercise_alerts'));
      expect(toggle, findsOneWidget);

      await tester.tap(toggle);
      await tester.pumpAndSettle();

      expect(
        await prefs.isEnabled(NotificationPrefType.exerciseAlerts),
        isTrue,
      );
    });
  });
}
