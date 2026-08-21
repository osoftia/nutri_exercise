import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../atoms/neumorphic_container.dart';
import '../atoms/typography.dart';

class RoutinesPage extends StatelessWidget {
  const RoutinesPage({super.key});

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
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const AppHeading('Routines', size: AppHeadingSize.h2),
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
  }
}