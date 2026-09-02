import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/wizard_provider.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/typography.dart';

class WizardStepAge extends StatefulWidget {
  const WizardStepAge({super.key});

  @override
  State<WizardStepAge> createState() => _WizardStepAgeState();
}

class _WizardStepAgeState extends State<WizardStepAge> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<RoutineWizardProvider>();
    _controller = TextEditingController(text: provider.age?.toString() ?? '');
    _focusNode.addListener(() {
      setState(() {
        _focused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String? _validationMessage(String text) {
    final age = int.tryParse(text);
    if (text.isEmpty) return null;
    if (age == null || age < 14 || age > 80) {
      return 'Please enter an age between 14 and 80.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoutineWizardProvider>();
    final validationMessage = _validationMessage(_controller.text);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface800,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.surface700, width: 1),
          boxShadow: [
            BoxShadow(
              color: _focused
                  ? AppColors.primary500.withValues(alpha: 0.08)
                  : AppColors.primary500.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeading('How old are you?', size: AppHeadingSize.h2),
            const SizedBox(height: AppSpacing.sm),
            const AppText('We use your age to calibrate intensity.'),
            const SizedBox(height: AppSpacing.xxl),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.primary500,
                  ),
                  onChanged: (value) {
                    provider.setAge(int.tryParse(value) ?? 0);
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.surface900,
                    hintText: '25',
                    hintStyle: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.textLow,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.lg,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.surface700),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.surface700),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(
                        color: AppColors.primary500,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (validationMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Center(
                child: AppText(
                  validationMessage,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
