import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../atoms/typography.dart';
import 'shimmer_loading.dart';

class GeneratingOverlay extends StatelessWidget {
  const GeneratingOverlay({super.key});

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
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShimmerLoading(),
          SizedBox(height: AppSpacing.xxl),
          CircularProgressIndicator(
            color: AppColors.primary500,
            strokeWidth: 3,
          ),
          SizedBox(height: AppSpacing.lg),
          AppHeading('Generating your routine...', size: AppHeadingSize.h3),
          AppText('AI is crafting your personalized plan'),
        ],
      ),
    );
  }
}
