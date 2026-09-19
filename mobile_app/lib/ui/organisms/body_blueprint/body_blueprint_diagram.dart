import 'package:flutter/material.dart';

import '../../../core/domain/body_projection/body_diagram_view_model.dart';
import '../../../core/domain/body_projection/body_segment.dart';
import 'body_blueprint_painter.dart';
import 'body_callout_chip.dart';
import 'body_segment_geometry.dart';
import 'callout_placement.dart';

/// The interactive blueprint diagram: schematic figure plus gutter callouts.
///
/// The widget owns no business state (`StatelessWidget`) — it maps taps to
/// [BodySegment]s via [BodySegmentGeometry.hitTest] and reports them through
/// [onSegmentSelected], which the host uses to open the detail popup. Both the
/// segment tap and the matching callout tap report the same segment.
class BodyBlueprintDiagram extends StatelessWidget {
  /// Creates a diagram for [viewModel].
  const BodyBlueprintDiagram({
    super.key,
    required this.viewModel,
    this.onSegmentSelected,
  });

  /// The immutable snapshot to render.
  final BodyDiagramViewModel viewModel;

  /// Called with the segment whose body or callout was tapped.
  final ValueChanged<BodySegment>? onSegmentSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 320,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 320,
        );
        final placements = layoutBodyCallouts(size);

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
                if (segment != null) onSegmentSelected?.call(segment);
              },
              child: CustomPaint(
                painter: BodyBlueprintPainter(viewModel: viewModel),
              ),
            ),
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
                  onTap: () => onSegmentSelected?.call(placement.segment),
                ),
              ),
          ],
        );
      },
    );
  }
}
