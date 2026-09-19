import 'package:flutter/material.dart';

import '../../core/data/daily_entry_repository.dart';
import '../../core/models/food_entry.dart';
import '../../core/services/notification_service.dart';
import '../../core/state/body_detail_controller.dart';
import '../../core/state/nutrition_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/custom_button.dart';
import '../atoms/dynamic_avatar.dart';
import '../atoms/neumorphic_bar_chart.dart';
import '../atoms/neumorphic_circular_progress.dart';
import '../atoms/neumorphic_container.dart';
import '../atoms/typography.dart';
import '../molecules/body_segment_sheet.dart';
import '../organisms/calendar_history_dialog.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({
    super.key,
    required this.controller,
    this.dailyEntryRepository,
    this.notificationService,
    this.bodyDetailController,
  });

  final NutritionController controller;

  /// Optional SQLite-backed history; enables the Calendar History button.
  final DailyEntryRepository? dailyEntryRepository;

  /// Optional notification service; enables reactive meal notifications.
  final NotificationService? notificationService;

  /// Optional blueprint controller; enables the daily nutrition action button.
  final BodyDetailController? bodyDetailController;

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  bool _reactiveEnabled = true;

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
    _logFood(FoodEntry(name: name, calories: calories));
    _nameController.clear();
    _caloriesController.clear();
  }

  /// Logs [entry] and, when reactive notifications are enabled, fires an
  /// immediate meal-logged notification.
  void _logFood(FoodEntry entry) {
    widget.controller.logFood(entry);
    _maybeNotifyReactive();
  }

  Future<void> _maybeNotifyReactive() async {
    final service = widget.notificationService;
    final repository = widget.dailyEntryRepository;
    if (!_reactiveEnabled || service == null || repository == null) return;
    await service.showReactiveMealNotification(
      repository: repository,
      recovered: widget.controller.consumedCalories,
    );
  }

  Future<void> _testNotifications() async {
    final service = widget.notificationService;
    final repository = widget.dailyEntryRepository;
    if (service == null || repository == null) return;
    await service.showReactiveMealNotification(
      repository: repository,
      recovered: widget.controller.consumedCalories,
    );
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AppHeading('Nutrition', size: AppHeadingSize.h2),
                if (widget.dailyEntryRepository != null)
                  CustomButton(
                    key: const Key('history_button'),
                    label: 'History',
                    variant: CustomButtonVariant.ghost,
                    onPressed: () => showCalendarHistoryDialog(
                      context,
                      repository: widget.dailyEntryRepository!,
                    ),
                  ),
              ],
            ),
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
            if (widget.notificationService != null &&
                widget.dailyEntryRepository != null) ...[
              NeumorphicContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SwitchListTile(
                      key: const Key('reactive_notifications_toggle'),
                      title: const AppText('Reactive meal notifications'),
                      subtitle: const AppCaption(
                        'Notify right after logging a meal',
                      ),
                      value: _reactiveEnabled,
                      onChanged: (value) =>
                          setState(() => _reactiveEnabled = value),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: AppSpacing.md,
                        right: AppSpacing.md,
                        bottom: AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomButton(
                            key: const Key('exercise_not_button'),
                            label: 'EXERCISE NOT',
                            variant: CustomButtonVariant.ghost,
                            onPressed: () =>
                                widget.notificationService
                                    ?.showExerciseReminderTest(),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          CustomButton(
                            key: const Key('test_notifications_button'),
                            label: 'Test Notifications',
                            variant: CustomButtonVariant.ghost,
                            onPressed: _testNotifications,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            NeumorphicContainer(
              child: DynamicAvatar(morph: c.morphFactor),
            ),
            if (widget.bodyDetailController != null) ...[
              const SizedBox(height: AppSpacing.lg),
              CustomButton(
                key: const Key('nutrition_action_button'),
                label: 'Daily nutrition summary',
                onPressed: () => showNutritionSummarySheet(
                  context,
                  controller: widget.bodyDetailController!,
                ),
              ),
            ],
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
                    onPressed: () => _logFood(entry),
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
