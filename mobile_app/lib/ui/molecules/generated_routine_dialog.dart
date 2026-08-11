import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../atoms/custom_button.dart';
import '../atoms/typography.dart';

Future<void> showGeneratedRoutineDialog(BuildContext context, String text) {
  return showDialog<void>(
    context: context,
    builder: (context) => GeneratedRoutineDialog(text: text),
  );
}

class GeneratedRoutineDialog extends StatelessWidget {
  const GeneratedRoutineDialog({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      icon: const Icon(Icons.smart_toy_outlined,
          color: AppColors.primary400, size: 40),
      title: const AppHeading('Generated Routine', size: AppHeadingSize.h3),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: AppText(text),
        ),
      ),
      actions: [
        CustomButton(
          label: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
