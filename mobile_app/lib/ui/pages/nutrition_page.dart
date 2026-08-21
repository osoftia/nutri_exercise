import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../atoms/neumorphic_container.dart';
import '../atoms/typography.dart';

class NutritionPage extends StatelessWidget {
  const NutritionPage({super.key});

  static const List<({String meal, String name, int calories})> _mockPlan = [
    (meal: 'Breakfast', name: 'Oatmeal & Berries', calories: 420),
    (meal: 'Lunch', name: 'Grilled Chicken Bowl', calories: 650),
    (meal: 'Dinner', name: 'Salmon & Quinoa', calories: 580),
    (meal: 'Snack', name: 'Greek Yogurt & Almonds', calories: 240),
  ];

  @override
  Widget build(BuildContext context) {
    final totalCalories = _mockPlan.fold<int>(
      0,
      (sum, meal) => sum + meal.calories,
    );

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const AppHeading('Nutrition', size: AppHeadingSize.h2),
        const SizedBox(height: AppSpacing.lg),
        NeumorphicContainer(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText('Daily Plan'),
              AppText('$totalCalories kcal'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final meal in _mockPlan)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: NeumorphicContainer(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: AppText(meal.name),
                subtitle: AppCaption(meal.meal),
                trailing: AppText('${meal.calories} kcal'),
              ),
            ),
          ),
      ],
    );
  }
}