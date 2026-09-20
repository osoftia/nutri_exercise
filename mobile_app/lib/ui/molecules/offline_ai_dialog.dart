import 'package:flutter/material.dart';

import '../../core/domain/i18n/localization_scope.dart';
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
    final strings = LocalizationScope.stringsOf(context);
    return AlertDialog(
      backgroundColor: AppColors.surface800,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      icon: const Icon(Icons.cloud_off, color: AppColors.primary400, size: 40),
      title: AppHeading(strings.offlineAiTitle, size: AppHeadingSize.h3),
      content: AppText(strings.offlineAiBody),
      actions: [
        CustomButton(
          label: strings.gotItButton,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
