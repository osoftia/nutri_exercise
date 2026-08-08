import 'package:flutter/material.dart';

import '../../core/models/routine_models.dart';
import '../../core/theme/app_theme.dart';

class RoutineList extends StatelessWidget {
  const RoutineList({super.key, required this.routines});

  final List<WorkoutDay> routines;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [for (final day in routines) _RoutineTile(day: day)],
    );
  }
}

class _RoutineTile extends StatelessWidget {
  const _RoutineTile({required this.day});

  final WorkoutDay day;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(day.weekday, style: textTheme.titleLarge),
                Text(
                  '${day.exercises.length} exercises',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(day.focus, style: textTheme.bodyMedium),
            const Divider(height: AppSpacing.xl, color: AppColors.surface700),
            for (final exercise in day.exercises)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(exercise.name, style: textTheme.bodyMedium),
                    Text(
                      '${exercise.sets}x ${exercise.reps}',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
