import 'package:flutter/material.dart';

import '../../../core/domain/body_projection/body_diagram_view_model.dart';
import '../../../core/domain/body_projection/body_segment.dart';
import 'body_blueprint_painter.dart';
import 'body_callout_chip.dart';
import 'body_segment_geometry.dart';
import 'callout_placement.dart';

/// The interactive blueprint diagram: schematic figure plus gutter callouts.
///
/// Segment thicknesses animate toward the [BodyDiagramViewModel]'s scale
/// factors, so tamagotchi muscle growth, stomach bloat and projection changes
/// morph the figure smoothly. The widget owns no business state.
class BodyBlueprintDiagram extends StatefulWidget {
  /// Creates a diagram for [viewModel].
  const BodyBlueprintDiagram({
    super.key,
    required this.viewModel,
    this.onSegmentSelected,
    this.animationDuration = const Duration(milliseconds: 400),
    this.showCallouts = true,
  });

  /// The immutable snapshot to render.
  final BodyDiagramViewModel viewModel;

  /// Called with the segment whose body or callout was tapped.
  final ValueChanged<BodySegment>? onSegmentSelected;

  /// How long segment thicknesses take to animate to their new values.
  final Duration animationDuration;

  /// Whether to overlay the gutter callout chips. Hidden on compact surfaces
  /// (e.g. the Nutrition avatar) that only need the articulated figure.
  final bool showCallouts;

  @override
  State<BodyBlueprintDiagram> createState() => _BodyBlueprintDiagramState();
}

class _BodyBlueprintDiagramState extends State<BodyBlueprintDiagram>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.animationDuration,
    value: 1,
  );

  late Map<BodySegment, double> _from = widget.viewModel.scaleFactors;
  late Map<BodySegment, double> _to = widget.viewModel.scaleFactors;

  @override
  void didUpdateWidget(covariant BodyBlueprintDiagram oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_scalesEqual(
      oldWidget.viewModel.scaleFactors,
      widget.viewModel.scaleFactors,
    )) {
      _from = _interpolatedScales(_controller.value);
      _to = widget.viewModel.scaleFactors;
      _controller.forward(from: 0);
    } else {
      _to = widget.viewModel.scaleFactors;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Map<BodySegment, double> _interpolatedScales(double t) {
    final keys = {..._from.keys, ..._to.keys};
    return {
      for (final key in keys)
        key: _lerp(_from[key] ?? 1.0, _to[key] ?? 1.0, t),
    };
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  bool _scalesEqual(
    Map<BodySegment, double> a,
    Map<BodySegment, double> b,
  ) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 320,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 320,
        );
        final placements = layoutBodyCallouts(size);

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final viewModel = widget.viewModel.copyWith(
              scaleFactors: _interpolatedScales(_controller.value),
            );
            return Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  key: const Key('body_blueprint_canvas'),
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    final segment = BodySegmentGeometry.hitTest(
                      details.localPosition,
                      size,
                      scaleFor: viewModel.scaleFor,
                    );
                    if (segment != null) {
                      widget.onSegmentSelected?.call(segment);
                    }
                  },
                  child: CustomPaint(
                    key: const Key('body_blueprint_paint'),
                    painter: BodyBlueprintPainter(viewModel: viewModel),
                  ),
                ),
                if (widget.showCallouts)
                  for (final placement in placements)
                    Positioned.fromRect(
                      rect: placement.chipRect,
                      child: BodyCalloutChip(
                        key: Key('callout_${placement.segment.name}'),
                        callout: viewModel.calloutFor(placement.segment) ??
                            BodyCallout(
                              segment: placement.segment,
                              label: placement.segment.name,
                              value: '—',
                            ),
                        status: viewModel.statusFor(placement.segment),
                        onTap: () =>
                            widget.onSegmentSelected?.call(placement.segment),
                      ),
                    ),
              ],
            );
          },
        );
      },
    );
  }
}
