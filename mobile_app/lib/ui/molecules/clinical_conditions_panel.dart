import 'package:flutter/material.dart';

import '../../core/data/ai_diagnosis_repository.dart';
import '../../core/domain/clinical/clinical_condition.dart';
import '../../core/domain/i18n/app_language.dart';
import '../../core/domain/i18n/localization_scope.dart';
import '../../core/state/clinical_profile_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/typography.dart';
import 'ai_diagnosis_controls.dart';

/// Profile controls for active clinical conditions and demo patient cases.
class ClinicalConditionsPanel extends StatelessWidget {
  const ClinicalConditionsPanel({
    super.key,
    required this.controller,
    this.aiDiagnosisRepository,
  });

  final ClinicalProfileController controller;
  final AiDiagnosisRepository? aiDiagnosisRepository;

  @override
  Widget build(BuildContext context) {
    final language = LocalizationScope.languageOf(context);
    final isSpanish = language.name == 'spanish';
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final profile = controller.profile;
        return Column(
          key: const Key('clinical_conditions_panel'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCaption(
              isSpanish
                  ? 'Elige las condiciones para adaptar las notas de alimentos.'
                  : 'Choose conditions to tailor food guidance.',
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<ClinicalMockCase>(
              key: const Key('clinical_mock_case_selector'),
              // ignore: deprecated_member_use
              value: profile.mockCase,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: isSpanish ? 'Caso de paciente' : 'Mock patient case',
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final mockCase in ClinicalMockCase.values)
                  DropdownMenuItem(
                    value: mockCase,
                    child: Text(mockCase.labelFor(language)),
                  ),
              ],
              onChanged: (mockCase) {
                if (mockCase != null) controller.selectMockCase(mockCase);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final condition in ClinicalCondition.values)
              _conditionTile(condition, language),
            if (controller.hasConditions) ...[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: const Key('clinical_clear_conditions'),
                  onPressed: controller.clearConditions,
                  icon: const Icon(Icons.clear_all),
                  label: Text(
                      isSpanish ? 'Borrar condiciones' : 'Clear conditions'),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              isSpanish
                  ? 'Orientación educativa basada en estimaciones nutricionales; no sustituye el consejo de un profesional de salud.'
                  : 'Educational guidance based on nutrient estimates; not a substitute for advice from a health professional.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textLow,
                  ),
            ),
            if (aiDiagnosisRepository != null) ...[
              const SizedBox(height: AppSpacing.md),
              AiDiagnosisControls(
                controller: controller,
                repository: aiDiagnosisRepository!,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _conditionTile(
    ClinicalCondition condition,
    AppLanguage language,
  ) {
    final severity = controller.profile.severityFor(condition);
    final isSpanish = language.name == 'spanish';
    return Column(
      children: [
        CheckboxListTile(
          key: Key('clinical_condition_${condition.name}'),
          contentPadding: EdgeInsets.zero,
          title: Text(condition.labelFor(language)),
          value: severity != null,
          onChanged: (selected) {
            if (selected ?? false) {
              controller.setSeverity(condition, ClinicalSeverity.moderate);
            } else {
              controller.removeCondition(condition);
            }
          },
          activeColor: AppColors.primary400,
        ),
        if (severity != null)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xl),
            child: Row(
              children: [
                Expanded(
                  child: AppCaption(
                    isSpanish ? 'Nivel de seguimiento' : 'Guidance severity',
                  ),
                ),
                DropdownButton<ClinicalSeverity>(
                  key: Key('clinical_severity_${condition.name}'),
                  value: severity,
                  items: [
                    for (final value in ClinicalSeverity.values)
                      DropdownMenuItem(
                        value: value,
                        child: Text(value.labelFor(language)),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) controller.setSeverity(condition, value);
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}
