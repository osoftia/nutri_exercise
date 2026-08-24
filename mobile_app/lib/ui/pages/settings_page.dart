import 'package:flutter/material.dart';

import '../../core/data/notification_prefs_repository.dart';
import '../../core/data/settings_repository.dart';
import '../../core/models/notification_pref.dart';
import '../../core/models/routine_models.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/typography.dart';

/// Settings screen: saved-record management + notification preferences.
class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.settingsRepository,
    required this.prefsRepository,
  });

  final SettingsRepository settingsRepository;
  final NotificationPrefsRepository prefsRepository;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Future<List<WorkoutDay>> _recordsFuture;
  final Map<int, bool> _expanded = {};

  @override
  void initState() {
    super.initState();
    _recordsFuture = widget.settingsRepository.getRecords();
  }

  void _reload() {
    setState(() {
      _recordsFuture = widget.settingsRepository.getRecords();
    });
  }

  Future<void> _editRecord(WorkoutDay day) async {
    final newFocus = await showDialog<String>(
      context: context,
      builder: (dialogContext) =>
          _EditFocusDialog(initialFocus: day.focus),
    );

    if (newFocus == null || newFocus.isEmpty || !mounted) return;
    await widget.settingsRepository.updateRecordFocus(day.id, newFocus);
    if (!mounted) return;
    _reload();
  }

  Future<void> _deleteRecord(WorkoutDay day) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const AppHeading('Delete record', size: AppHeadingSize.h3),
          content: AppText('Delete "${day.weekday}" routine?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const AppText('Cancel'),
            ),
            CustomButtonText(
              label: 'Delete',
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    await widget.settingsRepository.deleteRecord(day.id);
    if (!mounted) return;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const AppHeading('Settings', size: AppHeadingSize.h2),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const AppHeading('Saved Records', size: AppHeadingSize.h3),
          const SizedBox(height: AppSpacing.md),
          FutureBuilder<List<WorkoutDay>>(
            future: _recordsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final records = snapshot.data!;
              if (records.isEmpty) {
                return const AppText('No saved records.');
              }
              return Column(
                children: records.map(_buildRecordTile).toList(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xxl),
          const AppHeading('Notification Preferences', size: AppHeadingSize.h3),
          const SizedBox(height: AppSpacing.md),
          _PrefsSection(repository: widget.prefsRepository),
        ],
      ),
    );
  }

  Widget _buildRecordTile(WorkoutDay day) {
    final expanded = _expanded[day.id] ?? false;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        children: [
          ListTile(
            title: AppText(day.weekday),
            subtitle: AppCaption(day.focus),
            onTap: () => setState(() => _expanded[day.id] = !expanded),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editRecord(day),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteRecord(day),
                ),
                IconButton(
                  icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () =>
                      setState(() => _expanded[day.id] = !expanded),
                ),
              ],
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: day.exercises.map(_buildExerciseRow).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExerciseRow(Exercise exercise) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(exercise.name),
          AppCaption('${exercise.sets} x ${exercise.reps}'),
        ],
      ),
    );
  }
}

/// Renders the three notification toggles, loaded once and kept in local
/// state after an initial read from the repository.
class _PrefsSection extends StatefulWidget {
  const _PrefsSection({required this.repository});

  final NotificationPrefsRepository repository;

  @override
  State<_PrefsSection> createState() => _PrefsSectionState();
}

class _PrefsSectionState extends State<_PrefsSection> {
  final Map<NotificationPrefType, bool> _values = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    for (final type in NotificationPrefType.values) {
      _values[type] = await widget.repository.isEnabled(type);
    }
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _toggle(NotificationPrefType type, bool value) async {
    setState(() => _values[type] = value);
    await widget.repository.setEnabled(type, value);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        SwitchListTile(
          key: const Key('toggle_exercise_alerts'),
          title: const AppText('Exercise alerts'),
          value: _values[NotificationPrefType.exerciseAlerts] ?? false,
          onChanged: (value) =>
              _toggle(NotificationPrefType.exerciseAlerts, value),
        ),
        SwitchListTile(
          key: const Key('toggle_food_alerts'),
          title: const AppText('Food alerts'),
          value: _values[NotificationPrefType.foodAlerts] ?? false,
          onChanged: (value) => _toggle(NotificationPrefType.foodAlerts, value),
        ),
        SwitchListTile(
          key: const Key('toggle_daily_intake_reminders'),
          title: const AppText('Daily intake reminders'),
          value: _values[NotificationPrefType.dailyIntakeReminders] ?? false,
          onChanged: (value) =>
              _toggle(NotificationPrefType.dailyIntakeReminders, value),
        ),
      ],
    );
  }
}

/// Minimal text-style button used inside Settings dialogs.
class CustomButtonText extends StatelessWidget {
  const CustomButtonText({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: Text(label));
  }
}

/// Dialog that edits a record's focus area. Owns its [TextEditingController]
/// so it is disposed when the dialog itself is disposed (not while the exit
/// animation is still running).
class _EditFocusDialog extends StatefulWidget {
  const _EditFocusDialog({required this.initialFocus});

  final String initialFocus;

  @override
  State<_EditFocusDialog> createState() => _EditFocusDialogState();
}

class _EditFocusDialogState extends State<_EditFocusDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialFocus);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const AppHeading('Edit focus', size: AppHeadingSize.h3),
      content: TextField(
        key: const Key('focus_edit_field'),
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Focus area'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const AppText('Cancel'),
        ),
        CustomButtonText(
          label: 'Save',
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
        ),
      ],
    );
  }
}
