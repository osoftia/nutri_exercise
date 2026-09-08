import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_entry_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_nutrition_repository.dart';
import 'package:nutri_mobile_app/core/services/notification_service.dart';
import 'package:nutri_mobile_app/core/state/nutrition_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/pages/nutrition_page.dart';

class _SpyNotificationService extends NotificationService {
  int exerciseTestCalls = 0;

  @override
  Future<void> showExerciseReminderTest() async {
    exerciseTestCalls++;
  }
}

void main() {
  testWidgets('nutrition tab shows the EXERCISE NOT button and triggers a test',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final service = _SpyNotificationService();
    final controller = NutritionController(
      repository: MockNutritionRepository(),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: NutritionPage(
          controller: controller,
          dailyEntryRepository: MockDailyEntryRepository(),
          notificationService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('exercise_not_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('exercise_not_button')));
    await tester.pump();

    expect(service.exerciseTestCalls, 1);
  });
}