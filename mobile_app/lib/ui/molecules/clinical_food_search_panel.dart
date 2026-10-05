import 'package:flutter/material.dart';

import '../../core/domain/i18n/app_language.dart';
import '../../core/domain/i18n/app_strings.dart';
import '../../core/domain/i18n/localization_scope.dart';
import '../../core/models/food_entry.dart';
import '../../core/state/clinical_profile_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/custom_button.dart';
import '../atoms/typography.dart';
import '../pages/nutrition_presets.dart';
import 'clinical_food_safety_badge.dart';

/// Searchable quick-add catalogue with live clinical food guidance.
class ClinicalFoodSearchPanel extends StatefulWidget {
  const ClinicalFoodSearchPanel({
    super.key,
    required this.onAdd,
    this.controller,
  });

  final ClinicalProfileController? controller;
  final ValueChanged<FoodEntry> onAdd;

  @override
  State<ClinicalFoodSearchPanel> createState() =>
      _ClinicalFoodSearchPanelState();
}

class _ClinicalFoodSearchPanelState extends State<ClinicalFoodSearchPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizationScope.stringsOf(context);
    final language = LocalizationScope.languageOf(context);
    final isSpanish = language == AppLanguage.spanish;
    final content = widget.controller == null
        ? _foodResults(strings)
        : ListenableBuilder(
            listenable: widget.controller!,
            builder: (context, _) => _foodResults(strings),
          );

    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText(strings.addFoodsTitle),
          const SizedBox(height: AppSpacing.sm),
          if (widget.controller != null) ...[
            TextField(
              key: const Key('clinical_food_search_field'),
              controller: _searchController,
              decoration: AppInputDecoration.rounded(
                label: isSpanish ? 'Buscar alimentos' : 'Search foods',
                hint:
                    isSpanish ? 'Avena, carne, sodio…' : 'Oats, meat, sodium…',
                suffixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          content,
        ],
      ),
    );
  }

  Widget _foodResults(AppStrings strings) {
    final query = _query.trim().toLowerCase();
    final matches = NutritionPresets.quickAdds
        .where((food) => food.name.toLowerCase().contains(query))
        .toList(growable: false);
    final language = LocalizationScope.languageOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final food in matches) _foodCard(food, strings),
        if (matches.isEmpty)
          AppCaption(
            language == AppLanguage.spanish
                ? 'No hay alimentos con ese nombre.'
                : 'No foods match that search.',
          ),
      ],
    );
  }

  Widget _foodCard(FoodEntry food, AppStrings strings) {
    final clinical = widget.controller;
    final button = SizedBox(
      width: double.infinity,
      child: CustomButton(
        key: Key('quick_add_${food.name}'),
        label: NutritionPresets.label(strings, food),
        variant: CustomButtonVariant.ghost,
        onPressed: () => widget.onAdd(food),
      ),
    );
    final content = clinical != null && clinical.hasConditions
        ? ClinicalFoodSafetyBadge(
            cardKey: Key('clinical_food_${food.name}'),
            verdict: clinical.evaluate(food),
            child: button,
          )
        : button;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: content,
    );
  }
}
