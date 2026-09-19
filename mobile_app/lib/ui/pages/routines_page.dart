import 'package:flutter/material.dart';

import '../../core/state/body_detail_controller.dart';
import '../../core/state/projection_controller.dart';
import '../../core/state/workout_completion_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/neumorphic_container.dart';
import '../atoms/neumorphic_timeline.dart';
import '../atoms/typography.dart';
import '../molecules/body_segment_sheet.dart';
import '../molecules/exercise_completion_sheet.dart';
import '../organisms/body_blueprint/body_blueprint_diagram.dart';

/// Routines tab: the blueprint Body Projection card plus the weekly plan.
///
/// The diagram's selection callback is wired to the shared
/// [BodyDetailController] and opens the matching food / exercise detail sheet.
class RoutinesPage extends StatefulWidget {
  /// Creates the Routines tab.
  const RoutinesPage({
    super.key,
    required this.controller,
    required this.detailController,
    this.workoutCompletionController,
  });

  /// Owns the long-term projection plan and selected milestone.
  final ProjectionController controller;

  /// Owns the blueprint data and its detail popups.
  final BodyDetailController detailController;

  /// Optional workout completion controller; enables the check-in button.
  final WorkoutCompletionController? workoutCompletionController;

  @override
  State<RoutinesPage> createState() => _RoutinesPageState();
}

class _RoutinesPageState extends State<RoutinesPage> {
  static const List<({String weekday, String focus, String exercises})>
      _mockRoutines = [
    (
      weekday: 'Monday',
      focus: 'Push Day',
      exercises: 'Chest · Shoulders · Triceps',
    ),
    (weekday: 'Wednesday', focus: 'Pull Day', exercises: 'Back · Biceps'),
    (
      weekday: 'Friday',
      focus: 'Leg Day',
      exercises: 'Quads · Hamstrings · Glutes',
    ),
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onProjectionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.controller.load();
      widget.detailController.loadOverview();
      widget.workoutCompletionController?.restore();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onProjectionChanged);
    super.dispose();
  }

  /// Forwards the selected milestone to the forecaster behind the controller.
  void _onProjectionChanged() {
    final milestone = widget.controller.selectedMilestone;
    if (milestone == null) return;
    widget.detailController.applyProjection(
      month: widget.controller.selectedMonth,
      shoulderFactor: milestone.shoulderFactor,
      waistFactor: milestone.waistFactor,
    );
  }

  /// Confirms or reverses the workout when the toggle changes.
  Future<void> _toggleWorkout(bool value) async {
    final completion = widget.workoutCompletionController;
    if (completion == null) return;

    if (value) {
      await completion.confirm(widget.detailController.plannedExercises());
      await widget.detailController.refreshWorkouts();
      final summary = completion.summary;
      if (!mounted || summary == null) return;
      await showExerciseCompletionSheet(context, summary);
    } else {
      await completion.undo();
      await widget.detailController.refreshWorkouts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final completion = widget.workoutCompletionController;
    final listenable = completion == null
        ? Listenable.merge([widget.controller, widget.detailController])
        : Listenable.merge([
            widget.controller,
            widget.detailController,
            completion,
          ]);
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        final controller = widget.controller;
        final milestone = controller.selectedMilestone;
        final viewModel = widget.detailController.buildViewModel();

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const AppHeading('Routines', size: AppHeadingSize.h2),
            const SizedBox(height: AppSpacing.lg),
            NeumorphicContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppText('Body Projection'),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 320,
                    width: double.infinity,
                    child: BodyBlueprintDiagram(
                      viewModel: viewModel,
                      onSegmentSelected: (segment) =>
                          showBodySegmentDetailSheet(
                        context,
                        segment: segment,
                        controller: widget.detailController,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  NeumorphicTimeline(
                    selectedMonth: controller.selectedMonth,
                    onSelected: controller.selectMonth,
                  ),
                  if (milestone != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppText(
                      '${milestone.weightKg.toStringAsFixed(1)} kg · '
                      '${milestone.focus}',
                      key: const Key('projection_summary'),
                    ),
                  ],
                  if (widget.workoutCompletionController != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SwitchListTile(
                      key: const Key('confirm_workout_toggle'),
                      contentPadding: EdgeInsets.zero,
                      title: const AppText('Workout completed'),
                      subtitle: const AppCaption(
                        'Records today\'s workout and grows your avatar',
                      ),
                      value: widget.workoutCompletionController!.isConfirmed,
                      onChanged: _toggleWorkout,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final routine in _mockRoutines)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: NeumorphicContainer(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: AppText(routine.weekday),
                    subtitle: AppText(routine.focus),
                    trailing: AppCaption(routine.exercises),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
