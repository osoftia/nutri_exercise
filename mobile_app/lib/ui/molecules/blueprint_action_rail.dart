import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../atoms/blueprint_fab.dart';

/// The standardized vertical rail of circular blueprint actions positioned
/// beside the unified body figure.
///
/// Both the Routines and Nutrition tabs render the same rail: an optional
/// History FAB plus the tab's summary action (Daily Routine Summary / Daily
/// Nutrition Summary). It collapses to nothing when no action is available.
class BlueprintActionRail extends StatelessWidget {
  /// Creates an action rail.
  const BlueprintActionRail({
    super.key,
    this.showHistory = true,
    this.historyKey,
    this.onHistory,
    this.historyTooltip = 'History',
    this.summaryKey,
    this.onSummary,
    this.summaryTooltip = 'Summary',
    this.summaryIcon = Icons.description_outlined,
  });

  /// Whether the History FAB is part of the rail.
  final bool showHistory;

  /// Key applied to the History FAB (e.g. `body_history_fab`).
  final Key? historyKey;

  /// History FAB callback; required when [showHistory] is true.
  final VoidCallback? onHistory;

  /// Tooltip / semantic label of the History FAB.
  final String historyTooltip;

  /// Key applied to the summary FAB.
  final Key? summaryKey;

  /// Summary FAB callback; the FAB is hidden when null.
  final VoidCallback? onSummary;

  /// Tooltip / semantic label of the summary FAB.
  final String summaryTooltip;

  /// Glyph drawn inside the summary FAB.
  final IconData summaryIcon;

  @override
  Widget build(BuildContext context) {
    final history = showHistory && onHistory != null;
    final summary = onSummary != null;
    if (!history && !summary) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (history)
          BlueprintFab(
            key: historyKey,
            icon: Icons.history,
            tooltip: historyTooltip,
            onPressed: onHistory!,
          ),
        if (history && summary) const SizedBox(height: AppSpacing.md),
        if (summary)
          BlueprintFab(
            key: summaryKey,
            icon: summaryIcon,
            tooltip: summaryTooltip,
            onPressed: onSummary!,
          ),
      ],
    );
  }
}
