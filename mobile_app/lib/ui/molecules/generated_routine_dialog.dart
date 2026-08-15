import 'package:flutter/material.dart';

import '../../core/models/wizard_models.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/custom_button.dart';
import '../atoms/typography.dart';

Future<void> showGeneratedRoutineDialog(
  BuildContext context,
  String text, {
  WizardData? data,
  VoidCallback? onApply,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) =>
        GeneratedRoutineDialog(text: text, data: data, onApply: onApply),
  );
}

class GeneratedRoutineDialog extends StatelessWidget {
  const GeneratedRoutineDialog({
    super.key,
    required this.text,
    this.data,
    this.onApply,
  });

  final String text;
  final WizardData? data;
  final VoidCallback? onApply;

  @override
  Widget build(BuildContext context) {
    final apply = onApply;
    return AlertDialog(
      backgroundColor: AppColors.surface800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      icon: const Icon(
        Icons.smart_toy_outlined,
        color: AppColors.primary400,
        size: 40,
      ),
      title: const AppHeading('Generated Routine', size: AppHeadingSize.h3),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data != null) ...[
                AppCaption(data!.toPreferencesString()),
                const SizedBox(height: AppSpacing.lg),
              ],
              AppText(text),
            ],
          ),
        ),
      ),
      actions: [
        CustomButton(
          label: 'Close',
          variant: CustomButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
        if (apply != null)
          CustomButton(
            label: 'Apply to Dashboard',
            variant: CustomButtonVariant.accent,
            onPressed: () {
              Navigator.of(context).pop();
              apply();
            },
          ),
      ],
    );
  }
}
