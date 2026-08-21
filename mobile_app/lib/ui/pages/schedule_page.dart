import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../atoms/neumorphic_container.dart';
import '../atoms/typography.dart';

class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key, this.month});

  /// Reference month; defaults to the mock August 2026 calendar.
  final DateTime? month;

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

  static const Set<int> _workoutDays = {5, 12, 19, 26};

  static const double _tileSize = 40;
  static const double _tileSpacing = 6;

  @override
  Widget build(BuildContext context) {
    final ref = month ?? DateTime(2026, 8);
    final label = '${_monthNames[ref.month - 1]} ${ref.year}';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const AppHeading('Schedule', size: AppHeadingSize.h2),
        const SizedBox(height: AppSpacing.lg),
        NeumorphicContainer(
          key: const Key('calendar_grid'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText(label, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
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
              _buildGrid(context, ref),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, DateTime ref) {
    final daysInMonth = DateTime(ref.year, ref.month + 1, 0).day;
    final firstWeekday = DateTime(ref.year, ref.month, 1).weekday;
    final leading = firstWeekday - 1;

    return Wrap(
      spacing: _tileSpacing,
      runSpacing: _tileSpacing,
      children: [
        for (var i = 0; i < leading; i++)
          const SizedBox(width: _tileSize, height: _tileSize),
        for (var day = 1; day <= daysInMonth; day++)
          _dayTile(context, day, isWorkout: _workoutDays.contains(day)),
      ],
    );
  }

  Widget _dayTile(
    BuildContext context,
    int day, {
    required bool isWorkout,
  }) {
    return SizedBox(
      width: _tileSize,
      height: _tileSize,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isWorkout
              ? AppColors.primary500.withOpacity(0.15)
              : AppColors.surface900,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: isWorkout
              ? Border.all(color: AppColors.primary400, width: 1.5)
              : null,
        ),
        child: Text('$day', style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}