import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/wizard_provider.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/typography.dart';

class WizardStepDays extends StatelessWidget {
  const WizardStepDays({super.key});

  static const List<String> _dayAbbreviations = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoutineWizardProvider>();
    final days = provider.availableDays ?? 4;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface800,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.surface700, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary500.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeading('Days per week', size: AppHeadingSize.h2),
            const SizedBox(height: AppSpacing.sm),
            const AppText('How many days can you commit to training?'),
            const SizedBox(height: AppSpacing.xxl),
            Center(
              child: Column(
                children: [
                  Text(
                    '$days',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.primary500,
                    ),
                  ),
                  AppText('days', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Slider(
              min: 2,
              max: 6,
              divisions: 4,
              value: days.toDouble(),
              activeColor: AppColors.primary500,
              inactiveColor: AppColors.surface700,
              label: '$days days',
              onChanged: (value) => provider.setAvailableDays(value.round()),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < _dayAbbreviations.length; i++)
                  _DayChip(
                    label: _dayAbbreviations[i],
                    active: i < days,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.primary500 : AppColors.surface700,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: active ? AppColors.textHigh : AppColors.textLow,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
