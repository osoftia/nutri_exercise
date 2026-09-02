import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/data/notification_prefs_repository.dart';
import 'package:nutri_mobile_app/core/data/settings_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_notification_prefs_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_settings_repository.dart';
import 'package:nutri_mobile_app/core/models/notification_pref.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/pages/settings_page.dart';

void main() {
  Widget wrap({SettingsRepository? settings, NotificationPrefsRepository? prefs}) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: SettingsPage(
        settingsRepository: settings ?? MockSettingsRepository(),
        prefsRepository: prefs ?? MockNotificationPrefsRepository(),
      ),
    );
  }

  group('Saved Records', () {
    testWidgets('opening the settings screen shows saved records and focus', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.text('Monday'), findsOneWidget);
      expect(find.text('Chest & Triceps'), findsOneWidget);
      expect(find.text('Wednesday'), findsOneWidget);
      expect(find.text('Back & Biceps'), findsOneWidget);
    });

    testWidgets('tapping a record shows its exercise details', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Monday'));
      await tester.pumpAndSettle();

      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('4 x 8-12'), findsOneWidget);
      expect(find.text('Triceps Pushdown'), findsOneWidget);
    });

    testWidgets('editing the focus area persists the change', (tester) async {
      final settings = MockSettingsRepository();
      await tester.pumpWidget(wrap(settings: settings));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('focus_edit_field')),
        'Push day',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Push day'), findsOneWidget);

      final records = await settings.getRecords();
      expect(records.firstWhere((r) => r.id == 1).focus, 'Push day');
    });

    testWidgets('deleting a record removes it from list and repository', (
      tester,
    ) async {
      final settings = MockSettingsRepository();
      await tester.pumpWidget(wrap(settings: settings));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      final ids = (await settings.getRecords()).map((r) => r.id).toList();
      expect(ids, isNot(contains(1)));

      await tester.pumpAndSettle();
      expect(find.text('Monday'), findsNothing);
    });
  });

  group('Notification Preferences', () {
    testWidgets('all toggles are off by default', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(
        tester.widget<SwitchListTile>(find.byKey(const Key('toggle_exercise_alerts'))).value,
        isFalse,
      );
      expect(
        tester.widget<SwitchListTile>(find.byKey(const Key('toggle_food_alerts'))).value,
        isFalse,
      );
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('toggle_daily_intake_reminders')))
            .value,
        isFalse,
      );
    });

    testWidgets('toggling exercise alerts on persists the preference', (
      tester,
    ) async {
      final prefs = MockNotificationPrefsRepository();
      await tester.pumpWidget(wrap(prefs: prefs));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('toggle_exercise_alerts')));
      await tester.pumpAndSettle();

      expect(
        await prefs.isEnabled(NotificationPrefType.exerciseAlerts),
        isTrue,
      );
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('toggle_exercise_alerts')))
            .value,
        isTrue,
      );
    });

    testWidgets('toggling food alerts on persists the preference', (
      tester,
    ) async {
      final prefs = MockNotificationPrefsRepository();
      await tester.pumpWidget(wrap(prefs: prefs));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('toggle_food_alerts')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('toggle_food_alerts')));
      await tester.pumpAndSettle();

      expect(await prefs.isEnabled(NotificationPrefType.foodAlerts), isTrue);
    });

    testWidgets('toggling daily intake reminders on persists the preference', (
      tester,
    ) async {
      final prefs = MockNotificationPrefsRepository();
      await tester.pumpWidget(wrap(prefs: prefs));
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('toggle_daily_intake_reminders')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('toggle_daily_intake_reminders')));
      await tester.pumpAndSettle();

      expect(
        await prefs.isEnabled(NotificationPrefType.dailyIntakeReminders),
        isTrue,
      );
    });

    testWidgets('preferences persist when the page is rebuilt', (tester) async {
      final prefs = MockNotificationPrefsRepository();
      await tester.pumpWidget(wrap(prefs: prefs));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('toggle_exercise_alerts')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('toggle_food_alerts')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('toggle_food_alerts')));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(wrap(prefs: prefs));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('toggle_exercise_alerts')))
            .value,
        isTrue,
      );
      expect(
        tester.widget<SwitchListTile>(find.byKey(const Key('toggle_food_alerts'))).value,
        isTrue,
      );
    });
  });
}