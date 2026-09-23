import 'package:flutter/material.dart';

import '../../core/data/daily_entry_repository.dart';
import '../../core/domain/i18n/app_strings.dart';
import '../../core/domain/i18n/localization_scope.dart';
import '../../core/models/weekly_stat.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/weekly_stats.dart';
import '../atoms/neumorphic_container.dart';
import '../atoms/typography.dart';
import 'weekly_balance_chart.dart';

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
                      // M47 Task 4: a single overlaid bar presents the weekly
                      // protein and fat metrics on top of the balance chart.
                      _MacroOverlay(stats: stats, strings: strings),
                      const SizedBox(height: AppSpacing.md),
                      // M36 Task 1: labels come from the real stat dates
                      // (weekdayLabel), never a static list, so each bar is
                      // tagged with its exact weekday.
                      WeeklyBalanceChart(stats: stats),
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

/// A single overlaid bar presenting the weekly protein and fat totals.
///
/// Rather than a separate row of tiles, the two macro metrics are folded into
/// one compact capsule that sits directly above the balance chart.
class _MacroOverlay extends StatelessWidget {
  const _MacroOverlay({required this.stats, required this.strings});

  final List<WeeklyStat> stats;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final protein = stats.fold<int>(0, (sum, s) => sum + s.protein);
    final fat = stats.fold<int>(0, (sum, s) => sum + s.fat);
    return Container(
      key: const Key('weekly_macro_overlay'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.primary500.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          AppCaption(strings.weeklyMacrosTitle),
          const Spacer(),
          _MacroChip(
            key: const Key('weekly_protein_overlay'),
            label: strings.proteinLabel,
            value: '${protein}g',
            color: AppColors.primary400,
          ),
          const SizedBox(width: AppSpacing.lg),
          _MacroChip(
            key: const Key('weekly_fat_overlay'),
            label: strings.fatLabel,
            value: '${fat}g',
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }
}

/// A compact colored-dot + value metric used inside the macro overlay.
class _MacroChip extends StatelessWidget {
  const _MacroChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppText(value, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(width: AppSpacing.xs),
        AppCaption(label),
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

