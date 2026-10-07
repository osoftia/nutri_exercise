import 'package:flutter/material.dart';

import '../../core/data/ai_diagnosis_repository.dart';
import '../../core/domain/i18n/app_strings.dart';
import '../../core/domain/i18n/localization_scope.dart';
import '../../core/models/ai_diagnosis.dart';
import '../../core/models/food_entry.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/typography.dart';
import 'accordion_section.dart';

/// Renders the most recently cached AI meal recommendations in Nutrition.
class ClinicalRecommendationsAccordion extends StatefulWidget {
  const ClinicalRecommendationsAccordion({
    super.key,
    required this.repository,
    required this.onAddMeal,
  });

  final AiDiagnosisRepository repository;
  final ValueChanged<FoodEntry> onAddMeal;

  @override
  State<ClinicalRecommendationsAccordion> createState() =>
      _ClinicalRecommendationsAccordionState();
}

class _ClinicalRecommendationsAccordionState
    extends State<ClinicalRecommendationsAccordion> {
  late Future<AiDiagnosisReport?> _latest;

  @override
  void initState() {
    super.initState();
    _latest = widget.repository.latestDiagnosis();
  }

  @override
  void didUpdateWidget(covariant ClinicalRecommendationsAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _latest = widget.repository.latestDiagnosis();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizationScope.stringsOf(context);
    return FutureBuilder<AiDiagnosisReport?>(
      future: _latest,
      builder: (context, snapshot) {
        final report = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done ||
            snapshot.hasError ||
            report == null ||
            report.menus.isEmpty) {
          return const SizedBox.shrink();
        }
        return AccordionSection(
          headerKey: const Key('nutrition_clinical_recommendations_accordion'),
          title: strings.recommendedClinicalNutritionTitle,
          icon: Icons.medical_services_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var menuIndex = 0;
                  menuIndex < report.menus.length;
                  menuIndex++) ...[
                if (menuIndex > 0) const SizedBox(height: AppSpacing.md),
                AppText(
                  report.menus[menuIndex].day.isEmpty
                      ? report.menus[menuIndex].name
                      : '${report.menus[menuIndex].day} · ${report.menus[menuIndex].name}',
                ),
                for (var mealIndex = 0;
                    mealIndex < report.menus[menuIndex].meals.length;
                    mealIndex++)
                  _mealTile(
                    context,
                    strings,
                    report.menus[menuIndex].meals[mealIndex],
                    menuIndex,
                    mealIndex,
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _mealTile(
    BuildContext context,
    AppStrings strings,
    AiSuggestedMeal meal,
    int menuIndex,
    int mealIndex,
  ) =>
      Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meal.name),
                  if (meal.description.isNotEmpty)
                    Text(
                      meal.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (meal.calories > 0)
                    Text(
                      '${strings.kcal(meal.calories)} · '
                      '${strings.macroSummary(meal.proteinG, meal.carbsG, meal.fatG)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            IconButton(
              key: Key('clinical_recommendation_add_${menuIndex}_$mealIndex'),
              tooltip: strings.addSuggestedMeal,
              onPressed: () => widget.onAddMeal(
                FoodEntry(
                  name: meal.name,
                  calories: meal.calories,
                  proteinG: meal.proteinG,
                  carbsG: meal.carbsG,
                  fatG: meal.fatG,
                ),
              ),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      );
}
