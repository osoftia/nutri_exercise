import 'package:flutter/material.dart';

import '../../core/domain/body_projection/nutrition_log.dart';
import '../../core/domain/i18n/app_strings.dart';
import '../../core/domain/i18n/localization_scope.dart';
import '../../core/state/body_detail_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/typography.dart';

/// Draggable blueprint sheet listing today's logged foods with inline delete
/// controls and a sticky total row.
///
/// Management is **deletion-only**: food can be removed (reducing calorie
/// surplus and stomach bloat), while additions stay bound to the preset
/// suggestions or the RAG AI advisor pipeline.
class BodyFoodDetailSheet extends StatefulWidget {
  /// Creates the food sheet for [controller].
  const BodyFoodDetailSheet({super.key, required this.controller});

  /// The shared detail controller.
  final BodyDetailController controller;

  @override
  State<BodyFoodDetailSheet> createState() => _BodyFoodDetailSheetState();
}

class _BodyFoodDetailSheetState extends State<BodyFoodDetailSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Only hydrate from the repository when the shared controller has not
      // loaded yet; otherwise keep the live in-memory log so a just-added food
      // is never clobbered by a stale read.
      if (!widget.controller.foodLogLoaded) widget.controller.loadFoodLog();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          key: const Key('body_food_sheet'),
          decoration: const BoxDecoration(
            color: AppColors.surface900,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
            border: Border(
              top: BorderSide(color: AppColors.primary500, width: 1),
            ),
          ),
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              final strings = LocalizationScope.stringsOf(context);
              final controller = widget.controller;
              final log = controller.foodLog;
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        const _SheetHandle(),
                        const SizedBox(height: AppSpacing.md),
                        AppHeading(
                          strings.stomachTitle,
                          size: AppHeadingSize.h3,
                        ),
                        AppCaption(strings.foodLoggedToday),
                        const SizedBox(height: AppSpacing.lg),
                        if (controller.isLoadingFood && log.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.lg),
                              child: CircularProgressIndicator(
                                key: Key('food_loading'),
                              ),
                            ),
                          )
                        else if (controller.foodError != null && log.isEmpty)
                          AppText(controller.foodError!)
                        else if (log.isEmpty)
                          AppText(
                            strings.noFoodLoggedToday,
                            key: const Key('food_empty_state'),
                          )
                        else
                          for (var i = 0; i < log.entries.length; i++)
                            _FoodTile(
                              key: Key('food_item_$i'),
                              deleteKey: Key('food_delete_$i'),
                              food: log.entries[i],
                              strings: strings,
                              onDelete: () => controller.removeFood(i),
                            ),
                      ],
                    ),
                  ),
                  _StickyTotals(log: log, strings: strings),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.surface700,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _FoodTile extends StatelessWidget {
  const _FoodTile({
    super.key,
    required this.deleteKey,
    required this.food,
    required this.strings,
    required this.onDelete,
  });

  final Key deleteKey;
  final LoggedFood food;
  final AppStrings strings;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(food.name),
                AppCaption('${food.portion} · ${food.time}'),
                AppCaption(
                  strings.macroSummary(
                    food.proteinG,
                    food.carbsG,
                    food.fatG,
                  ),
                ),
              ],
            ),
          ),
          AppText(strings.kcal(food.calories)),
          IconButton(
            key: deleteKey,
            tooltip: strings.removeItemTooltip(food.name),
            onPressed: onDelete,
            icon: const Icon(
              Icons.close,
              size: 18,
              color: AppColors.textLow,
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyTotals extends StatelessWidget {
  const _StickyTotals({required this.log, required this.strings});

  final DailyFoodLog log;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface800,
        border: Border(
          top: BorderSide(color: AppColors.surface700),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        key: const Key('nutrition_total_row'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppCaption(strings.totalLabel),
                    AppText(
                      strings.kcal(log.totalCalories),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary400,
                      ),
                    ),
                  ],
                ),
              ),
              AppCaption(
                strings.itemCount(log.entries.length),
                key: const Key('nutrition_total_items'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          AppCaption(
            strings.macroSummary(
              log.totalProteinG,
              log.totalCarbsG,
              log.totalFatG,
            ),
            key: const Key('nutrition_total_macros'),
          ),
        ],
      ),
    );
  }
}
