import 'package:flutter/material.dart';

import '../../core/data/daily_entry_repository.dart';
import '../../core/data/error_log_repository.dart';
import '../../core/data/success_log_repository.dart';
import '../../core/domain/i18n/localization_scope.dart';
import '../../core/models/error_log_entry.dart';
import '../../core/models/success_log_entry.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/custom_button.dart';
import '../atoms/typography.dart';

/// The Profile "Pruebas" (Tests) panel: quick notification test triggers.
class TestsPanel extends StatelessWidget {
  /// Creates a tests panel.
  const TestsPanel({
    super.key,
    required this.notificationService,
    this.dailyEntryRepository,
    this.errorLogRepository,
    this.successLogRepository,
    this.consumedCalories = 0,
  });

  /// Service used to fire the test notifications.
  final NotificationService notificationService;

  /// Optional calendar store used by the reactive meal notification.
  final DailyEntryRepository? dailyEntryRepository;

  /// Optional local forensic log shown from the Profile Testing panel.
  final ErrorLogRepository? errorLogRepository;

  /// Optional local successful-response log shown from the Testing panel.
  final SuccessLogRepository? successLogRepository;

  /// Calories passed to the reactive meal notification body.
  final int consumedCalories;

  @override
  Widget build(BuildContext context) {
    final strings = LocalizationScope.stringsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCaption(strings.quickTestTitle),
        const SizedBox(height: AppSpacing.sm),
        CustomButton(
          key: const Key('settings_meal_test_button'),
          label: strings.mealTestButton,
          variant: CustomButtonVariant.ghost,
          onPressed: () {
            final repository = dailyEntryRepository;
            if (repository != null) {
              notificationService.showReactiveMealNotification(
                repository: repository,
                recovered: consumedCalories,
              );
            }
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        CustomButton(
          key: const Key('settings_nightly_test_button'),
          label: strings.nightlyCheckInTestButton,
          variant: CustomButtonVariant.ghost,
          onPressed: notificationService.showNightlyCheckInTest,
        ),
        const SizedBox(height: AppSpacing.sm),
        CustomButton(
          key: const Key('settings_exercise_not_button'),
          label: strings.exerciseNotButton,
          variant: CustomButtonVariant.ghost,
          onPressed: notificationService.showExerciseReminderTest,
        ),
        if (errorLogRepository != null) ...[
          const SizedBox(height: AppSpacing.sm),
          CustomButton(
            key: const Key('settings_error_logs_button'),
            label: 'Errores registrados',
            variant: CustomButtonVariant.ghost,
            onPressed: () => showErrorLogSheet(context, errorLogRepository!),
          ),
        ],
        if (successLogRepository != null) ...[
          const SizedBox(height: AppSpacing.sm),
          CustomButton(
            key: const Key('settings_success_logs_button'),
            label: 'Respuestas exitosas',
            variant: CustomButtonVariant.ghost,
            onPressed: () =>
                showSuccessLogSheet(context, successLogRepository!),
          ),
        ],
      ],
    );
  }
}

