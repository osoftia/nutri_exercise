import 'package:flutter/material.dart';

import '../../core/domain/i18n/app_strings.dart';
import '../../core/domain/i18n/localization_scope.dart';
import '../../core/models/symptom_log.dart';
import '../../core/state/symptom_controller.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/circular_icon_button.dart';
import '../atoms/neumorphic_container.dart';
import '../atoms/typography.dart';
import 'circular_icon_button_group.dart';

/// Daily symptom tracking view.
///
/// Each symptom is a spaced-out [CircularIconButton] with a graphic glyph and a
/// long-press tooltip; tapping cycles its severity (`none → mild → moderate →
/// severe → none`) and persists the reading through [controller].
class SymptomTracker extends StatelessWidget {
  /// Creates the symptom tracker for [controller].
  const SymptomTracker({
    super.key,
    required this.controller,
    this.icons = defaultIcons,
  });

  /// Default glyph per symptom kind.
  static const Map<SymptomType, IconData> defaultIcons = {
    SymptomType.pain: Icons.healing,
    SymptomType.discomfort: Icons.accessibility_new,
    SymptomType.energy: Icons.bolt,
    SymptomType.stress: Icons.self_improvement,
  };

  /// The controller owning the day's severities.
  final SymptomController controller;

  /// Overridable glyph mapping (tests / future theming).
  final Map<SymptomType, IconData> icons;

  @override
  Widget build(BuildContext context) {
    final strings = LocalizationScope.stringsOf(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return NeumorphicContainer(
          key: const Key('symptom_tracker'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText(strings.symptomTrackerTitle),
              const SizedBox(height: AppSpacing.sm),
              AppCaption(strings.symptomTrackerSubtitle),
              const SizedBox(height: AppSpacing.xl),
              CircularIconButtonGroup(
                children: [
                  for (final type in SymptomType.values)
                    CircularIconButton(
                      key: Key('symptom_${type.name}'),
                      icon: icons[type] ?? Icons.circle,
                      tooltip: strings.symptomTooltip(type),
                      selected: controller.levelOf(type) > 0,
                      onPressed: () => controller.cycle(type),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _buildLevelReadout(context, strings),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLevelReadout(BuildContext context, AppStrings strings) {
    if (!controller.hasAnyLogged) {
      return AppCaption(strings.symptomNoneLogged);
    }
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.sm,
      children: [
        for (final type in controller.loggedTypes)
          AppCaption(
            '${strings.symptomLabel(type)}: '
            '${strings.symptomLevel(controller.levelOf(type))}',
          ),
      ],
    );
  }
}
