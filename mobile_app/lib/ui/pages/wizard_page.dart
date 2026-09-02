import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/routine_provider.dart';
import '../../core/providers/wizard_provider.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/custom_button.dart';
import '../atoms/typography.dart';
import '../molecules/generated_routine_dialog.dart';
import '../molecules/generating_overlay.dart';
import '../molecules/wizard_step_age.dart';
import '../molecules/wizard_step_confirm.dart';
import '../molecules/wizard_step_days.dart';
import '../molecules/wizard_step_fitness.dart';
import '../molecules/wizard_step_goal.dart';
import '../organisms/wizard_nav_bar.dart';
import '../organisms/wizard_stepper.dart';

class WizardPage extends StatefulWidget {
  const WizardPage({super.key});

  @override
  State<WizardPage> createState() => _WizardPageState();
}

class _WizardPageState extends State<WizardPage> {
  late final RoutineWizardProvider _provider;
  bool _resultHandled = false;

  @override
  void initState() {
    super.initState();
    _provider = context.read<RoutineWizardProvider>();
    _provider.addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    super.dispose();
  }

  void _onProviderChanged() {
    if (_provider.status == WizardStatus.generating) {
      _resultHandled = false;
      return;
    }
    if (_provider.status == WizardStatus.generated && !_resultHandled) {
      _resultHandled = true;
      _showResultDialog();
    }
  }

  Future<void> _showResultDialog() async {
    final text = _provider.generatedText;
    if (text == null || !mounted) return;
    await showGeneratedRoutineDialog(
      context,
      text,
      data: _provider.wizardData,
      onApply: () {
        final routineProvider = context.read<RoutineProvider>();
        final wizardProvider = context.read<RoutineWizardProvider>();
        if (!mounted) return;
        Navigator.of(context).pop();
        routineProvider.loadRoutine();
        wizardProvider.reset();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Routine saved to your dashboard.')),
        );
      },
    );
  }

  void _handleBack(RoutineWizardProvider provider) {
    if (provider.status == WizardStatus.generating) return;
    if (provider.currentStep > 0) {
      provider.previousStep();
    } else {
      _confirmDiscard(provider);
    }
  }

  Future<void> _confirmDiscard(RoutineWizardProvider provider) async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const AppHeading('Discard your progress?', size: AppHeadingSize.h3),
        content: const AppText('Your wizard answers will be lost.'),
        actions: [
          CustomButton(
            label: 'Cancel',
            variant: CustomButtonVariant.ghost,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          CustomButton(
            label: 'Discard',
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      provider.reset();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoutineWizardProvider>();
    final isGenerating = provider.status == WizardStatus.generating;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(provider);
      },
      child: Scaffold(
        backgroundColor: AppColors.surface900,
        appBar: AppBar(
          backgroundColor: AppColors.surface900,
          leading: BackButton(
            color: AppColors.textMedium,
            onPressed: () => _handleBack(provider),
          ),
          title: const AppHeading('AI Routine Wizard', size: AppHeadingSize.h3),
        ),
        body: SafeArea(
          child: Column(
            children: [
              const WizardStepper(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildBody(provider),
                ),
              ),
              if (!isGenerating && provider.status != WizardStatus.error)
                const WizardNavBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(RoutineWizardProvider provider) {
    return switch (provider.status) {
      WizardStatus.generating => const GeneratingOverlay(),
      WizardStatus.error => _ErrorCard(provider: provider, onGoBack: _handleBack),
      _ => KeyedSubtree(
        key: ValueKey(provider.currentStep),
        child: switch (provider.currentStep) {
          0 => const WizardStepAge(),
          1 => const WizardStepGoal(),
          2 => const WizardStepFitness(),
          3 => const WizardStepDays(),
          _ => const WizardStepConfirm(),
        },
      ),
    };
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.provider, required this.onGoBack});

  final RoutineWizardProvider provider;
  final ValueChanged<RoutineWizardProvider> onGoBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surface700, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
          const SizedBox(height: AppSpacing.md),
          const AppHeading('Generation Failed', size: AppHeadingSize.h3),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: AppText(
              provider.error ?? 'Unknown error',
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          CustomButton(label: 'Try Again', onPressed: provider.generateRoutine),
          const SizedBox(height: AppSpacing.md),
          CustomButton(
            label: 'Go Back',
            variant: CustomButtonVariant.ghost,
            onPressed: () => onGoBack(provider),
          ),
        ],
      ),
    );
  }
}
