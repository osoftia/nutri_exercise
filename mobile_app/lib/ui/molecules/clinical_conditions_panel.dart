import 'package:flutter/material.dart';

import '../../core/data/ai_diagnosis_repository.dart';
import '../../core/domain/clinical/clinical_condition.dart';
import '../../core/domain/i18n/app_language.dart';
import '../../core/domain/i18n/localization_scope.dart';
import '../../core/models/ai_diagnosis.dart';
import '../../core/state/clinical_profile_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/typography.dart';

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
              _AiDiagnosisControls(
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

class _AiDiagnosisControls extends StatefulWidget {
  const _AiDiagnosisControls({
    required this.controller,
    required this.repository,
  });

  final ClinicalProfileController controller;
  final AiDiagnosisRepository repository;

  @override
  State<_AiDiagnosisControls> createState() => _AiDiagnosisControlsState();
}

class _AiDiagnosisControlsState extends State<_AiDiagnosisControls> {
  final TextEditingController _preferencesController = TextEditingController();
  AiDiagnosisReport? _latest;
  bool _isLoading = false;
  bool _preferencesLoaded = false;
  String? _error;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void dispose() {
    _preferencesController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    try {
      final values = await Future.wait<Object?>([
        widget.repository.loadFoodPreferences(),
        widget.repository.latestDiagnosis(),
      ]);
      if (!mounted) return;
      setState(() {
        _preferencesController.text = values[0] as String;
        _latest = values[1] as AiDiagnosisReport?;
        _preferencesLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _preferencesLoaded = true);
    }
  }

  Future<void> _savePreferences() async {
    await widget.repository.saveFoodPreferences(_preferencesController.text);
  }

  Future<void> _generate(AppLanguage language) async {
    if (!widget.controller.hasConditions || _isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _showSuccess = false;
    });
    try {
      final report = await widget.repository.generateDiagnosis(
        profile: widget.controller.profile,
        foodPreferences: _preferencesController.text,
        language: language.code,
      );
      if (!mounted) return;
      setState(() {
        _latest = report;
        _showSuccess = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('AiDiagnosisException: ', '');
        _showSuccess = false;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = LocalizationScope.languageOf(context);
    final isSpanish = language == AppLanguage.spanish;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('clinical_food_preferences_field'),
          controller: _preferencesController,
          enabled: _preferencesLoaded && !_isLoading,
          minLines: 1,
          maxLines: 3,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _savePreferences(),
          onEditingComplete: _savePreferences,
          decoration: InputDecoration(
            labelText:
                isSpanish ? 'Preferencias de comida' : 'Food preferences',
            hintText: isSpanish
                ? 'Ej.: vegetariana, me gusta el pescado, sin champiñones'
                : 'e.g. vegetarian, likes fish, no mushrooms',
            helperText: isSpanish
                ? 'Se enviarán para adaptar las sugerencias.'
                : 'Used to tailor the suggested menus.',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton.icon(
          key: const Key('ai_diagnosis_generate_button'),
          onPressed: widget.controller.hasConditions && !_isLoading
              ? () => _generate(language)
              : null,
          icon: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(
            _isLoading
                ? (isSpanish ? 'Generando…' : 'Generating…')
                : (isSpanish ? 'Obtener diagnóstico' : 'Get diagnosis'),
          ),
        ),
        if (!widget.controller.hasConditions) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            isSpanish
                ? 'Selecciona al menos una condición para generar el informe.'
                : 'Select at least one condition to generate a report.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (_showSuccess) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            key: const Key('ai_diagnosis_success_banner'),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: AppColors.success),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(isSpanish
                      ? 'Informe guardado para consultarlo sin conexión.'
                      : 'Report saved for offline access.'),
                ),
              ],
            ),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _error!,
            key: const Key('ai_diagnosis_error_message'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (_latest != null) ...[
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            key: const Key('ai_diagnosis_view_saved_button'),
            onPressed: () => showAiDiagnosisSheet(
              context,
              _latest!,
              language: language,
            ),
            icon: const Icon(Icons.menu_book_outlined),
            label:
                Text(isSpanish ? 'Ver informe guardado' : 'View saved report'),
          ),
        ],
      ],
    );
  }
}

/// Displays a locally saved report and its suggested menus.
Future<void> showAiDiagnosisSheet(
  BuildContext context,
  AiDiagnosisReport report, {
  AppLanguage language = AppLanguage.english,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final isSpanish = language == AppLanguage.spanish;
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.88,
            child: ListView(
              key: const Key('ai_diagnosis_result_sheet'),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              children: [
                Text(report.title,
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.md),
                Text(report.summary),
                if (report.considerations.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    isSpanish ? 'Puntos a considerar' : 'Considerations',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final item in report.considerations)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: const Icon(Icons.info_outline),
                      title: Text(item),
                    ),
                ],
                if (report.menus.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    isSpanish ? 'Menús sugeridos' : 'Suggested menus',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final menu in report.menus) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      menu.day.isEmpty
                          ? menu.name
                          : '${menu.day} · ${menu.name}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    for (final meal in menu.meals)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.restaurant_menu),
                        title: Text(meal.name),
                        subtitle: meal.description.isEmpty
                            ? null
                            : Text(meal.description),
                      ),
                  ],
                ],
                const SizedBox(height: AppSpacing.lg),
                Text(
                  isSpanish
                      ? 'Contenido educativo generado por IA; no constituye un diagnóstico médico ni sustituye la atención de un profesional de salud.'
                      : 'Educational AI-generated content; it is not a medical diagnosis and does not replace advice from a qualified health professional.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
