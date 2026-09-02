import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../atoms/typography.dart';

class SelectionTile extends StatelessWidget {
  const SelectionTile({
    super.key,
    required this.icon,
    required this.label,
    this.description,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? description;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary500.withValues(alpha: 0.12)
              : AppColors.surface900,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? AppColors.primary500 : AppColors.surface700,
            width: selected ? 2 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary500.withValues(alpha: 0.25),
                    blurRadius: 16,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 36,
                  color: selected ? AppColors.primary400 : AppColors.textLow,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: selected ? AppColors.textHigh : AppColors.textMedium,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AppText(
                    description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textLow,
                    ),
                  ),
                ],
              ],
            ),
            if (selected)
              Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
