import 'package:flutter/material.dart';

import '../../core/domain/body_projection/body_segment.dart';
import '../../core/domain/body_projection/muscle_workout_log.dart';
import '../../core/domain/i18n/app_strings.dart';
import '../../core/domain/i18n/localization_scope.dart';
import '../../core/state/body_detail_controller.dart';
import '../../core/state/workout_completion_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/typography.dart';

/// Opens the daily routine summary: today's planned exercises with their
/// completed sets, aggregated across every trained segment.
///
/// When [completion] is supplied, each exercise gains a delete control that
/// removes its completion record and refreshes the blueprint.
Future<void> showRoutineSummarySheet(
  BuildContext context, {
  required BodyDetailController controller,
  WorkoutCompletionController? completion,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RoutineSummarySheet(
      controller: controller,
      completion: completion,
    ),
  );
}

/// Draggable sheet summarising the day's routine.
class RoutineSummarySheet extends StatelessWidget {
  /// Creates the summary sheet for [controller].
  const RoutineSummarySheet({
    super.key,
    required this.controller,
    this.completion,
  });

  /// The shared detail controller owning the workout logs.
  final BodyDetailController controller;

  /// Optional completion controller; enables per-exercise deletion.
  final WorkoutCompletionController? completion;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          key: const Key('routine_summary_sheet'),
          decoration: const BoxDecoration(
            color: AppColors.surface900,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
            border: Border(
              top: BorderSide(color: AppColors.primary500, width: 1),
            ),
          ),
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final strings = LocalizationScope.stringsOf(context);
              final sections = controller.workouts.values
                  .where((workout) => workout.entries.isNotEmpty)
                  .toList(growable: false);
              var planned = 0;
              var completed = 0;
              for (final workout in sections) {
                planned += workout.plannedSets;
                completed += workout.completedSets;
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        const _SheetHandle(),
                        const SizedBox(height: AppSpacing.md),
                        AppHeading(
                          strings.dailyRoutineSummary,
                          size: AppHeadingSize.h3,
                        ),
                        AppCaption(strings.routineSummaryCaption),
                        const SizedBox(height: AppSpacing.lg),
                        if (sections.isEmpty)
                          AppText(
                            strings.noRoutinePlanned,
                            key: const Key('routine_summary_empty'),
                          )
                        else
                          for (final workout in sections)
                            _WorkoutSection(
                              workout: workout,
                              strings: strings,
                              onDelete: completion == null
                                  ? null
                                  : (name) async {
                                      await completion!.removeExercise(name);
                                      await controller.refreshWorkouts();
                                    },
                            ),
                      ],
                    ),
                  ),
                  _SummaryTotals(
                    completed: completed,
                    planned: planned,
                    strings: strings,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.surface700,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _WorkoutSection extends StatelessWidget {
  const _WorkoutSection({
    required this.workout,
    required this.strings,
    this.onDelete,
  });

  final MuscleWorkoutLog workout;
  final AppStrings strings;

  /// Invoked with an exercise name when its delete control is tapped.
  final Future<void> Function(String name)? onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            strings.regionLabel(regionForSegment(workout.segment)),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primary400,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final entry in workout.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(child: AppText(entry.name)),
                  AppCaption(
                    strings.setsRepsLoad(
                      entry.completedSets,
                      entry.plannedSets,
                      entry.reps,
                      _formatLoad(entry.loadKg),
                    ),
                  ),
                  if (onDelete != null)
                    IconButton(
                      key: Key('routine_delete_${entry.name}'),
                      tooltip: strings.removeExerciseTooltip(entry.name),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.danger,
                      ),
                      onPressed: () => onDelete!(entry.name),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _formatLoad(double load) =>
      load == load.roundToDouble() ? load.toInt().toString() : '$load';
}

/// Maps a blueprint [BodySegment] to its structural [BodyRegion] label.
BodyRegion regionForSegment(BodySegment segment) => switch (segment) {
      BodySegment.chest => BodyRegion.chest,
      BodySegment.leftUpperArm || BodySegment.leftForearm => BodyRegion.armLeft,
      BodySegment.rightUpperArm ||
      BodySegment.rightForearm =>
        BodyRegion.armRight,
      BodySegment.leftThigh || BodySegment.leftCalf => BodyRegion.legLeft,
      BodySegment.rightThigh ||
      BodySegment.rightCalf =>
        BodyRegion.legRight,
      BodySegment.abdomen => BodyRegion.core,
      BodySegment.head => BodyRegion.head,
      BodySegment.neck => BodyRegion.neck,
    };

class _SummaryTotals extends StatelessWidget {
  const _SummaryTotals({
    required this.completed,
    required this.planned,
    required this.strings,
  });

  final int completed;
  final int planned;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface800,
        border: Border(top: BorderSide(color: AppColors.surface700)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        key: const Key('routine_summary_total'),
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppCaption(strings.totalSetsLabel),
          AppText(
            strings.completedOfPlanned(completed, planned),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primary400,
            ),
          ),
        ],
      ),
    );
  }
}
