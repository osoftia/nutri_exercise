import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/wizard_models.dart';
import '../../core/providers/wizard_provider.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/typography.dart';
import 'selection_tile.dart';

class WizardStepGoal extends StatelessWidget {
  const WizardStepGoal({super.key});

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
            const AppHeading('What is your goal?', size: AppHeadingSize.h2),
            const SizedBox(height: AppSpacing.sm),
            const AppText('Choose the outcome that matters most.'),
            const SizedBox(height: AppSpacing.xxl),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              children: [
                for (final goal in FitnessGoal.values)
                  SelectionTile(
                    icon: goal.icon,
                    label: goal.label,
                    selected: provider.goal == goal,
                    onTap: () => provider.setGoal(goal),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
