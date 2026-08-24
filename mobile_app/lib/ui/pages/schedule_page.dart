import 'package:flutter/material.dart';

import '../../core/models/schedule_event.dart';
import '../../core/state/schedule_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/neumorphic_container.dart';
import '../atoms/typography.dart';

/// Schedule tab: interactive neumorphic calendar + dynamic daily agenda,
/// backed by [ScheduleController] for date-selection state.
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key, required this.controller});

  final ScheduleController controller;

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _weekdayHeader = [
    'Mo',
    'Tu',
    'We',
    'Th',
    'Fr',
    'Sa',
    'Su',
  ];

  static const List<String> _weekdayShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const double _tileSize = 40;
  static const double _tileSpacing = 6;

  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final month = widget.controller.visibleMonth;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const AppHeading('Schedule', size: AppHeadingSize.h2),
            const SizedBox(height: AppSpacing.lg),
            _buildCalendar(context, month),
            const SizedBox(height: AppSpacing.lg),
            _buildAgenda(context),
          ],
        );
      },
    );
  }

  Widget _buildCalendar(BuildContext context, DateTime month) {
    final label = '${_monthNames[month.month - 1]} ${month.year}';

    return NeumorphicContainer(
      key: const Key('calendar_grid'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                key: const Key('prev_month_button'),
                icon: const Icon(Icons.chevron_left),
                onPressed: widget.controller.previousMonth,
              ),
              AppText(label, style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                key: const Key('next_month_button'),
                icon: const Icon(Icons.chevron_right),
                onPressed: widget.controller.nextMonth,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: _weekdayHeader
                .map(
                  (day) => Expanded(
                    child: Center(child: AppCaption(day)),
                  ),
                )
                .toList(),
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
                ? AppColors.primary500.withOpacity(0.3)
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

  Widget _buildAgenda(BuildContext context) {
    final date = widget.controller.selectedDate;
    final events = widget.controller.eventsForSelectedDate;

    return NeumorphicContainer(
      key: const Key('daily_agenda'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText(_agendaTitle(date), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          if (events.isEmpty)
            const AppText('No events scheduled')
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

  String _agendaTitle(DateTime date) =>
      '${_weekdayShort[date.weekday - 1]}, ${date.day} '
      '${_monthNames[date.month - 1]}';

  IconData _typeIcon(ScheduleEventType type) => switch (type) {
    ScheduleEventType.workout => Icons.fitness_center,
    ScheduleEventType.meal => Icons.restaurant,
    ScheduleEventType.rest => Icons.hotel,
  };
}