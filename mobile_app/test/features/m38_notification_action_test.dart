import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_body_detail_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_log_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_nutrition_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_profile_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_projection_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_schedule_repository.dart';
import 'package:nutri_mobile_app/core/services/rule_based_muscle_gap_advisor.dart';
import 'package:nutri_mobile_app/core/state/body_detail_controller.dart';
import 'package:nutri_mobile_app/core/state/daily_log_controller.dart';
import 'package:nutri_mobile_app/core/state/notification_navigation_controller.dart';
import 'package:nutri_mobile_app/core/state/nutrition_controller.dart';
import 'package:nutri_mobile_app/core/state/projection_controller.dart';
import 'package:nutri_mobile_app/core/state/schedule_controller.dart';
import 'package:nutri_mobile_app/core/state/user_profile_controller.dart';
import 'package:nutri_mobile_app/core/state/workout_completion_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/pages/main_shell_page.dart';

void main() {
  test('requestExerciseCompletion marks the action pending', () {
    final nav = NotificationNavigationController();
    nav.requestExerciseCompletion();
    expect(nav.pending, NotificationAction.exerciseCompleted);
    nav.consume();
    expect(nav.pending, isNull);
  });

  testWidgets('the shell opens the completion sheet for the pending action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final nav = NotificationNavigationController();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: MainShellPage(
          profileController: UserProfileController(
            repository: MockProfileRepository(),
          ),
          scheduleController: ScheduleController(
            repository: MockScheduleRepository(),
            initialMonth: DateTime(2026, 8),
          ),
          nutritionController: NutritionController(
            repository: MockNutritionRepository(),
          ),
          projectionController: ProjectionController(
            repository: MockProjectionRepository(),
          ),
          bodyDetailController: BodyDetailController(
            repository: MockBodyDetailRepository(),
            advisor: const RuleBasedMuscleGapAdvisor(),
          ),
          aiChatController: null,
          notificationNav: nav,
          dailyLogController: DailyLogController(
            repository: MockDailyLogRepository(),
          ),
          workoutCompletionController: WorkoutCompletionController(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    nav.requestExerciseCompletion();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('exercise_completion_sheet')), findsOneWidget);
  });
}
