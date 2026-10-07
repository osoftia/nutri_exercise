import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/data/notification_prefs_repository.dart';
import '../../core/domain/i18n/localization_scope.dart';
import '../../core/models/notification_pref.dart';
import '../../core/state/http_timeout_settings_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/typography.dart';

/// The Profile "System Settings" panel: notification preferences.
///
/// The language switcher is rendered by the Profile page directly beneath this
/// panel so it always sits at the very bottom of System Settings.
class SettingsPanel extends StatefulWidget {
  /// Creates a settings panel.
  const SettingsPanel({
    super.key,
    this.prefsRepository,
    this.timeoutSettingsController,
  });

  /// Optional preference store; when absent the toggles are hidden.
  final NotificationPrefsRepository? prefsRepository;

  /// Optional global request-timeout preference.
  final HttpTimeoutSettingsController? timeoutSettingsController;

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

    final repository = widget.prefsRepository;
    final timeoutController = widget.timeoutSettingsController;
    if (repository == null && timeoutController == null) {
      return AppCaption(strings.notificationPreferencesTitle);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (repository != null) ...[
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
            onChanged: (value) =>
                _toggle(NotificationPrefType.foodAlerts, value),
          ),
          SwitchListTile(
            key: const Key('settings_toggle_daily_intake_reminders'),
            contentPadding: EdgeInsets.zero,
            title: AppText(strings.dailyIntakeRemindersLabel),
            value: _values[NotificationPrefType.dailyIntakeReminders] ?? false,
            onChanged: (value) =>
                _toggle(NotificationPrefType.dailyIntakeReminders, value),
          ),
        ],
        if (timeoutController != null) ...[
          if (repository != null) const SizedBox(height: AppSpacing.md),
          ListenableBuilder(
            listenable: timeoutController,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  strings.requestTimeoutLabel(timeoutController.timeoutSeconds),
                  key: const Key('settings_request_timeout_label'),
                ),
                const SizedBox(height: AppSpacing.xs),
                Slider(
                  key: const Key('settings_request_timeout_slider'),
                  min: 10,
                  max: 60,
                  divisions: 50,
                  value: timeoutController.timeoutSeconds.toDouble(),
                  label: '${timeoutController.timeoutSeconds} s',
                  onChanged: timeoutController.isLoaded
                      ? (value) =>
                          timeoutController.previewTimeoutSeconds(value.round())
                      : null,
                  onChangeEnd: timeoutController.isLoaded
                      ? (value) => unawaited(
                            timeoutController.setTimeoutSeconds(value.round()),
                          )
                      : null,
                ),
                AppCaption(strings.requestTimeoutDescription),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
