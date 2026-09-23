import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/app.dart';
import 'package:nutri_mobile_app/core/config/app_config.dart';
import 'package:nutri_mobile_app/core/models/daily_entry.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/services/notification_service.dart';
import 'package:nutri_mobile_app/core/utils/weekly_stats.dart';

void main() {
  group('NotificationService meal-logged body', () {
    test('reminds the user to do their routine when no exercise is logged',
        () async {
      final repo = MockDailyEntryRepository();
      final service = NotificationService();

      final body = await service.mealLoggedNotificationBody(
        repository: repo,
        recovered: 650,
      );

      expect(body, 'Remember to do your routine!');
    });

    test('reports recovered vs burned calories when exercises are logged',
        () async {
      final today = DailyEntry.dateKey(DateTime.now());
      final repo = MockDailyEntryRepository();
      await repo.save(DailyEntry(
        date: today,
        exercises: const ['Squat', 'Bench Press'],
      ));
      final service = NotificationService();

      final body = await service.mealLoggedNotificationBody(
        repository: repo,
        recovered: 650,
      );

      final burned = 2 * caloriesBurnedPerExercise;
      expect(body, "You've recovered 650 of the $burned calories you burned!");
    });
  });

  testWidgets('nutrition tab no longer hosts the notification test controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      NutriApp(config: const AppConfig(name: 'dev', useMocks: true)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nutrition'));
    await tester.pumpAndSettle();

    // M47 Task 3: the triggers moved to the Profile "Pruebas" section.
    expect(find.byKey(const Key('test_notifications_button')), findsNothing);
    expect(
      find.byKey(const Key('reactive_notifications_toggle')),
      findsNothing,
    );
  });
}