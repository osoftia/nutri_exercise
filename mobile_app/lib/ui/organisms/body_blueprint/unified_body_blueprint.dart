import 'package:flutter/material.dart';

import '../../../core/domain/body_projection/body_diagram_view_model.dart';
import '../../../core/domain/body_projection/body_segment.dart';
import 'body_blueprint_diagram.dart';

/// The single shared, articulated body figure used by **both** the Routines and
/// Nutrition tabs.
///
/// It wraps [BodyBlueprintDiagram], which owns the blueprint styling and the
/// responsive, aspect-preserving geometry (split limbs with elbow/knee joint
/// gaps, per-segment status colouring and animated mass scaling). The Nutrition
/// tab hides the gutter callouts because it only needs the figure; the Routines
/// tab keeps them.
class UnifiedBodyBlueprint extends StatelessWidget {
  /// Creates the shared blueprint figure for [viewModel].
  const UnifiedBodyBlueprint({
    super.key,
    required this.viewModel,
    this.onSegmentSelected,
    this.showCallouts = true,
    this.animationDuration = const Duration(milliseconds: 400),
  });

  /// The immutable snapshot to render.
  final BodyDiagramViewModel viewModel;

  /// Called with the segment whose body or callout was tapped.
  final ValueChanged<BodySegment>? onSegmentSelected;

  /// Whether to overlay the gutter callout chips.
  final bool showCallouts;

  /// How long segment thicknesses take to animate to their new values.
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    return BodyBlueprintDiagram(
      key: const Key('unified_body_blueprint'),
      viewModel: viewModel,
      onSegmentSelected: onSegmentSelected,
      showCallouts: showCallouts,
      animationDuration: animationDuration,
    );
  }
}
