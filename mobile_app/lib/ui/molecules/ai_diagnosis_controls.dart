import 'package:flutter/material.dart';

import '../../core/data/ai_diagnosis_repository.dart';
import '../../core/domain/i18n/app_language.dart';
import '../../core/domain/i18n/localization_scope.dart';
import '../../core/models/ai_diagnosis.dart';
import '../../core/state/clinical_profile_controller.dart';
import '../../core/theme/app_theme.dart';

/// Profile controls for creating, saving, and viewing AI clinical reports.
class AiDiagnosisControls extends StatefulWidget {
  const AiDiagnosisControls({
    super.key,
    required this.controller,
    required this.repository,
  });

  final ClinicalProfileController controller;
  final AiDiagnosisRepository repository;

  @override
  State<AiDiagnosisControls> createState() => _AiDiagnosisControlsState();
}

class _AiDiagnosisControlsState extends State<AiDiagnosisControls> {
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
    try {
      await widget.repository.saveFoodPreferences(_preferencesController.text);
    } catch (_) {
      // Generation can still use the in-memory value if local preferences fail.
    }
  }

  Future<void> _generate(AppLanguage language) async {
    if (!widget.controller.hasConditions || _isLoading) return;
    if (_latest != null && !await _confirmOverwrite(language)) return;
    if (!mounted) return;
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

  /// Confirms before replacing an existing valid local diagnosis.
  Future<bool> _confirmOverwrite(AppLanguage language) async {
    final isSpanish = language == AppLanguage.spanish;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('ai_diagnosis_overwrite_dialog'),
        title: Text(isSpanish ? 'Volver a generar' : 'Regenerate diagnosis'),
        content: Text(
          isSpanish
              ? '¿Está seguro de que desea volver a generar el diagnóstico?'
              : 'Are you sure you want to regenerate the diagnosis?',
        ),
        actions: [
          TextButton(
            key: const Key('ai_diagnosis_overwrite_cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(isSpanish ? 'Cancelar' : 'Cancel'),
          ),
          FilledButton(
            key: const Key('ai_diagnosis_overwrite_confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(isSpanish ? 'Regenerar' : 'Regenerate'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
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
