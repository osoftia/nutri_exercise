import 'package:flutter/material.dart';

import '../../core/state/muscle_tamagotchi_state.dart';
import '../../core/theme/app_theme.dart';
import '../atoms/typography.dart';
import 'interactive_body_map.dart';

/// Polished vertical "Instagram Story" share card.
///
/// The card content is wrapped in a [RepaintBoundary] keyed by [repaintKey] so
/// [WidgetToImageExporter] can capture it. It shows the user's
/// [InteractiveBodyMap] (with current muscle colors / bloat), the current
/// streak count (🔥) and a motivational summary.
class SocialShareCard extends StatelessWidget {
  const SocialShareCard({
    super.key,
    required this.repaintKey,
    required this.tamagotchiState,
    required this.streak,
    this.bodyWidthFactor = 1.0,
    this.motivationalMessage,
  });

  /// GlobalKey attached to the [RepaintBoundary] for image capture.
  final GlobalKey repaintKey;

  final MuscleTamagotchiState tamagotchiState;
  final int streak;

  /// Baseline body width factor forwarded to the body map.
  final double bodyWidthFactor;

  /// Optional motivational summary; defaults to a streak-based message.
  final String? motivationalMessage;

  /// Design size of the card (9:16 story ratio).
  static const double width = 360;
  static const double height = 640;

  String get _motivation {
    final explicit = motivationalMessage;
    if (explicit != null) return explicit;
    if (streak >= 7) return '¡Imparable! Sigue construyendo tu mejor versión 💪';
    if (streak >= 3) return '¡Gran racha! Un día más y sumas otra llama 🔥';
    if (streak == 1) return '¡Primer día! El comienzo de algo grande 🚀';
    return 'Empieza hoy: entrena y come sano para encender tu racha 🔥';
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: repaintKey,
      child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surface900, AppColors.primary600],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeading('Mi Progreso', size: AppHeadingSize.h3),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: Center(
                child: InteractiveBodyMap(
                  tamagotchiState: tamagotchiState,
                  bodyWidthFactor: bodyWidthFactor,
                  animate: false,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('🔥', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '$streak días',
                  key: const Key('streak_count'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _motivation,
              key: const Key('motivational_message'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}