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
  Future<void> showExerciseReminderTest({String? payload}) async {
    exerciseTestCalls++;
  }
}

void main() {
  testWidgets('nutrition tab no longer shows the EXERCISE NOT button (M47)', (
    tester,
  ) async {
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

    // M47 Task 3: the trigger moved to the Profile "Pruebas" section.
    expect(find.byKey(const Key('exercise_not_button')), findsNothing);
    expect(service.exerciseTestCalls, 0);
  });
}