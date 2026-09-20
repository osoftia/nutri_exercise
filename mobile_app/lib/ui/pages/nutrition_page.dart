import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/data/daily_entry_repository.dart';
import '../../core/domain/body_projection/body_diagram_view_model.dart';
import '../../core/domain/body_projection/nutrition_body_view_model.dart';
import '../../core/domain/body_projection/nutrition_log.dart';
import '../../core/domain/i18n/app_strings.dart';
import '../../core/domain/i18n/localization_scope.dart';
import '../../core/domain/nutrition/portion_scaler.dart';
import '../../core/models/food_entry.dart';
import '../../core/services/notification_service.dart';
import '../../core/state/body_detail_controller.dart';
import '../../core/state/nutrition_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/custom_button.dart';
import '../atoms/neumorphic_bar_chart.dart';
import '../atoms/neumorphic_circular_progress.dart';
import '../atoms/neumorphic_container.dart';
import '../atoms/typography.dart';
import '../molecules/blueprint_action_rail.dart';
import '../molecules/body_segment_sheet.dart';
import '../molecules/quick_add_grams_dialog.dart';
import '../organisms/body_blueprint/unified_body_blueprint.dart';
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

  /// Localized label for a preset quick-add, keyed by its canonical name.
  static String _quickAddLabel(AppStrings strings, FoodEntry entry) =>
      switch (entry.name) {
        'Oatmeal & Berries' => strings.quickAddOatmealBerries,
        'Grilled Chicken Bowl' => strings.quickAddGrilledChickenBowl,
        'Salmon & Quinoa' => strings.quickAddSalmonQuinoa,
        'Greek Yogurt & Almonds' => strings.quickAddGreekYogurtAlmonds,
        'Protein Shake' => strings.quickAddProteinShake,
        _ => entry.name,
      };

  /// Intercepts a preset quick-add: asks for the portion in grams (default
  /// 100 g) and logs the proportionally scaled entry.
  Future<void> _addQuick(FoodEntry entry) async {
    final grams = await showQuickAddGramsDialog(context, food: entry);
    if (grams == null || !mounted) return;
    _logFood(PortionScaler.scaleFood(entry, grams), grams: grams);
  }

  /// Logs [entry] and, when reactive notifications are enabled, fires an
  /// immediate meal-logged notification.
  ///
  /// When [grams] is provided the entry is mirrored onto the shared body-detail
  /// log so the blueprint abdomen status colour and the Tamagotchi stomach mass
  /// react to the actual portion on the same frame.
  void _logFood(FoodEntry entry, {double? grams}) {
    widget.controller.logFood(entry);
    final detail = widget.bodyDetailController;
    if (detail != null) {
      unawaited(
        detail.addFood(
          LoggedFood(
            name: entry.name,
            portion: grams == null ? '1 serving' : _formatGrams(grams),
            calories: entry.calories,
            proteinG: entry.proteinG,
            carbsG: entry.carbsG,
            fatG: entry.fatG,
            time: _nowHHmm(),
          ),
        ),
      );
    }
    _maybeNotifyReactive();
  }

  static String _formatGrams(double grams) => grams == grams.roundToDouble()
      ? '${grams.toInt()} g'
      : '${grams.toStringAsFixed(1)} g';

  static String _nowHHmm() {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(now.hour)}:${two(now.minute)}';
  }

  /// The shared blueprint snapshot: the live body-detail state when available
  /// (so the abdomen colour tracks logged food), otherwise a calorie-derived
  /// snapshot so the figure still responds to the day's intake.
  BodyDiagramViewModel _blueprintViewModel(NutritionController c) {
    final detail = widget.bodyDetailController;
    if (detail != null) return detail.buildViewModel();
    return nutritionBodyViewModel(
      morph: c.morphFactor,
      calorieRatio: c.calorieRatio,
    );
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
        final strings = LocalizationScope.stringsOf(context);
        final macroTargets = c.macroTargets;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            AppHeading(strings.nutritionTitle, size: AppHeadingSize.h2),
            const SizedBox(height: AppSpacing.lg),
            NeumorphicContainer(
              child: Row(
                key: const Key('calorie_summary'),
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(strings.calorieLabel),
                  AppText(
                    strings.caloriesOfTarget(
                      c.consumedCalories,
                      c.targetCalories,
                    ),
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
                      title: AppText(strings.reactiveNotificationsTitle),
                      subtitle: AppCaption(
                        strings.reactiveNotificationsSubtitle,
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
                            label: strings.exerciseNotButton,
                            variant: CustomButtonVariant.ghost,
                            onPressed: () =>
                                widget.notificationService
                                    ?.showExerciseReminderTest(),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          CustomButton(
                            key: const Key('test_notifications_button'),
                            label: strings.testNotificationsButton,
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
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 260,
                      child: UnifiedBodyBlueprint(
                        viewModel: _blueprintViewModel(c),
                        showCallouts: false,
                        onSegmentSelected: widget.bodyDetailController == null
                            ? null
                            : (segment) => showBodySegmentDetailSheet(
                                  context,
                                  segment: segment,
                                  controller: widget.bodyDetailController!,
                                ),
                      ),
                    ),
                  ),
                  if (widget.dailyEntryRepository != null ||
                      widget.bodyDetailController != null)
                    BlueprintActionRail(
                      showHistory: widget.dailyEntryRepository != null,
                      historyKey: const Key('nutrition_history_fab'),
                      historyTooltip: 'History',
                      onHistory: widget.dailyEntryRepository == null
                          ? null
                          : () => showCalendarHistoryDialog(
                                context,
                                repository: widget.dailyEntryRepository!,
                              ),
                      summaryKey: const Key('nutrition_action_button'),
                      summaryTooltip: 'Daily Nutrition Summary',
                      summaryIcon: Icons.restaurant_menu,
                      onSummary: widget.bodyDetailController == null
                          ? null
                          : () => showNutritionSummarySheet(
                                context,
                                controller: widget.bodyDetailController!,
                              ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: NeumorphicCircularProgress(
                    title: strings.proteinLabel,
                    progress: c.proteinProgress,
                    valueLabel: strings.macroOfTarget(
                      c.proteinG,
                      macroTargets.protein,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: NeumorphicCircularProgress(
                    title: strings.carbsLabel,
                    progress: c.carbsProgress,
                    valueLabel: strings.macroOfTarget(
                      c.carbsG,
                      macroTargets.carbs,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: NeumorphicCircularProgress(
                    title: strings.fatLabel,
                    progress: c.fatProgress,
                    valueLabel: strings.macroOfTarget(
                      c.fatG,
                      macroTargets.fat,
                    ),
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
                  AppText(strings.weeklyCaloriesTitle),
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
            AppText(strings.quickAddTitle),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final entry in _quickAdds)
                  CustomButton(
                    key: Key('quick_add_${entry.name}'),
                    label: _quickAddLabel(strings, entry),
                    variant: CustomButtonVariant.ghost,
                    onPressed: () => _addQuick(entry),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            NeumorphicContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(strings.logAMealTitle),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    key: const Key('food_name_field'),
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: strings.nameFieldLabel,
                      hintText: strings.nameFieldHint,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    key: const Key('food_calories_field'),
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: strings.caloriesFieldLabel,
                      hintText: strings.caloriesFieldHint,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomButton(
                    key: const Key('food_add_button'),
                    label: strings.add,
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
