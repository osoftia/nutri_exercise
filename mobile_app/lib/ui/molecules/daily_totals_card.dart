import 'package:flutter/material.dart';

import '../../core/state/daily_nutrition_state.dart';
import '../../core/theme/app_theme.dart';

/// A compact summary card showing today's accumulated Calories, Protein and Fat
/// totals, driven by a shared [DailyNutritionState].
class DailyTotalsCard extends StatelessWidget {
  const DailyTotalsCard({super.key, required this.state});

  final DailyNutritionState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return Row(
          children: [
          Expanded(
            child: _Total(
              key: const Key('daily_calories_total'),
              title: 'Calories',
              label: AppColors.accent,
              value: '${state.calories} kcal',
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _Total(
              key: const Key('daily_protein_total'),
              title: 'Protein',
              label: AppColors.primary400,
              value: '${state.protein} g',
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _Total(
              key: const Key('daily_fat_total'),
              title: 'Fat',
              label: AppColors.success,
              value: '${state.fat} g',
            ),
          ),
          ],
        );
      },
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({
    super.key,
    required this.title,
    required this.label,
    required this.value,
  });

  final String title;
  final Color label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: label, shape: BoxShape.circle),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
