import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/models/weekly_stat.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/weekly_stats.dart';
import '../atoms/typography.dart';

/// Animated grouped bar chart: consumed (blue) and burned (green) per day.
///
/// Extracted from `weekly_stats_sheet.dart` (M48 decomposition).
class WeeklyBalanceChart extends StatelessWidget {
  /// Creates the balance chart for [stats].
  const WeeklyBalanceChart({super.key, required this.stats});

  /// The seven daily stats, oldest first.
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
                      // M36 Task 1: labels come from the real stat dates, never
                      // a static list, so each bar is tagged with its weekday.
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