/// Presents the locally persisted successful-response history.
Future<void> showSuccessLogSheet(
  BuildContext context,
  SuccessLogRepository repository,
) {
  final language = LocalizationScope.languageOf(context);
  final isSpanish = language.name == 'spanish';
  final entries = repository.getAll();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: Text(
                isSpanish ? 'Respuestas exitosas' : 'Successful responses',
                key: const Key('success_log_sheet_title'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Expanded(
              child: FutureBuilder<List<SuccessLogEntry>>(
                future: entries,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(isSpanish
                          ? 'No se pudo cargar el historial de respuestas.'
                          : 'Could not load the response history.'),
                    );
                  }
                  final records = snapshot.data ?? const <SuccessLogEntry>[];
                  if (records.isEmpty) {
                    return Center(
                      child: Text(isSpanish
                          ? 'No hay respuestas exitosas registradas.'
                          : 'No successful responses have been recorded.'),
                    );
                  }
                  return ListView.builder(
                    key: const Key('success_log_list'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    itemCount: records.length,
                    itemBuilder: (context, index) =>
                        _SuccessLogCard(entry: records[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SuccessLogCard extends StatelessWidget {
  const _SuccessLogCard({required this.entry});

  final SuccessLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final timestamp =
        entry.timestamp.toLocal().toString().replaceFirst('T', ' ');
    final id = entry.id ?? entry.timestamp.microsecondsSinceEpoch;
    return Card(
      key: Key('success_log_card_$id'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              dense: true,
              title: Text(timestamp),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: ${entry.statusCode}'),
                    if (entry.label.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text('Label: ${entry.label}'),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    SelectableText(
                      'Request URL: ${entry.requestUrl.isEmpty ? '—' : entry.requestUrl}',
                    ),
                  ],
                ),
              ),
            ),
            if (entry.requestBody.isNotEmpty)
              ExpansionTile(
                key: Key('success_log_request_body_$id'),
                title: const Text('Request body'),
                childrenPadding: const EdgeInsets.all(AppSpacing.md),
                children: [SelectableText(entry.requestBody)],
              ),
            if (entry.responseBody.isNotEmpty)
              ExpansionTile(
                key: Key('success_log_response_body_$id'),
                title: const Text('Response body'),
                childrenPadding: const EdgeInsets.all(AppSpacing.md),
                children: [SelectableText(entry.responseBody)],
              ),
          ],
        ),
      ),
    );
  }
}

/// Presents the locally persisted technical error history.
Future<void> showErrorLogSheet(
  BuildContext context,
  ErrorLogRepository repository,
) {
  final language = LocalizationScope.languageOf(context);
  final isSpanish = language.name == 'spanish';
  final entries = repository.getAll();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.sm,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: Text(
                isSpanish ? 'Errores registrados' : 'Recorded errors',
                key: const Key('error_log_sheet_title'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Expanded(
              child: FutureBuilder<List<ErrorLogEntry>>(
                future: entries,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(isSpanish
                          ? 'No se pudo cargar el historial de errores.'
                          : 'Could not load the error history.'),
                    );
                  }
                  final records = snapshot.data ?? const <ErrorLogEntry>[];
                  if (records.isEmpty) {
                    return Center(
                      child: Text(isSpanish
                          ? 'No hay errores registrados.'
                          : 'No errors have been recorded.'),
                    );
                  }
                  return ListView.builder(
                    key: const Key('error_log_list'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    itemCount: records.length,
                    itemBuilder: (context, index) =>
                        _ErrorLogCard(entry: records[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ErrorLogCard extends StatelessWidget {
  const _ErrorLogCard({required this.entry});

  final ErrorLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final timestamp =
        entry.timestamp.toLocal().toString().replaceFirst('T', ' ');
    final id = entry.id ?? entry.timestamp.microsecondsSinceEpoch;
    return Card(
      key: Key('error_log_card_$id'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              dense: true,
              title: Text(timestamp),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Code: ${entry.errorCode}'),
                    const SizedBox(height: AppSpacing.xs),
                    SelectableText(
                      'Request URL: ${entry.requestUrl.isEmpty ? '—' : entry.requestUrl}',
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    SelectableText(entry.message),
                  ],
                ),
              ),
            ),
            ExpansionTile(
              key: Key('error_log_stack_$id'),
              title: const Text('Stack trace'),
              childrenPadding: const EdgeInsets.all(AppSpacing.md),
              children: [
                SelectableText(
                  entry.stackTrace.isEmpty ? '—' : entry.stackTrace,
                ),
              ],
            ),
            if (entry.requestBody.isNotEmpty)
              ExpansionTile(
                key: Key('error_log_request_body_$id'),
                title: const Text('Request body'),
                childrenPadding: const EdgeInsets.all(AppSpacing.md),
                children: [SelectableText(entry.requestBody)],
              ),
            if (entry.responseBody.isNotEmpty)
              ExpansionTile(
                key: Key('error_log_response_body_$id'),
                title: const Text('Response body'),
                childrenPadding: const EdgeInsets.all(AppSpacing.md),
                children: [SelectableText(entry.responseBody)],
              ),
          ],
        ),
      ),
    );
  }
}
