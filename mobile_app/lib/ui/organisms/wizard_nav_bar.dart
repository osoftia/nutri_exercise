import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/wizard_provider.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/custom_button.dart';

class WizardNavBar extends StatelessWidget {
  const WizardNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoutineWizardProvider>();
    final isOnConfirmStep = provider.isOnConfirmStep;
    return Container(
      color: AppColors.surface900,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomButton(
            label: 'Back',
            variant: CustomButtonVariant.ghost,
            onPressed: provider.canGoBack ? provider.previousStep : null,
            disabled: !provider.canGoBack,
          ),
          if (isOnConfirmStep)
            CustomButton(
              label: 'Generate',
              variant: CustomButtonVariant.accent,
              onPressed: provider.generateRoutine,
            )
          else
            CustomButton(
              label: provider.currentStep < 3 ? 'Next' : 'Review',
              onPressed: provider.canGoForward ? provider.nextStep : null,
              disabled: !provider.canGoForward,
            ),
        ],
      ),
    );
  }
}
