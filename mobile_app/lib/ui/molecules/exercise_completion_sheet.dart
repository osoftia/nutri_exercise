import 'package:flutter/material.dart';

import '../../core/domain/popups/exercise_completion.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/custom_button.dart';
import '../atoms/typography.dart';

/// Opens the post-workout completion summary as a draggable modal sheet.
Future<void> showExerciseCompletionSheet(
  BuildContext context,
  ExerciseCompletionSummary summary,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ExerciseCompletionSheet(summary: summary),
  );
}

/// Draggable sheet summarising a confirmed workout: exercises and sets,
/// calories burned, and the updated muscle recovery statuses.
class ExerciseCompletionSheet extends StatelessWidget {
  /// Creates the completion sheet for [summary].
  const ExerciseCompletionSheet({
    super.key,
    required this.summary,
    this.onClose,
  });

  /// The confirmed workout summary.
  final ExerciseCompletionSummary summary;

  /// Optional close callback (defaults to popping the route).
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          key: const Key('exercise_completion_sheet'),
          decoration: const BoxDecoration(
            color: AppColors.surface900,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
            border: Border(
              top: BorderSide(color: AppColors.success, width: 1),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              const Center(
                child: SizedBox(
                  width: 40,
                  height: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: AppColors.surface700),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const AppHeading('Workout Complete', size: AppHeadingSize.h3),
              AppCaption(
                summary.isEmpty
                    ? 'Nothing logged yet'
                    : '${summary.totalSets} sets · ${summary.totalReps} reps',
              ),
              const SizedBox(height: AppSpacing.lg),
              if (summary.isEmpty)
                const AppText(
                  'No exercises were completed for this check-in.',
                  key: Key('exercise_completion_empty'),
                )
              else
                for (var i = 0; i < summary.exercises.length; i++)
                  _ExerciseRow(
                    key: Key('completion_exercise_$i'),
                    exercise: summary.exercises[i],
                  ),
              const SizedBox(height: AppSpacing.md),
              _BurnedRow(calories: summary.caloriesBurned),
              const SizedBox(height: AppSpacing.md),
              if (summary.recovery.isNotEmpty)
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final entry in summary.recovery.entries)
                      _RecoveryChip(
                        key: Key('recovery_${entry.key}'),
                        region: entry.key,
                        level: entry.value,
                      ),
                  ],
                ),
              const SizedBox(height: AppSpacing.lg),
              CustomButton(
                key: const Key('exercise_completion_close'),
                label: 'Done',
                onPressed:
                    onClose ?? () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({super.key, required this.exercise});

  final CompletedExercise exercise;

  @override
  Widget build(BuildContext context) {
    final load = exercise.loadKg == exercise.loadKg.roundToDouble()
        ? exercise.loadKg.toInt().toString()
        : exercise.loadKg.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(exercise.name),
                AppCaption(
                  '${exercise.completedSets}/${exercise.plannedSets} × '
                  '${exercise.reps} · ${load}kg',
                ),
              ],
            ),
          ),
          Icon(
            exercise.isComplete ? Icons.check_circle : Icons.timelapse,
            color: exercise.isComplete
                ? AppColors.success
                : AppColors.warning,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _BurnedRow extends StatelessWidget {
  const _BurnedRow({required this.calories});

  final int calories;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const Key('burned_calories_row'),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const AppText('Calories burned'),
        AppText(
          '$calories kcal',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

class _RecoveryChip extends StatelessWidget {
  const _RecoveryChip({
    super.key,
    required this.region,
    required this.level,
  });

  final String region;
  final RecoveryLevel level;

  @override
  Widget build(BuildContext context) {
    final color = switch (level) {
      RecoveryLevel.recovered => AppColors.success,
      RecoveryLevel.recovering => AppColors.warning,
      RecoveryLevel.fatigued => AppColors.danger,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color),
      ),
      child: Text(
        '${region.toUpperCase()} · ${level.name.toUpperCase()}',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: color,
        ),
      ),
    );
  }
}
