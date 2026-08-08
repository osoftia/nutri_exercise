import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../atoms/custom_button.dart';
import '../atoms/typography.dart';

Future<void> showOfflineAiDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const OfflineAiDialog(),
  );
}

class OfflineAiDialog extends StatelessWidget {
  const OfflineAiDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      icon: const Icon(Icons.cloud_off, color: AppColors.primary400, size: 40),
      title: const AppHeading('Offline AI', size: AppHeadingSize.h3),
      content: const AppText(
        'To consult the AI, please connect to the internet.',
      ),
      actions: [
        CustomButton(
          label: 'Got it',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
