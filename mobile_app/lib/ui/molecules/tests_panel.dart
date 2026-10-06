import 'package:flutter/material.dart';

import '../../core/data/daily_entry_repository.dart';
import '../../core/data/error_log_repository.dart';
import '../../core/domain/i18n/localization_scope.dart';
import '../../core/models/error_log_entry.dart';
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
    this.consumedCalories = 0,
  });

  /// Service used to fire the test notifications.
  final NotificationService notificationService;

  /// Optional calendar store used by the reactive meal notification.
  final DailyEntryRepository? dailyEntryRepository;

  /// Optional local forensic log shown from the Profile Testing panel.
  final ErrorLogRepository? errorLogRepository;

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
      ],
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
          ],
        ),
      ),
    );
  }
}
