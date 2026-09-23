import 'package:flutter/material.dart';

import '../../core/constants/muscle_group_map.dart';
import '../../core/constants/tamagotchi_groups.dart';
import '../../core/models/diet_models.dart';
import '../../core/models/user_profile.dart';
import '../../core/providers/routine_provider.dart';
import '../../core/state/daily_nutrition_state.dart';
import '../../core/state/muscle_tamagotchi_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/exercise_muscle_mapper.dart';
import '../atoms/custom_button.dart';
import '../atoms/typography.dart';
import '../molecules/daily_totals_card.dart';
import '../molecules/exercise_card.dart';
import '../organisms/home_dashboard_sections.dart';
import '../organisms/muscle_group_visualizer.dart';

/// The legacy admin dashboard's scrollable body.
///
/// Extracted from `home_page.dart` (M48 decomposition). It renders the daily
/// totals, muscle map, exercise list and daily menus, delegating every
/// mutation back to [onQuickAdd], [onSimulateWorkout], [onSimulateMeal] and the
/// [provider]/[tamagotchi] it receives.
class HomeDashboardContent extends StatelessWidget {
  /// Creates a dashboard content body.
  const HomeDashboardContent({
    super.key,
    required this.provider,
    required this.menus,
    required this.nutrition,
    required this.tamagotchi,
    required this.bodyWidthFactor,
    required this.onLaunchWizard,
    required this.onOpenDailyLog,
    required this.onNavigateToProfile,
    required this.onQuickAdd,
    required this.onSimulateWorkout,
    required this.onSimulateMeal,
    this.profile,
    this.showDailyLogHeader = false,
  });

  /// The routine provider driving the selected day/exercises.
  final RoutineProvider provider;

  /// The daily menus to list.
  final List<DailyMenu> menus;

  /// Shared daily nutrition totals.
  final DailyNutritionState nutrition;

  /// Shared muscle/tamagotchi state driving the avatar.
  final MuscleTamagotchiState tamagotchi;

  /// Baseline body width factor (from the user's BMI).
  final double bodyWidthFactor;

  /// Opens the AI routine wizard.
  final VoidCallback onLaunchWizard;

  /// Opens the quick daily log sheet (when a controller is available).
  final VoidCallback onOpenDailyLog;

  /// Navigates to the profile tab.
  final VoidCallback onNavigateToProfile;

  /// Adds a default quick meal.
  final VoidCallback onQuickAdd;

  /// Applies a simulated core workout.
  final VoidCallback onSimulateWorkout;

  /// Applies a simulated 650 kcal meal.
  final VoidCallback onSimulateMeal;

  /// The saved profile (for the info card).
  final UserProfile? profile;

  /// Whether to show the "Daily Log" header row.
  final bool showDailyLogHeader;

  @override
  Widget build(BuildContext context) {
    final exercises = provider.selectedDayExercises;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CustomButton(label: 'Ask AI', onPressed: onLaunchWizard),
            const SizedBox(width: AppSpacing.md),
            CustomButton(
              label: 'Refresh',
              variant: CustomButtonVariant.ghost,
              onPressed: provider.loadRoutine,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const SizedBox.shrink(),
        if (showDailyLogHeader) ...[
          const SizedBox(height: AppSpacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AppHeading('Daily Log', size: AppHeadingSize.h2),
              IconButton(
                key: const Key('daily_log_action'),
                icon: const Icon(
                  Icons.edit_note,
                  color: AppColors.primary400,
                ),
                tooltip: 'Quick log today',
                onPressed: onOpenDailyLog,
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xxl),
        const AppHeading('Daily Totals'),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: DailyTotalsCard(state: nutrition)),
            const SizedBox(width: AppSpacing.md),
            ProfileInfoCard(profile: profile, onEdit: onNavigateToProfile),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        const AppHeading('Muscle Map'),
        const SizedBox(height: AppSpacing.md),
        // M34 Task 1: explicit avatar rebuild trigger on every tamagotchi
        // mutation, instead of relying solely on the map's internal listener.
        ListenableBuilder(
          listenable: tamagotchi,
          builder: (context, _) {
            return MuscleGroupVisualizer(
              tamagotchiState: tamagotchi,
              bodyWidthFactor: bodyWidthFactor,
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                key: const Key('quick_add_button'),
                label: 'Quick Add',
                onPressed: onQuickAdd,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                label: 'Simulate Workout (Core)',
                onPressed: onSimulateWorkout,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: CustomButton(
                label: 'Simulate Meal (650 kcal)',
                onPressed: onSimulateMeal,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        const AppHeading('Exercises'),
        const SizedBox(height: AppSpacing.md),
        if (exercises.isEmpty)
          const AppText('Select a day to view exercises.')
        else
          for (final exercise in exercises)
            ExerciseCard(
              exercise: exercise,
              isHighlighted: provider.selectedMuscleRegion != null &&
                  muscleGroupToRegion[exercise.muscleGroup] ==
                      provider.selectedMuscleRegion,
              isLogged: provider.isExerciseLogged(exercise.name),
              onLog: () {
                provider.toggleExerciseLog(exercise.name);
                if (provider.isExerciseLogged(exercise.name)) {
                  final regionId = muscleGroupToRegion[exercise.muscleGroup];
                  final group = regionId == null
                      ? null
                      : tamagotchiGroupForRegion(regionId);
                  if (group != null) {
                    tamagotchi.applyGrowth([group]);
                  }
                  tamagotchi.applySlimming();
                }
              },
              onTap: () {
                final regionId = muscleGroupToRegion[exercise.muscleGroup];
                if (regionId != null) {
                  provider.selectMuscleRegion(regionId);
                }
                tamagotchi.setOverrides(
                  ExerciseMuscleMapper.getColorsForExercise(exercise.name),
                );
              },
            ),
        const SizedBox(height: AppSpacing.xxl),
        const AppHeading('Weekly Routines'),
        const SizedBox(height: AppSpacing.md),
        const SizedBox.shrink(),
        const SizedBox(height: AppSpacing.xxl),
        const AppHeading('Daily Menus'),
        const SizedBox(height: AppSpacing.md),
        DailyMenuList(menus: menus),
      ],
    );
  }
}
