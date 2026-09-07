import 'package:flutter/material.dart';

import '../../core/data/daily_entry_repository.dart';
import '../../core/models/daily_entry.dart';
import '../../core/state/daily_entry_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/custom_button.dart';
import '../atoms/neumorphic_container.dart';
import '../atoms/typography.dart';

/// Opens the calendar history popup backed by [repository].
Future<void> showCalendarHistoryDialog(
  BuildContext context, {
  required DailyEntryRepository repository,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CalendarHistoryDialog(repository: repository),
  );
}

/// Month grid of daily logged entries (nutrition + exercises) with an inline
/// editor for reviewing and updating past days.
class CalendarHistoryDialog extends StatefulWidget {
  const CalendarHistoryDialog({super.key, required this.repository});

  final DailyEntryRepository repository;

  @override
  State<CalendarHistoryDialog> createState() => _CalendarHistoryDialogState();
}

class _CalendarHistoryDialogState extends State<CalendarHistoryDialog> {
  late final DailyEntryController _controller;
  late DateTime _month;

  static const List<String> _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _controller = DailyEntryController(repository: widget.repository);
    _controller.loadAll();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _previousMonth() {
    setState(() => _month = DateTime(_month.year, _month.month - 1));
  }

  void _nextMonth() {
    setState(() => _month = DateTime(_month.year, _month.month + 1));
  }

  String _monthLabel() {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[_month.month - 1]} ${_month.year}';
  }

  Future<void> _openEditor(String date) async {
    final existing = _controller.entries
        .where((entry) => entry.date == date)
        .firstOrNull;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EntryEditorSheet(
        controller: _controller,
        date: date,
        existing: existing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: NeumorphicContainer(
        key: const Key('calendar_history_dialog'),
        color: AppColors.surface900,
        padding: EdgeInsets.zero,
        borderRadius: AppRadius.lg,
        child: SafeArea(
          top: false,
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AppHeading('History', size: AppHeadingSize.h3),
                        const SizedBox(height: AppSpacing.md),
                        _buildMonthHeader(),
                        const SizedBox(height: AppSpacing.sm),
                        _buildWeekdayHeader(),
                        const SizedBox(height: AppSpacing.xs),
                        _buildDayGrid(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          key: const Key('history_prev_month'),
          icon: const Icon(Icons.chevron_left),
          onPressed: _previousMonth,
        ),
        AppText(_monthLabel(), key: const Key('history_month_label')),
        IconButton(
          key: const Key('history_next_month'),
          icon: const Icon(Icons.chevron_right),
          onPressed: _nextMonth,
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader() {
    return Row(
      children: [
        for (final day in _weekdays)
          Expanded(
            child: Center(
              child: AppCaption(day),
            ),
          ),
      ],
    );
  }

  Widget _buildDayGrid() {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingBlanks = DateTime(_month.year, _month.month, 1).weekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    final entries = _controller.entries
        .where(
          (entry) =>
              entry.date.startsWith(
                '${_month.year.toString().padLeft(4, '0')}-'
                '${_month.month.toString().padLeft(2, '0')}',
              ),
        )
        .map((entry) => entry.date)
        .toSet();

    final cells = <Widget>[];
    for (var i = 0; i < leadingBlanks; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DailyEntry.dateKey(DateTime(_month.year, _month.month, day));
      final hasEntry = entries.contains(date);
      cells.add(
        InkWell(
          key: Key('calendar_day_$date'),
          onTap: () => _openEditor(date),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            margin: const EdgeInsets.all(2),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: hasEntry
                  ? AppColors.primary500.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText('$day'),
                if (hasEntry)
                  const Icon(Icons.circle, size: 6, color: AppColors.accent),
              ],
            ),
          ),
        ),
      );
    }
    for (var i = totalCells; i % 7 != 0; i++) {
      cells.add(const SizedBox.shrink());
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: cells,
    );
  }
}

/// Bottom-sheet editor for a single day's nutrition + exercises.
class _EntryEditorSheet extends StatefulWidget {
  const _EntryEditorSheet({
    required this.controller,
    required this.date,
    this.existing,
  });

  final DailyEntryController controller;
  final String date;
  final DailyEntry? existing;

  @override
  State<_EntryEditorSheet> createState() => _EntryEditorSheetState();
}

class _EntryEditorSheetState extends State<_EntryEditorSheet> {
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
    if (saved && mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final deleted = await widget.controller.delete(widget.date);
    if (deleted && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final hasExisting = widget.existing != null;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: NeumorphicContainer(
        key: const Key('history_entry_editor'),
        color: AppColors.surface900,
        padding: EdgeInsets.zero,
        borderRadius: AppRadius.lg,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppText('Edit ${widget.date}'),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: const Key('history_calories_field'),
                  controller: _calories,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Calories',
                    border: OutlineInputBorder(),
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
                        decoration: const InputDecoration(
                          labelText: 'Protein (g)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        key: const Key('history_carbs_field'),
                        controller: _carbs,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Carbs (g)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        key: const Key('history_fat_field'),
                        controller: _fat,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Fat (g)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  key: const Key('history_exercises_field'),
                  controller: _exercises,
                  decoration: const InputDecoration(
                    labelText: 'Exercises (comma separated)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (hasExisting) ...[
                      CustomButton(
                        key: const Key('history_delete_button'),
                        label: 'Delete',
                        variant: CustomButtonVariant.ghost,
                        onPressed: _delete,
                      ),
                      const SizedBox(width: AppSpacing.md),
                    ],
                    CustomButton(
                      key: const Key('history_save_button'),
                      label: 'Save',
                      onPressed: _save,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}