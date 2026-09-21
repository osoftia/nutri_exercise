import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// A reusable circular icon button.
///
/// Replaces elongated pill controls in dense option clusters (calendar
/// navigation, symptom tracking, action rails). Each action gets a clear
/// graphic glyph inside a generously padded circular hit target, and explains
/// its exact function in a long-press tooltip.
class CircularIconButton extends StatelessWidget {
  /// Creates a circular icon button.
  const CircularIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.selected = false,
    this.size = defaultSize,
    this.selectedColor = AppColors.primary500,
    this.semanticLabel,
  });

  /// Minimum diameter: the Material 48 dp tap target with extra breathing room
  /// so adjacent buttons never feel crowded.
  static const double minimumSize = 56;

  /// Default diameter in logical pixels.
  static const double defaultSize = 56;

  /// Padding between the disc edge and the glyph.
  static const double defaultPadding = 16;

  /// Glyph drawn inside the disc.
  final IconData icon;

  /// Long-press tooltip explaining the button's exact function.
  final String tooltip;

  /// Invoked when tapped; `null` disables the button.
  final VoidCallback? onPressed;

  /// Whether this option is currently active.
  final bool selected;

  /// Overall diameter in logical pixels (clamped to [minimumSize]).
  final double size;

  /// Fill colour used while [selected].
  final Color selectedColor;

  /// Overrides the accessibility label when it should differ from [tooltip].
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final diameter = size < minimumSize ? minimumSize : size;
    final enabled = onPressed != null;
    final iconColor = selected
        ? AppColors.textHigh
        : (enabled ? AppColors.textMedium : AppColors.textLow);

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: semanticLabel ?? tooltip,
      child: Tooltip(
        message: tooltip,
        triggerMode: TooltipTriggerMode.longPress,
        preferBelow: false,
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: Material(
            color: selected ? selectedColor : AppColors.surface800,
            shape: CircleBorder(
              side: BorderSide(
                color: selected ? selectedColor : AppColors.surface700,
                width: selected ? 2 : 1.2,
              ),
            ),
            elevation: selected ? 4 : 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.all(defaultPadding),
                child: Icon(
                  icon,
                  size: diameter - defaultPadding * 2,
                  color: iconColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
