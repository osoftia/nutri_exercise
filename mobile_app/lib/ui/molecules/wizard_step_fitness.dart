import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/wizard_models.dart';
import '../../core/providers/wizard_provider.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/typography.dart';

class WizardStepFitness extends StatelessWidget {
  const WizardStepFitness({super.key});

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
              color: AppColors.primary500.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeading('Your fitness level', size: AppHeadingSize.h2),
            const SizedBox(height: AppSpacing.sm),
            const AppText('Be honest — this shapes volume and load.'),
            const SizedBox(height: AppSpacing.xxl),
            for (final level in FitnessLevel.values) ...[
              if (level != FitnessLevel.values.first)
                const SizedBox(height: AppSpacing.md),
              _FitnessOptionCard(
                level: level,
                selected: provider.fitnessLevel == level,
                onTap: () => provider.setFitnessLevel(level),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FitnessOptionCard extends StatelessWidget {
  const _FitnessOptionCard({
    required this.level,
    required this.selected,
    this.onTap,
  });

  final FitnessLevel level;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary500.withOpacity(0.10)
              : AppColors.surface900,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.primary500 : AppColors.surface700,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              level.icon,
              color: selected ? AppColors.primary400 : AppColors.textLow,
              size: 28,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeading(level.label, size: AppHeadingSize.h3),
                  AppText(level.description),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.success),
          ],
        ),
      ),
    );
  }
}
