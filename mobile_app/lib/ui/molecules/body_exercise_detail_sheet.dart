import 'package:flutter/material.dart';

import '../../core/domain/body_projection/body_segment.dart';
import '../../core/domain/body_projection/muscle_workout_log.dart';
import '../../core/state/body_detail_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/typography.dart';

/// Draggable blueprint sheet listing a muscle group's planned and completed
/// exercises plus the local AI's suggestion to close the gap.
class BodyExerciseDetailSheet extends StatefulWidget {
  /// Creates the exercise sheet for [segment].
  const BodyExerciseDetailSheet({
    super.key,
    required this.controller,
    required this.segment,
  });

  /// The shared detail controller.
  final BodyDetailController controller;

  /// The muscle segment being inspected.
  final BodySegment segment;

  @override
  State<BodyExerciseDetailSheet> createState() =>
      _BodyExerciseDetailSheetState();
}

class _BodyExerciseDetailSheetState extends State<BodyExerciseDetailSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.controller.loadWorkout(widget.segment);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          key: const Key('body_exercise_sheet'),
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
            listenable: widget.controller,
            builder: (context, _) {
              final controller = widget.controller;
              final log = controller.workoutLog;
              return ListView(
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
                  AppHeading(
                    widget.segment.name,
                    size: AppHeadingSize.h3,
                  ),
                  AppCaption(
                    log == null || log.isEmpty
                        ? 'No plan for this muscle yet'
                        : log.periodLabel,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (controller.isLoadingWorkout && log == null)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.lg),
                        child: CircularProgressIndicator(
                          key: Key('exercise_loading'),
                        ),
                      ),
                    )
                  else if (controller.workoutError != null && log == null)
                    AppText(controller.workoutError!)
                  else if (log == null || log.isEmpty)
                    const AppText(
                      'No exercises planned for this muscle group.',
                      key: Key('exercise_empty_state'),
                    )
                  else ...[
                    for (final entry in log.entries) _ExerciseTile(entry: entry),
                    const SizedBox(height: AppSpacing.sm),
                    _ProgressRow(key: const Key('exercise_progress_row'), log: log),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _SuggestionSection(controller: controller),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.entry});

  final MuscleExerciseLog entry;

  @override
  Widget build(BuildContext context) {
    final load = entry.loadKg == entry.loadKg.roundToDouble()
        ? entry.loadKg.toInt().toString()
        : entry.loadKg.toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(entry.name),
                AppCaption(
                  '${entry.plannedSets}×${entry.reps} · ${load}kg',
                ),
              ],
            ),
          ),
          AppText(entry.isCompleted ? '✓ ${entry.completedSets}/${entry.plannedSets} sets' : '${entry.completedSets} / ${entry.plannedSets} sets'),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({super.key, required this.log});

  final MuscleWorkoutLog log;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const AppText('Completed vs planned'),
          AppText(
            '${log.completedVolume.toStringAsFixed(0)} / '
            '${log.plannedVolume.toStringAsFixed(0)} kg',
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

class _SuggestionSection extends StatelessWidget {
  const _SuggestionSection({required this.controller});

  final BodyDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('body_ai_suggestion'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText('AI suggestion'),
        const SizedBox(height: AppSpacing.sm),
        if (controller.isLoadingSuggestion)
          const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              key: Key('suggestion_loading'),
              strokeWidth: 2,
            ),
          )
        else
          AppText(
            controller.suggestion ?? '—',
            style: const TextStyle(color: AppColors.textMedium),
          ),
      ],
    );
  }
}
