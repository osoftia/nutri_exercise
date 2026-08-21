import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Reusable neumorphic surface: a soft raised card with a light top-left
/// highlight and a dark bottom-right drop shadow (see [NeumorphicStyles]).
class NeumorphicContainer extends StatelessWidget {
  const NeumorphicContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.borderRadius = AppRadius.lg,
    this.color = AppColors.surface800,
    this.inset = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color color;

  /// When true, renders the "pressed" inset shadow instead of the raised pair.
  final bool inset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: inset
            ? const [NeumorphicStyles.innerShadow]
            : const [
                NeumorphicStyles.lightShadow,
                NeumorphicStyles.darkShadow,
              ],
      ),
      child: child,
    );
  }
}