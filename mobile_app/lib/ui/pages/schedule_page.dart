import 'package:flutter/material.dart';

import '../../core/domain/i18n/app_strings.dart';
import '../../core/domain/i18n/localization_scope.dart';
import '../../core/models/schedule_event.dart';
import '../../core/state/schedule_controller.dart';
import '../../core/state/symptom_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/circular_icon_button.dart';
import '../atoms/neumorphic_container.dart';
import '../atoms/typography.dart';
import '../molecules/symptom_tracker.dart';

/// Schedule tab: interactive neumorphic calendar + dynamic daily agenda,
/// backed by [ScheduleController] for date-selection state.
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key, required this.controller, this.symptomController});

  final ScheduleController controller;

  /// Optional symptom tracker controller; enables the daily symptoms view.
  final SymptomController? symptomController;

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  static const double _tileSize = 40;
  static const double _tileSpacing = 6;

  @override
  void initState() {
    super.initState();
    widget.controller.load();
    widget.symptomController?.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final strings = LocalizationScope.stringsOf(context);
        final month = widget.controller.visibleMonth;
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.pageBottom,
          ),
          children: [
            AppHeading(strings.scheduleTitle, size: AppHeadingSize.h2),
            const SizedBox(height: AppSpacing.section),
            _buildCalendar(context, month, strings),
            const SizedBox(height: AppSpacing.section),
            _buildAgenda(context, strings),
            if (widget.symptomController != null) ...[
              const SizedBox(height: AppSpacing.section),
              SymptomTracker(controller: widget.symptomController!),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCalendar(BuildContext context, DateTime month, AppStrings strings) {
    final label = strings.monthYear(month);

    return NeumorphicContainer(
      key: const Key('calendar_grid'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircularIconButton(
                key: const Key('prev_month_button'),
                icon: Icons.chevron_left,
                tooltip: strings.previousMonthTooltip,
                onPressed: widget.controller.previousMonth,
              ),
              AppText(label, style: Theme.of(context).textTheme.titleLarge),
              CircularIconButton(
                key: const Key('next_month_button'),
                icon: Icons.chevron_right,
                tooltip: strings.nextMonthTooltip,
                onPressed: widget.controller.nextMonth,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (var i = 1; i <= 7; i++)
                Expanded(
                  child: Center(
                    child: AppCaption(strings.weekdayNarrow(i)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildGrid(context, month),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, DateTime month) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = DateTime(month.year, month.month, 1).weekday;
    final leading = firstWeekday - 1;

    return Wrap(
      spacing: _tileSpacing,
      runSpacing: _tileSpacing,
      children: [
        for (var i = 0; i < leading; i++)
          const SizedBox(width: _tileSize, height: _tileSize),
        for (var day = 1; day <= daysInMonth; day++)
          _dayTile(context, DateTime(month.year, month.month, day)),
      ],
    );
  }

  Widget _dayTile(BuildContext context, DateTime date) {
    final isSelected = isSameDay(date, widget.controller.selectedDate);
    final hasEvents = widget.controller.hasEventsOn(date);

    return SizedBox(
      width: _tileSize,
      height: _tileSize,
      child: InkWell(
        key: Key('day_${date.day}'),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () => widget.controller.selectDate(date),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary500.withValues(alpha: 0.3)
                : AppColors.surface900,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: isSelected
                ? Border.all(color: AppColors.primary400, width: 1.5)
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text('${date.day}', style: Theme.of(context).textTheme.bodyMedium),
              if (hasEvents)
                Positioned(
                  bottom: 4,
                  child: Container(
                    key: Key('day_marker_${date.day}'),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgenda(BuildContext context, AppStrings strings) {
    final date = widget.controller.selectedDate;
    final events = widget.controller.eventsForSelectedDate;

    return NeumorphicContainer(
      key: const Key('daily_agenda'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText(
            strings.agendaTitle(date),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          if (events.isEmpty)
            AppText(strings.noEventsScheduled)
          else
            for (final event in events)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  children: [
                    Icon(_typeIcon(event.type), size: 20),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: AppText(event.title)),
                    AppCaption(event.time),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  IconData _typeIcon(ScheduleEventType type) => switch (type) {
    ScheduleEventType.workout => Icons.fitness_center,
    ScheduleEventType.meal => Icons.restaurant,
    ScheduleEventType.rest => Icons.hotel,
  };
}