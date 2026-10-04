import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/data/daily_entry_repository.dart';
import '../../core/domain/i18n/app_strings.dart';
import '../../core/domain/i18n/localization_scope.dart';
import '../../core/models/daily_entry.dart';
import '../../core/state/daily_entry_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/neumorphic_container.dart';
import '../atoms/typography.dart';
import '../molecules/calendar_month_header.dart';
import 'calendar_entry_editor.dart';

/// Opens the calendar history popup backed by [repository].
///
/// Rendered as a centered modal dialog (not a bottom sheet) so the historical
/// daily intake reads as a focused, self-contained card.
///
/// [onChanged] fires after any successful entry save/delete inside the
/// dialog so hosts can refresh dependent state (e.g. streak counters).
Future<void> showCalendarHistoryDialog(
  BuildContext context, {
  required DailyEntryRepository repository,
  VoidCallback? onChanged,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => CalendarHistoryDialog(
      repository: repository,
      onChanged: onChanged,
    ),
  );
}

/// Month grid of daily logged entries (nutrition + exercises) with an inline
/// editor for reviewing and updating past days.
class CalendarHistoryDialog extends StatefulWidget {
  const CalendarHistoryDialog(
      {super.key, required this.repository, this.onChanged});

  final DailyEntryRepository repository;

  /// Fired after any successful entry save/delete (M36 Task 2).
  final VoidCallback? onChanged;

  @override
  State<CalendarHistoryDialog> createState() => _CalendarHistoryDialogState();
}

class _CalendarHistoryDialogState extends State<CalendarHistoryDialog> {
  late final DailyEntryController _controller;
  late DateTime _month;

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

  String _monthLabel(AppStrings strings) => strings.monthYear(_month);

  Future<void> _openEditor(String date) async {
    // M36 Task 1: exact-match lookup through the controller so the tapped
    // day X always opens day X's entry.
    final existing = _controller.entryForDate(date);
    // M36 Task 2: the sheet reports success so dependent host state
    // (streak/stats) refreshes right after a save/delete.
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) => CalendarEntryEditor(
        controller: _controller,
        date: date,
        existing: existing,
      ),
    );
    if ((changed ?? false) && mounted) widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
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
                final strings = LocalizationScope.stringsOf(context);
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
                          AppHeading(strings.history, size: AppHeadingSize.h3),
                          const SizedBox(height: AppSpacing.lg),
                          _buildMonthHeader(strings),
                          const SizedBox(height: AppSpacing.md),
                          _buildWeekdayHeader(strings),
                          const SizedBox(height: AppSpacing.xs),
                          _buildDayGrid(strings),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthHeader(AppStrings strings) {
    return CalendarMonthHeader(
      label: _monthLabel(strings),
      previousKey: const Key('history_prev_month'),
      nextKey: const Key('history_next_month'),
      labelKey: const Key('history_month_label'),
      previousTooltip: strings.previousMonthTooltip,
      nextTooltip: strings.nextMonthTooltip,
      buttonSize: 48,
      onPrevious: _previousMonth,
      onNext: _nextMonth,
    );
  }

  Widget _buildWeekdayHeader(AppStrings strings) {
    return Row(
      children: [
        for (var i = 1; i <= 7; i++)
          Expanded(
            child: Center(
              child: AppCaption(strings.weekdayShort(i)),
            ),
          ),
      ],
    );
  }

  Widget _buildDayGrid(AppStrings strings) {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leadingBlanks = DateTime(_month.year, _month.month, 1).weekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    final entries = _controller.entries
        .where(
          (entry) => entry.date.startsWith(
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: hasEntry
                  ? AppColors.primary500.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: hasEntry ? 5 : 0),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: AppText('$day'),
                    ),
                  ),
                ),
                if (hasEntry)
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Icon(
                      Icons.circle,
                      size: 4,
                      color: AppColors.accent,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    for (var i = totalCells; i % 7 != 0; i++) {
      cells.add(const SizedBox.shrink());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / 7;
        final cellHeight = math.min(cellWidth * 1.1, 64.0);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            mainAxisExtent: cellHeight,
          ),
          itemCount: cells.length,
          itemBuilder: (context, index) => cells[index],
        );
      },
    );
  }
}
