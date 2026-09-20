import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/data/daily_entry_repository.dart';
import '../../core/domain/i18n/app_strings.dart';
import '../../core/domain/i18n/localization_scope.dart';
import '../../core/models/weekly_stat.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/weekly_stats.dart';
import '../atoms/neumorphic_container.dart';
import '../atoms/typography.dart';

/// Opens the weekly statistics sheet backed by [repository].
Future<void> showWeeklyStatsSheet(
  BuildContext context, {
  required DailyEntryRepository repository,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => WeeklyStatsSheet(repository: repository),
  );
}

/// Neumorphic sheet showing the last-7-days calories consumed vs burned with
/// an animated grouped bar chart.
class WeeklyStatsSheet extends StatefulWidget {
  const WeeklyStatsSheet({super.key, required this.repository});

  final DailyEntryRepository repository;

  @override
  State<WeeklyStatsSheet> createState() => _WeeklyStatsSheetState();
}

class _WeeklyStatsSheetState extends State<WeeklyStatsSheet> {
  late final Future<List<WeeklyStat>> _stats;

  @override
  void initState() {
    super.initState();
    _stats = _load();
  }

  Future<List<WeeklyStat>> _load() async {
    final entries = await widget.repository.getAll();
    return computeWeeklyStats(entries);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: NeumorphicContainer(
        key: const Key('weekly_stats_sheet'),
        color: AppColors.surface900,
        padding: EdgeInsets.zero,
        borderRadius: AppRadius.lg,
        child: SafeArea(
          top: false,
          child: FutureBuilder<List<WeeklyStat>>(
            future: _stats,
            builder: (context, snapshot) {
              final strings = LocalizationScope.stringsOf(context);
              final stats = snapshot.data;
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppHeading(strings.weeklyStats, size: AppHeadingSize.h3),
                    const SizedBox(height: AppSpacing.xs),
                    AppCaption(strings.weeklyStatsCaption),
                    const SizedBox(height: AppSpacing.lg),
                    if (stats == null)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      _WeeklySummary(stats: stats, strings: strings),
                      const SizedBox(height: AppSpacing.lg),
                      // M36 Task 1: labels come from the real stat dates
                      // (weekdayLabel), never a static list, so each bar is
                      // tagged with its exact weekday.
                      _WeeklyBalanceChart(stats: stats),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WeeklySummary extends StatelessWidget {
  const _WeeklySummary({required this.stats, required this.strings});

  final List<WeeklyStat> stats;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final consumed = stats.fold<int>(0, (sum, s) => sum + s.consumed);
    final burned = stats.fold<int>(0, (sum, s) => sum + s.burned);
    final balance = consumed - burned;
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            key: const Key('weekly_consumed_total'),
            title: strings.consumedLabel,
            value: strings.kcal(consumed),
            color: AppColors.primary400,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _SummaryTile(
            key: const Key('weekly_burned_total'),
            title: strings.burnedLabel,
            value: strings.kcal(burned),
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _SummaryTile(
            key: const Key('weekly_balance_total'),
            title: strings.balanceLabel,
            value: strings.signedKcal(balance),
            color: balance > 0 ? AppColors.warning : AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    super.key,
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Animated grouped bar chart: consumed (blue) and burned (green) per day.
class _WeeklyBalanceChart extends StatelessWidget {
  const _WeeklyBalanceChart({required this.stats});

  final List<WeeklyStat> stats;

  @override
  Widget build(BuildContext context) {
    var maxValue = 1;
    for (final stat in stats) {
      maxValue = math.max(maxValue, math.max(stat.consumed, stat.burned));
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < stats.length; i++)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _Bar(
                            key: Key('weekly_bar_consumed_$i'),
                            fraction: stats[i].consumed / maxValue * t,
                            color: AppColors.primary400,
                          ),
                          const SizedBox(width: 4),
                          _Bar(
                            key: Key('weekly_bar_burned_$i'),
                            fraction: stats[i].burned / maxValue * t,
                            color: AppColors.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppCaption(weekdayLabel(stats[i].date)),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({super.key, required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: math.max(2.0, fraction.clamp(0.0, 1.0) * 130),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sm),
        ),
      ),
    );
  }
}