import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/wizard_provider.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/typography.dart';

class WizardStepConfirm extends StatelessWidget {
  const WizardStepConfirm({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoutineWizardProvider>();
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
              color: AppColors.primary500.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeading('Review your profile', size: AppHeadingSize.h2),
            const SizedBox(height: AppSpacing.xl),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface900,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    icon: Icons.cake_outlined,
                    label: 'Age',
                    value: '${provider.age ?? '-'}',
                  ),
                  const Divider(height: 1, color: AppColors.surface700),
                  _SummaryRow(
                    icon: Icons.flag_outlined,
                    label: 'Goal',
                    value: provider.goal?.label ?? '-',
                  ),
                  const Divider(height: 1, color: AppColors.surface700),
                  _SummaryRow(
                    icon: Icons.fitness_center,
                    label: 'Level',
                    value: provider.fitnessLevel?.label ?? '-',
                  ),
                  const Divider(height: 1, color: AppColors.surface700),
                  _SummaryRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Days/week',
                    value: '${provider.availableDays ?? '-'}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCaption('Preferences: "${provider.preferencesPreview ?? '-'}"'),
            const SizedBox(height: AppSpacing.xxl),
            _GenerateButton(onPressed: provider.generateRoutine),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary400, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppText(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          AppText(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accent,
              AppColors.accent.withValues(alpha: 0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.40),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.textHigh),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'GENERATE MY ROUTINE',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppColors.textHigh),
            ),
          ],
        ),
      ),
    );
  }
}
