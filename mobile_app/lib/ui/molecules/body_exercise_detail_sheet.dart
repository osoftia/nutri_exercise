import 'package:flutter/material.dart';

import '../../core/domain/body_projection/body_segment.dart';
import '../../core/domain/body_projection/muscle_workout_log.dart';
import '../../core/domain/i18n/app_strings.dart';
import '../../core/domain/i18n/localization_scope.dart';
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
              final strings = LocalizationScope.stringsOf(context);
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
                        ? strings.noPlanForMuscle
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
                    AppText(
                      strings.noExercisesPlanned,
                      key: const Key('exercise_empty_state'),
                    )
                  else ...[
                    for (final entry in log.entries)
                      _ExerciseTile(entry: entry, strings: strings),
                    const SizedBox(height: AppSpacing.sm),
                    _ProgressRow(
                      key: const Key('exercise_progress_row'),
                      log: log,
                      strings: strings,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _SuggestionSection(
                    controller: controller,
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

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.entry, required this.strings});

  final MuscleExerciseLog entry;
  final AppStrings strings;

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
          AppText(
            entry.isCompleted
                ? strings.setsOfPlanned(entry.completedSets, entry.plannedSets)
                : strings.setsProgress(
                    entry.completedSets,
                    entry.plannedSets,
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({super.key, required this.log, required this.strings});

  final MuscleWorkoutLog log;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(strings.completedVsPlanned),
          AppText(
            strings.volumeOfPlanned(
              log.completedVolume.toStringAsFixed(0),
              log.plannedVolume.toStringAsFixed(0),
            ),
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
  const _SuggestionSection({required this.controller, required this.strings});

  final BodyDetailController controller;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('body_ai_suggestion'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(strings.aiSuggestionLabel),
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
