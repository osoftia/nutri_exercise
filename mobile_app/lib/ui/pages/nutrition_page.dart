import 'package:flutter/material.dart';

import '../../core/models/food_entry.dart';
import '../../core/state/nutrition_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/custom_button.dart';
import '../atoms/dynamic_avatar.dart';
import '../atoms/neumorphic_bar_chart.dart';
import '../atoms/neumorphic_circular_progress.dart';
import '../atoms/neumorphic_container.dart';
import '../atoms/typography.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key, required this.controller});

  final NutritionController controller;

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();

  static const List<FoodEntry> _quickAdds = [
    FoodEntry(
      name: 'Oatmeal & Berries',
      calories: 420,
      proteinG: 10,
      carbsG: 60,
      fatG: 12,
    ),
    FoodEntry(
      name: 'Grilled Chicken Bowl',
      calories: 650,
      proteinG: 45,
      carbsG: 55,
      fatG: 18,
    ),
    FoodEntry(
      name: 'Salmon & Quinoa',
      calories: 580,
      proteinG: 35,
      carbsG: 45,
      fatG: 22,
    ),
    FoodEntry(
      name: 'Greek Yogurt & Almonds',
      calories: 240,
      proteinG: 18,
      carbsG: 18,
      fatG: 10,
    ),
    FoodEntry(
      name: 'Protein Shake',
      calories: 150,
      proteinG: 30,
      carbsG: 6,
      fatG: 1,
    ),
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _addCustomEntry() {
    final name = _nameController.text.trim();
    final calories = int.tryParse(_caloriesController.text.trim());
    if (name.isEmpty || calories == null) return;
    widget.controller.logFood(FoodEntry(name: name, calories: calories));
    _nameController.clear();
    _caloriesController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        final macroTargets = c.macroTargets;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const AppHeading('Nutrition', size: AppHeadingSize.h2),
            const SizedBox(height: AppSpacing.lg),
            NeumorphicContainer(
              child: Row(
                key: const Key('calorie_summary'),
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppText('Calories'),
                  AppText(
                    '${c.consumedCalories} of ${c.targetCalories} kcal',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            NeumorphicContainer(
              child: DynamicAvatar(morph: c.morphFactor),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: NeumorphicCircularProgress(
                    title: 'Protein',
                    progress: c.proteinProgress,
                    valueLabel:
                        '${c.proteinG} / ${macroTargets.protein}g',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: NeumorphicCircularProgress(
                    title: 'Carbs',
                    progress: c.carbsProgress,
                    valueLabel: '${c.carbsG} / ${macroTargets.carbs}g',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: NeumorphicCircularProgress(
                    title: 'Fat',
                    progress: c.fatProgress,
                    valueLabel: '${c.fatG} / ${macroTargets.fat}g',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            NeumorphicContainer(
              key: const Key('weekly_bar_chart'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText('Weekly Calories'),
                  const SizedBox(height: AppSpacing.md),
                  NeumorphicBarChart(
                    values: c.weeklyCalories,
                    labels: const [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun',
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const AppText('Quick Add'),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final entry in _quickAdds)
                  CustomButton(
                    key: Key('quick_add_${entry.name}'),
                    label: entry.name,
                    variant: CustomButtonVariant.ghost,
                    onPressed: () => widget.controller.logFood(entry),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            NeumorphicContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText('Log a meal'),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    key: const Key('food_name_field'),
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'e.g. Banana',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    key: const Key('food_calories_field'),
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Calories',
                      hintText: 'e.g. 120',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomButton(
                    key: const Key('food_add_button'),
                    label: 'Add',
                    onPressed: _addCustomEntry,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
