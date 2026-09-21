import 'package:flutter/material.dart';

/// Lays out [CircularIconButton]s in a spaced-out row/wrap.
///
/// The generous [defaultSpacing] is the anti-saturation guardrail: it keeps
/// option clusters (calendar controls, symptom choices) breathable instead of
/// collapsing into an elongated pill strip.
class CircularIconButtonGroup extends StatelessWidget {
  /// Creates a spaced circular-button group.
  const CircularIconButtonGroup({
    super.key,
    required this.children,
    this.spacing = defaultSpacing,
    this.runSpacing = defaultSpacing,
    this.alignment = WrapAlignment.start,
  });

  /// Default gap between buttons.
  static const double defaultSpacing = 20;

  /// The buttons to lay out.
  final List<Widget> children;

  /// Horizontal gap between buttons.
  final double spacing;

  /// Vertical gap between wrapped runs.
  final double runSpacing;

  /// Alignment of each run.
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      children: children,
    );
  }
}
