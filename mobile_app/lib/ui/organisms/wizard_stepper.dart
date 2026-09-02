import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/wizard_provider.dart';
import '../../core/theme/app_theme.dart';

class WizardStepper extends StatelessWidget {
  const WizardStepper({super.key});

  static const List<String> _labels = ['Age', 'Goal', 'Level', 'Days'];

  @override
  Widget build(BuildContext context) {
    final currentStep = context.watch<RoutineWizardProvider>().currentStep;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < _labels.length; i++) ...[
                if (i > 0)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: _Trail(completed: currentStep > i),
                    ),
                  ),
                _StepItem(
                  index: i,
                  label: _labels[i],
                  state: currentStep > i
                      ? _StepState.completed
                      : currentStep == i
                      ? _StepState.active
                      : _StepState.upcoming,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: currentStep / RoutineWizardProvider.totalSteps,
              minHeight: 4,
              backgroundColor: AppColors.surface700,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary500),
            ),
          ),
        ],
      ),
    );
  }
}

enum _StepState { completed, active, upcoming }

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.index,
    required this.label,
    required this.state,
  });

  final int index;
  final String label;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    final isCompleted = state == _StepState.completed;
    final isActive = state == _StepState.active;
    final circleColor = isCompleted
        ? AppColors.success
        : isActive
        ? AppColors.primary500
        : AppColors.surface700;
    return SizedBox(
      width: 52,
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primary300.withOpacity(0.6),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: isCompleted
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  )
                : Text(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isActive
                          ? AppColors.textHigh
                          : AppColors.textLow,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isActive || isCompleted
                  ? AppColors.textMedium
                  : AppColors.textLow,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _Trail extends StatelessWidget {
  const _Trail({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: completed ? AppColors.primary300 : AppColors.surface700,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );
  }
}
