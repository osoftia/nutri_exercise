import 'package:flutter/material.dart';

import '../../core/domain/clinical/clinical_condition.dart';
import '../../core/domain/clinical/clinical_safety_verdict.dart';
import '../../core/domain/i18n/localization_scope.dart';
import '../../core/theme/app_theme.dart';

/// Colored, explainable food card driven by a clinical safety verdict.
class ClinicalFoodSafetyBadge extends StatelessWidget {
  const ClinicalFoodSafetyBadge({
    super.key,
    required this.verdict,
    this.child,
    this.cardKey,
  });

  final ClinicalSafetyVerdict verdict;
  final Widget? child;
  final Key? cardKey;

  Color get _color => switch (verdict.level) {
        ClinicalVerdictLevel.warning => Colors.redAccent,
        ClinicalVerdictLevel.beneficial => Colors.greenAccent,
        ClinicalVerdictLevel.unassessed => Colors.amberAccent,
        ClinicalVerdictLevel.safe => AppColors.primary300,
      };

  IconData get _icon => switch (verdict.level) {
        ClinicalVerdictLevel.warning => Icons.warning_amber_rounded,
        ClinicalVerdictLevel.beneficial => Icons.verified_outlined,
        ClinicalVerdictLevel.unassessed => Icons.help_outline,
        ClinicalVerdictLevel.safe => Icons.check_circle_outline,
      };

  @override
  Widget build(BuildContext context) {
    final isSpanish = LocalizationScope.languageOf(context).name == 'spanish';
    final borderColor = _color;
    return Container(
      key: cardKey ?? const Key('clinical_food_safety_card'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.055),
        border: Border.all(color: borderColor, width: 1.4),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: verdict.level == ClinicalVerdictLevel.beneficial
            ? [
                BoxShadow(
                  color: _color.withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(_icon, color: _color, size: 18),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  isSpanish ? verdict.level.labelEs : verdict.level.label,
                  style: TextStyle(
                    color: _color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          for (final finding in verdict.findings) ...[
            const SizedBox(height: 3),
            Text(
              '${finding.condition.labelFor(LocalizationScope.languageOf(context))}: ${finding.reason}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMedium,
                  ),
            ),
          ],
          if (child != null) ...[
            const SizedBox(height: AppSpacing.xs),
            child!,
          ],
        ],
      ),
    );
  }
}
