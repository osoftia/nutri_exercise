import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../atoms/circular_icon_button.dart';
import '../atoms/typography.dart';

/// Clean month header shared by the Schedule calendar and the history popup.
///
/// A centered month label sits in a subtle pill between two circular
/// navigation buttons, matching the app's spaced-out circular control language.
class CalendarMonthHeader extends StatelessWidget {
  /// Creates a month header.
  const CalendarMonthHeader({
    super.key,
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.previousTooltip,
    required this.nextTooltip,
    this.previousKey,
    this.nextKey,
    this.labelKey,
    this.buttonSize = 52,
  });

  /// Localized month + year label.
  final String label;

  /// Invoked by the previous-month button.
  final VoidCallback onPrevious;

  /// Invoked by the next-month button.
  final VoidCallback onNext;

  /// Long-press tooltip for the previous button.
  final String previousTooltip;

  /// Long-press tooltip for the next button.
  final String nextTooltip;

  /// Key for the previous button (for tests).
  final Key? previousKey;

  /// Key for the next button (for tests).
  final Key? nextKey;

  /// Key for the centered month label (for tests).
  final Key? labelKey;

  /// Diameter of the navigation buttons.
  final double buttonSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircularIconButton(
          key: previousKey,
          icon: Icons.chevron_left,
          tooltip: previousTooltip,
          size: buttonSize,
          onPressed: onPrevious,
        ),
        Expanded(
          child: Center(
            child: Container(
              key: const Key('calendar_month_pill'),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface800,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: AppColors.primary500.withValues(alpha: 0.25),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AppText(
                  label,
                  key: labelKey,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
          ),
        ),
        CircularIconButton(
          key: nextKey,
          icon: Icons.chevron_right,
          tooltip: nextTooltip,
          size: buttonSize,
          onPressed: onNext,
        ),
      ],
    );
  }
}
