import 'package:flutter/material.dart';

import '../../core/domain/i18n/localization_scope.dart';
import '../../core/models/daily_entry.dart';
import '../../core/state/daily_entry_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/custom_button.dart';
import '../atoms/neumorphic_container.dart';
import '../atoms/typography.dart';

/// Centered modal editor for a single day's nutrition + exercises.
///
/// Extracted from `calendar_history_dialog.dart` (M48 decomposition). Reports
/// `true` through `Navigator.pop` on a successful save/delete so the host can
/// refresh dependent state (e.g. streak counters).
class CalendarEntryEditor extends StatefulWidget {
  /// Creates a day editor.
  const CalendarEntryEditor({
    super.key,
    required this.controller,
    required this.date,
    this.existing,
  });

  /// The calendar-entry controller that persists the change.
  final DailyEntryController controller;

  /// The `YYYY-MM-DD` day being edited.
  final String date;

  /// The existing entry for [date], or `null` when creating one.
  final DailyEntry? existing;

  @override
  State<CalendarEntryEditor> createState() => _CalendarEntryEditorState();
}

class _CalendarEntryEditorState extends State<CalendarEntryEditor> {
  late final TextEditingController _calories;
  late final TextEditingController _protein;
  late final TextEditingController _carbs;
  late final TextEditingController _fat;
  late final TextEditingController _exercises;

  @override
  void initState() {
    super.initState();
    final entry = widget.existing;
    _calories = TextEditingController(text: entry?.calories.toString() ?? '');
    _protein = TextEditingController(text: entry?.protein.toString() ?? '');
    _carbs = TextEditingController(text: entry?.carbs.toString() ?? '');
    _fat = TextEditingController(text: entry?.fat.toString() ?? '');
    _exercises = TextEditingController(
      text: entry?.exercises.join(', ') ?? '',
    );
  }

  @override
  void dispose() {
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    _exercises.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final entry = DailyEntry(
      date: widget.date,
      calories: int.tryParse(_calories.text.trim()) ?? 0,
      protein: int.tryParse(_protein.text.trim()) ?? 0,
      carbs: int.tryParse(_carbs.text.trim()) ?? 0,
      fat: int.tryParse(_fat.text.trim()) ?? 0,
      exercises: _exercises.text
          .split(',')
          .map((name) => name.trim())
          .where((name) => name.isNotEmpty)
          .toList(),
    );

    final saved = await widget.controller.save(entry);
    if (saved && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final deleted = await widget.controller.delete(widget.date);
    if (deleted && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final strings = LocalizationScope.stringsOf(context);
    final hasExisting = widget.existing != null;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: NeumorphicContainer(
          key: const Key('history_entry_editor'),
          color: AppColors.surface900,
          padding: EdgeInsets.zero,
          borderRadius: AppRadius.lg,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppText(strings.editEntryTitleFor(widget.date)),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      key: const Key('history_calories_field'),
                      controller: _calories,
                      keyboardType: TextInputType.number,
                      decoration: AppInputDecoration.rounded(
                        label: strings.calorieLabel,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('history_protein_field'),
                            controller: _protein,
                            keyboardType: TextInputType.number,
                            decoration: AppInputDecoration.rounded(
                              label: '${strings.proteinLabel} (g)',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextField(
                            key: const Key('history_carbs_field'),
                            controller: _carbs,
                            keyboardType: TextInputType.number,
                            decoration: AppInputDecoration.rounded(
                              label: '${strings.carbsLabel} (g)',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextField(
                            key: const Key('history_fat_field'),
                            controller: _fat,
                            keyboardType: TextInputType.number,
                            decoration: AppInputDecoration.rounded(
                              label: '${strings.fatLabel} (g)',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      key: const Key('history_exercises_field'),
                      controller: _exercises,
                      decoration: AppInputDecoration.rounded(
                        label: strings.exercisesFieldLabel,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (hasExisting) ...[
                          // M36 Task 2: prominent delete affordance — danger
                          // outline + trash icon + explicit label (same stable
                          // key so existing tests keep resolving it).
                          OutlinedButton.icon(
                            key: const Key('history_delete_button'),
                            onPressed: _delete,
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.danger,
                            ),
                            label: Text(strings.deleteRecordButton),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl,
                                vertical: AppSpacing.md,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                        ],
                        CustomButton(
                          key: const Key('history_save_button'),
                          label: strings.save,
                          onPressed: _save,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
