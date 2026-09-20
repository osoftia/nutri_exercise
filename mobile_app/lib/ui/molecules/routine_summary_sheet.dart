import 'package:flutter/material.dart';

import '../../core/domain/body_projection/body_segment.dart';
import '../../core/domain/body_projection/muscle_workout_log.dart';
import '../../core/state/body_detail_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/typography.dart';

/// Opens the daily routine summary: today's planned exercises with their
/// completed sets, aggregated across every trained segment.
Future<void> showRoutineSummarySheet(
  BuildContext context, {
  required BodyDetailController controller,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RoutineSummarySheet(controller: controller),
  );
}

/// Draggable sheet summarising the day's routine.
class RoutineSummarySheet extends StatelessWidget {
  /// Creates the summary sheet for [controller].
  const RoutineSummarySheet({super.key, required this.controller});

  /// The shared detail controller owning the workout logs.
  final BodyDetailController controller;

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
                        const AppHeading(
                          'Daily Routine Summary',
                          size: AppHeadingSize.h3,
                        ),
                        const AppCaption('Planned vs completed sets'),
                        const SizedBox(height: AppSpacing.lg),
                        if (sections.isEmpty)
                          const AppText(
                            'No routine planned for today.',
                            key: Key('routine_summary_empty'),
                          )
                        else
                          for (final workout in sections)
                            _WorkoutSection(workout: workout),
                      ],
                    ),
                  ),
                  _SummaryTotals(
                    completed: completed,
                    planned: planned,
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
  const _WorkoutSection({required this.workout});

  final MuscleWorkoutLog workout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            _labelFor(workout.segment),
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
                    '${entry.completedSets}/${entry.plannedSets} × '
                    '${entry.reps} · ${_formatLoad(entry.loadKg)}kg',
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

  static String _labelFor(BodySegment segment) => switch (segment) {
        BodySegment.chest => 'CHEST',
        BodySegment.leftUpperArm || BodySegment.leftForearm => 'ARM L',
        BodySegment.rightUpperArm || BodySegment.rightForearm => 'ARM R',
        BodySegment.leftThigh || BodySegment.leftCalf => 'LEG L',
        BodySegment.rightThigh || BodySegment.rightCalf => 'LEG R',
        BodySegment.abdomen => 'CORE',
        BodySegment.head => 'HEAD',
        BodySegment.neck => 'NECK',
      };
}

class _SummaryTotals extends StatelessWidget {
  const _SummaryTotals({required this.completed, required this.planned});

  final int completed;
  final int planned;

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
          const AppCaption('Total sets'),
          AppText(
            '$completed / $planned',
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
