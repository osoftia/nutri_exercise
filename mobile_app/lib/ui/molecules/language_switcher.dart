import 'package:flutter/material.dart';

import '../../core/domain/i18n/app_language.dart';
import '../../core/domain/i18n/localization_scope.dart';
import '../../core/state/language_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/neumorphic_container.dart';
import '../atoms/typography.dart';

/// Reactive language switcher: one button per supported [AppLanguage].
///
/// Tapping a language calls [LanguageController.setLanguage], which notifies
/// listeners so the whole app (and this switcher's own labels) rebuild in place
/// — instant runtime switching, no restart.
class LanguageSwitcher extends StatelessWidget {
  /// Creates a switcher bound to [controller].
  const LanguageSwitcher({super.key, required this.controller});

  /// Owns the active language.
  final LanguageController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final strings = LocalizationScope.stringsOf(context);
        return NeumorphicContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText(
                strings.languageSectionTitle,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppCaption(strings.languageSectionSubtitle),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final language in AppLanguage.supported)
                    _LanguageChip(
                      key: Key('language_option_${language.code}'),
                      label: strings.languageName(language),
                      selected: controller.language == language,
                      onPressed: () => controller.setLanguage(language),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected
              ? AppColors.primary500.withValues(alpha: 0.22)
              : Colors.transparent,
          foregroundColor:
              selected ? AppColors.textHigh : AppColors.textMedium,
          side: BorderSide(
            color: selected ? AppColors.primary400 : AppColors.surface700,
            width: selected ? 1.4 : 1,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

/// Localizes the section heading used above the [LanguageSwitcher].
class LanguageSectionHeading extends StatelessWidget {
  /// Creates a localized heading.
  const LanguageSectionHeading({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = LocalizationScope.stringsOf(context);
    return AppText(
      strings.languageSectionTitle,
      style: const TextStyle(fontWeight: FontWeight.w700),
    );
  }
}
