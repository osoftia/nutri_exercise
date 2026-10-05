import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/data/daily_entry_repository.dart';
import '../../core/domain/body_projection/body_diagram_view_model.dart';
import '../../core/domain/body_projection/nutrition_body_view_model.dart';
import '../../core/domain/body_projection/nutrition_log.dart';
import '../../core/domain/i18n/localization_scope.dart';
import '../../core/domain/nutrition/portion_scaler.dart';
import '../../core/models/daily_entry.dart';
import '../../core/models/food_entry.dart';
import '../../core/services/notification_service.dart';
import '../../core/state/body_detail_controller.dart';
import '../../core/state/clinical_profile_controller.dart';
import '../../core/state/nutrition_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/custom_button.dart';
import '../atoms/neumorphic_bar_chart.dart';
import '../atoms/neumorphic_circular_progress.dart';
import '../atoms/neumorphic_container.dart';
import '../atoms/typography.dart';
import '../molecules/blueprint_action_rail.dart';
import '../molecules/body_segment_sheet.dart';
import '../molecules/clinical_food_search_panel.dart';
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
    this.clinicalProfileController,
  });

  final NutritionController controller;

  /// Optional SQLite-backed history; enables the Calendar History button.
  final DailyEntryRepository? dailyEntryRepository;

  /// Optional notification service; enables reactive meal notifications.
  final NotificationService? notificationService;

  /// Optional blueprint controller; enables the daily nutrition action button.
  final BodyDetailController? bodyDetailController;

  /// Optional reactive clinical condition profile for food safety guidance.
  final ClinicalProfileController? clinicalProfileController;

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.load();
    widget.clinicalProfileController?.load();
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

  /// Intercepts a preset quick-add: asks for the portion in grams (default
  /// 100 g) and logs the proportionally scaled entry.
  Future<void> _addQuick(FoodEntry entry) async {
    final grams = await showQuickAddGramsDialog(
      context,
      food: entry,
      clinicalProfileController: widget.clinicalProfileController,
    );
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
    // Persist the consumed calories/macros to the shared daily entry so the
    // Weekly Stats and calendar reflect food logged from the Nutrition tab.
    unawaited(_persistNutrition(entry));
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
            saturatedFatG: entry.saturatedFatG,
            sugarsG: entry.sugarsG,
            fiberG: entry.fiberG,
            glycemicIndex: entry.glycemicIndex,
            purinesMg: entry.purinesMg,
            sodiumMg: entry.sodiumMg,
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

  /// Adds [entry]'s calories and macros onto today's persisted [DailyEntry].
  ///
  /// The daily entry stores the day's running totals, so multiple logs on the
  /// same day accumulate instead of overwriting one another.
  Future<void> _persistNutrition(FoodEntry entry) async {
    final repository = widget.dailyEntryRepository;
    if (repository == null) return;
    final today = DailyEntry.dateKey(DateTime.now());
    final existing =
        await repository.getByDate(today) ?? DailyEntry(date: today);
    await repository.save(
      existing.copyWith(
        calories: existing.calories + entry.calories,
        protein: existing.protein + entry.proteinG,
        carbs: existing.carbs + entry.carbsG,
        fat: existing.fat + entry.fatG,
      ),
    );
  }

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

  /// Fires the reactive meal notification after a food log.
  ///
  /// The reactive toggle and test triggers moved to the Profile "Pruebas"
  /// section (M47 Task 3); logging a meal still triggers the notification.
  Future<void> _maybeNotifyReactive() async {
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
    final clinicalController = widget.clinicalProfileController;
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        final strings = LocalizationScope.stringsOf(context);
        final macroTargets = c.macroTargets;
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.pageBottom,
          ),
          children: [
            AppHeading(strings.nutritionTitle, size: AppHeadingSize.h2),
            const SizedBox(height: AppSpacing.section),
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
            const SizedBox(height: AppSpacing.section),
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
                                  clinicalProfileController: clinicalController,
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
                                clinicalProfileController: clinicalController,
                              ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.section),
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
            const SizedBox(height: AppSpacing.section),
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
            const SizedBox(height: AppSpacing.section),
            ClinicalFoodSearchPanel(
              controller: clinicalController,
              onAdd: _addQuick,
            ),
            const SizedBox(height: AppSpacing.section),
            NeumorphicContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(strings.logAMealShortTitle),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    key: const Key('food_name_field'),
                    controller: _nameController,
                    decoration: AppInputDecoration.rounded(
                      label: strings.nameFieldLabel,
                      hint: strings.nameFieldHint,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    key: const Key('food_calories_field'),
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    decoration: AppInputDecoration.rounded(
                      label: strings.caloriesFieldLabel,
                      hint: strings.caloriesFieldHint,
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
