import 'package:flutter/material.dart';

import '../../core/data/daily_entry_repository.dart';
import '../../core/domain/i18n/localization_scope.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/custom_button.dart';
import '../atoms/typography.dart';

/// The Profile "Pruebas" (Tests) panel: quick notification test triggers.
class TestsPanel extends StatelessWidget {
  /// Creates a tests panel.
  const TestsPanel({
    super.key,
    required this.notificationService,
    this.dailyEntryRepository,
    this.consumedCalories = 0,
  });

  /// Service used to fire the test notifications.
  final NotificationService notificationService;

  /// Optional calendar store used by the reactive meal notification.
  final DailyEntryRepository? dailyEntryRepository;

  /// Calories passed to the reactive meal notification body.
  final int consumedCalories;

  @override
  Widget build(BuildContext context) {
    final strings = LocalizationScope.stringsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCaption(strings.quickTestTitle),
        const SizedBox(height: AppSpacing.sm),
        CustomButton(
          key: const Key('settings_meal_test_button'),
          label: strings.mealTestButton,
          variant: CustomButtonVariant.ghost,
          onPressed: () {
            final repository = dailyEntryRepository;
            if (repository != null) {
              notificationService.showReactiveMealNotification(
                repository: repository,
                recovered: consumedCalories,
              );
            }
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        CustomButton(
          key: const Key('settings_nightly_test_button'),
          label: strings.nightlyCheckInTestButton,
          variant: CustomButtonVariant.ghost,
          onPressed: notificationService.showNightlyCheckInTest,
        ),
        const SizedBox(height: AppSpacing.sm),
        CustomButton(
          key: const Key('settings_exercise_not_button'),
          label: strings.exerciseNotButton,
          variant: CustomButtonVariant.ghost,
          onPressed: notificationService.showExerciseReminderTest,
        ),
      ],
    );
  }
}
