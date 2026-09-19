import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A blueprint-styled floating action button.
///
/// Matches the technical-drawing language of the body diagram: a circular
/// `surface800` disc outlined in `primary500` with concentric registration
/// rings, used for secondary diagram actions such as opening History.
class BlueprintFab extends StatelessWidget {
  /// Creates a blueprint FAB.
  const BlueprintFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.history,
    this.tooltip = 'History',
    this.size = 52,
  });

  /// Invoked when the button is tapped.
  final VoidCallback onPressed;

  /// Glyph drawn inside the disc.
  final IconData icon;

  /// Accessible label and tooltip.
  final String tooltip;

  /// Overall diameter in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onPressed,
          child: SizedBox(
            width: size,
            height: size,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface800,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary500, width: 1.2),
                boxShadow: const [NeumorphicStyles.darkShadow],
              ),
              child: Center(
                child: Container(
                  width: size * 0.72,
                  height: size * 0.72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary500.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: AppColors.primary300,
                      size: size * 0.42,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
