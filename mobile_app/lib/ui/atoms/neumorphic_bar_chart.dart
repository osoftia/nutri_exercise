import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'typography.dart';

/// A neumorphic weekly bar chart: one bar per day, normalized against the
/// maximum weekly value.
class NeumorphicBarChart extends StatelessWidget {
  const NeumorphicBarChart({
    super.key,
    required this.values,
    required this.labels,
  });

  /// Seven values (one per weekday).
  final List<int> values;

  /// Seven weekday captions, aligned with [values].
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold<int>(0, (m, v) => v > m ? v : m);
    final safeMax = maxValue == 0 ? 1 : maxValue;
    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      key: Key('weekly_bar_$i'),
                      height: (values[i] / safeMax) * 100,
                      decoration: BoxDecoration(
                        color: AppColors.primary500.withValues(alpha: 0.6),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadius.sm),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppCaption(labels[i]),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
