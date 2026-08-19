import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_notification_prefs_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_settings_repository.dart';
import 'package:nutri_mobile_app/core/models/notification_pref.dart';
import 'package:nutri_mobile_app/core/models/routine_models.dart';

void main() {
  group('MockNotificationPrefsRepository', () {
    test('defaults all notification prefs to disabled', () async {
      final repo = MockNotificationPrefsRepository();

      expect(await repo.isEnabled(NotificationPrefType.exerciseAlerts), isFalse);
      expect(await repo.isEnabled(NotificationPrefType.foodAlerts), isFalse);
      expect(
        await repo.isEnabled(NotificationPrefType.dailyIntakeReminders),
        isFalse,
      );
    });

    test('persists enabled state in memory', () async {
      final repo = MockNotificationPrefsRepository();

      await repo.setEnabled(NotificationPrefType.exerciseAlerts, true);
      await repo.setEnabled(NotificationPrefType.foodAlerts, true);

      expect(
        await repo.isEnabled(NotificationPrefType.exerciseAlerts),
        isTrue,
      );
      expect(await repo.isEnabled(NotificationPrefType.foodAlerts), isTrue);
      expect(
        await repo.isEnabled(NotificationPrefType.dailyIntakeReminders),
        isFalse,
      );
    });
  });

  group('MockSettingsRepository', () {
    test('returns seeded records', () async {
      final repo = MockSettingsRepository();
      final records = await repo.getRecords();

      expect(records.length, greaterThanOrEqualTo(2));
      expect(records.map((r) => r.weekday), contains('Monday'));
    });

    test('updates the focus of a record', () async {
      final repo = MockSettingsRepository();
      await repo.updateRecordFocus(1, 'Push day');

      final records = await repo.getRecords();
      final monday = records.firstWhere((r) => r.id == 1);
      expect(monday.focus, 'Push day');
    });

    test('deletes a record', () async {
      final repo = MockSettingsRepository();
      await repo.deleteRecord(2);

      final records = await repo.getRecords();
      expect(records.any((r) => r.id == 2), isFalse);
    });
  });

  test('NotificationPrefType maps to stable keys', () {
    expect(NotificationPrefType.exerciseAlerts.key, 'exercise_alerts');
    expect(NotificationPrefType.foodAlerts.key, 'food_alerts');
    expect(
      NotificationPrefType.dailyIntakeReminders.key,
      'daily_intake_reminders',
    );
    expect(NotificationPrefType.values.length, 3);
  });

  test('WorkoutDay is constructible for settings', () {
    const day = WorkoutDay(
      id: 1,
      weekday: 'Monday',
      focus: 'Chest & Triceps',
      exercises: [],
    );
    expect(day.focus, 'Chest & Triceps');
  });
}