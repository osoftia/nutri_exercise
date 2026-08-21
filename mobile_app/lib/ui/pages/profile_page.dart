import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../atoms/neumorphic_container.dart';
import '../atoms/typography.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const List<({String label, String value})> _mockStats = [
    (label: 'Weight', value: '78 kg'),
    (label: 'Height', value: '180 cm'),
    (label: 'Streak', value: '12 days'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        const AppHeading('Profile', size: AppHeadingSize.h2),
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: NeumorphicContainer(
            borderRadius: 56,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: const CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary500,
              child: Text(
                'AC',
                style: TextStyle(
                  color: AppColors.textHigh,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(child: AppText('Alex Carter')),
        Center(child: AppCaption('Muscle Gain')),
        const SizedBox(height: AppSpacing.xxl),
        for (final stat in _mockStats)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: NeumorphicContainer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(stat.label),
                  AppText(stat.value),
                ],
              ),
            ),
          ),
      ],
    );
  }
}