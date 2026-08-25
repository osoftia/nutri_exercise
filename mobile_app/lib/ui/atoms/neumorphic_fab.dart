import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'neumorphic_container.dart';

/// A neumorphic circular floating action button built on [NeumorphicContainer].
///
/// Reuses the raised light/dark shadow pair so the button matches the rest of
/// the "blue gym" neumorphic design language.
class NeumorphicFab extends StatelessWidget {
  const NeumorphicFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.smart_toy_outlined,
    this.tooltip = 'Ask AI',
    this.size = 56,
    this.color = AppColors.primary500,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;
  final double size;
  final Color color;

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
            child: NeumorphicContainer(
              padding: EdgeInsets.zero,
              borderRadius: size / 2,
              color: color,
              child: Center(
                child: Icon(icon, color: AppColors.textHigh, size: size * 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
