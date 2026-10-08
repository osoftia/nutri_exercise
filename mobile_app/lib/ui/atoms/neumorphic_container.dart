import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/theme/app_design_tokens.dart';
import '../../core/theme/app_theme.dart';

/// Reusable neumorphic surface: a soft raised card with a light top-left
/// highlight and a dark bottom-right drop shadow (see [NeumorphicStyles]).
class NeumorphicContainer extends StatelessWidget {
  const NeumorphicContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.borderRadius,
    this.color,
    this.inset = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? borderRadius;
  final Color? color;

  /// When true, renders the "pressed" inset shadow instead of the raised pair.
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppDesignTokens>();
    final radius = borderRadius ?? tokens?.cardRadius ?? AppRadius.lg;
    final surfaceColor = color ?? tokens?.cardColor ?? AppColors.surface800;
    final shadows = inset
        ? (tokens?.insetShadows ?? const [NeumorphicStyles.innerShadow])
        : (tokens?.cardShadows ??
            const [
              NeumorphicStyles.lightShadow,
              NeumorphicStyles.darkShadow,
            ]);
    final surface = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(radius),
        border: tokens == null || tokens.cardBorderColor == Colors.transparent
            ? null
            : Border.all(color: tokens.cardBorderColor),
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
    if (tokens?.frostedGlass != true) return surface;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: surface,
      ),
    );
  }
}
