import 'package:flutter/material.dart';

import '../../core/state/projection_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/neumorphic_container.dart';
import '../atoms/neumorphic_timeline.dart';
import '../atoms/projection_avatar.dart';
import '../atoms/typography.dart';

class RoutinesPage extends StatefulWidget {
  const RoutinesPage({super.key, required this.controller});

  final ProjectionController controller;

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
    widget.controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        final milestone = c.selectedMilestone;
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
                  ProjectionAvatar(
                    shoulderFactor: c.shoulderFactor,
                    waistFactor: c.waistFactor,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  NeumorphicTimeline(
                    selectedMonth: c.selectedMonth,
                    onSelected: c.selectMonth,
                  ),
                  if (milestone != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppText(
                      '${milestone.weightKg.toStringAsFixed(1)} kg · '
                      '${milestone.focus}',
                      key: const Key('projection_summary'),
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
