import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'typography.dart';

/// Neumorphic segmented timeline selector for projection milestones.
class NeumorphicTimeline extends StatelessWidget {
  const NeumorphicTimeline({
    super.key,
    required this.selectedMonth,
    required this.onSelected,
  });

  final int selectedMonth;
  final ValueChanged<int> onSelected;

  static const List<(int, String)> _options = [
    (0, 'Now'),
    (1, '1m'),
    (3, '3m'),
    (6, '6m'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (month, label) in _options)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: GestureDetector(
                key: Key('timeline_$month'),
                onTap: () => onSelected(month),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: month == selectedMonth
                        ? AppColors.primary500
                        : AppColors.surface800,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: month == selectedMonth
                        ? const [NeumorphicStyles.innerShadow]
                        : const [
                            NeumorphicStyles.lightShadow,
                            NeumorphicStyles.darkShadow,
                          ],
                  ),
                  child: Center(child: AppText(label)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
