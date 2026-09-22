import 'package:flutter/material.dart';

import '../../core/data/notification_prefs_repository.dart';
import '../../core/domain/i18n/localization_scope.dart';
import '../../core/models/notification_pref.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/custom_button.dart';
import '../atoms/typography.dart';

/// The Profile "Settings" panel: notification preferences plus quick
/// notification test triggers.
class SettingsPanel extends StatefulWidget {
  /// Creates a settings panel.
  const SettingsPanel({
    super.key,
    this.prefsRepository,
    this.notificationService,
  });

  /// Optional preference store; when absent the toggles are hidden.
  final NotificationPrefsRepository? prefsRepository;

  /// Optional notification service; when present the quick-test triggers show.
  final NotificationService? notificationService;

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  final Map<NotificationPrefType, bool> _values = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repository = widget.prefsRepository;
    if (repository == null) {
      if (mounted) setState(() => _loaded = true);
      return;
    }
    for (final type in NotificationPrefType.values) {
      _values[type] = await repository.isEnabled(type);
    }
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _toggle(NotificationPrefType type, bool value) async {
    setState(() => _values[type] = value);
    await widget.prefsRepository?.setEnabled(type, value);
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizationScope.stringsOf(context);
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final children = <Widget>[];
    final repository = widget.prefsRepository;
    if (repository != null) {
      children.addAll([
        AppCaption(strings.notificationPreferencesTitle),
        const SizedBox(height: AppSpacing.sm),
        SwitchListTile(
          key: const Key('settings_toggle_exercise_alerts'),
          contentPadding: EdgeInsets.zero,
          title: AppText(strings.exerciseAlertsLabel),
          value: _values[NotificationPrefType.exerciseAlerts] ?? false,
          onChanged: (value) =>
              _toggle(NotificationPrefType.exerciseAlerts, value),
        ),
        SwitchListTile(
          key: const Key('settings_toggle_food_alerts'),
          contentPadding: EdgeInsets.zero,
          title: AppText(strings.foodAlertsLabel),
          value: _values[NotificationPrefType.foodAlerts] ?? false,
          onChanged: (value) => _toggle(NotificationPrefType.foodAlerts, value),
        ),
        SwitchListTile(
          key: const Key('settings_toggle_daily_intake_reminders'),
          contentPadding: EdgeInsets.zero,
          title: AppText(strings.dailyIntakeRemindersLabel),
          value: _values[NotificationPrefType.dailyIntakeReminders] ?? false,
          onChanged: (value) =>
              _toggle(NotificationPrefType.dailyIntakeReminders, value),
        ),
      ]);
    }

    final service = widget.notificationService;
    if (service != null) {
      children.addAll([
        const SizedBox(height: AppSpacing.lg),
        AppCaption(strings.quickTestTitle),
        const SizedBox(height: AppSpacing.sm),
        CustomButton(
          key: const Key('settings_nightly_test_button'),
          label: strings.nightlyCheckInTestButton,
          variant: CustomButtonVariant.ghost,
          onPressed: service.showNightlyCheckInTest,
        ),
        const SizedBox(height: AppSpacing.sm),
        CustomButton(
          key: const Key('settings_exercise_not_button'),
          label: strings.exerciseNotButton,
          variant: CustomButtonVariant.ghost,
          onPressed: service.showExerciseReminderTest,
        ),
      ]);
    }

    if (children.isEmpty) {
      return AppCaption(strings.notificationPreferencesTitle);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
