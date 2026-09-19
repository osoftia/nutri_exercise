import 'dart:ui';

import '../../../core/domain/body_projection/body_segment.dart';
import '../../../core/domain/body_projection/callout_layout_table.dart';
import 'body_segment_geometry.dart';

/// A resolved callout: its declarative slot plus the pixels it occupies.
class BodyCalloutPlacement {
  /// Creates a resolved placement.
  const BodyCalloutPlacement({
    required this.slot,
    required this.chipRect,
    required this.attach,
    required this.anchor,
  });

  /// The declarative rule this placement came from.
  final BodyCalloutSlot slot;

  /// The rectangle the chip occupies in the gutter.
  final Rect chipRect;

  /// The point on the chip's inner edge where the leader line ends.
  final Offset attach;

  /// The point on the segment where the leader line (and anchor dot) starts.
  final Offset anchor;

  /// The annotated segment.
  BodySegment get segment => slot.segment;

  /// The gutter this callout lives in.
  CalloutSide get side => slot.side;
}

/// Minimum square touch target for a chip (accessibility).
const double calloutMinTouchTarget = 48;

/// Minimum gutter width needed to render a chip.
const double _minGutterWidth = 88;

/// Resolves the declarative [bodyCalloutSlots] table into pixels for [size].
///
/// Slots are stacked evenly per gutter, so two callouts on the same side can
/// never overlap as long as the diagram is tall enough.
List<BodyCalloutPlacement> layoutBodyCallouts(Size size) {
  final figure = BodySegmentGeometry.figureRect(size);
  final placements = <BodyCalloutPlacement>[];

  for (final side in CalloutSide.values) {
    final slots = bodyCalloutSlots.where((s) => s.side == side).toList()
      ..sort((a, b) => a.slot.compareTo(b.slot));
    if (slots.isEmpty) continue;

    final gutter = side == CalloutSide.left
        ? Rect.fromLTRB(0, 0, (figure.left - 4).clamp(0.0, size.width), size.height)
        : Rect.fromLTRB(
            (figure.right + 4).clamp(0.0, size.width),
            0,
            size.width,
            size.height,
          );
    if (gutter.width < _minGutterWidth) continue;

    final slotHeight = size.height / slots.length;
    for (final slot in slots) {
      final centreY = (slot.slot + 0.5) * slotHeight;
      final top = (centreY - calloutMinTouchTarget / 2)
          .clamp(0.0, size.height - calloutMinTouchTarget);
      final chipRect = Rect.fromLTWH(
        gutter.left,
        top,
        gutter.width,
        calloutMinTouchTarget,
      );
      placements.add(
        BodyCalloutPlacement(
          slot: slot,
          chipRect: chipRect,
          attach: side == CalloutSide.left
              ? Offset(chipRect.right, chipRect.center.dy)
              : Offset(chipRect.left, chipRect.center.dy),
          anchor: BodySegmentGeometry.anchorFor(slot.segment, size),
        ),
      );
    }
  }

  return placements;
}

/// Builds the right-angled leader polyline from a callout anchor to its chip.
///
/// Elbows are strictly horizontal / vertical, giving the technical-drawing
/// feel required by the blueprint language.
Path buildLeaderPath(BodyCalloutPlacement placement, {double leadOut = 16}) {
  final direction = placement.side == CalloutSide.left ? -1.0 : 1.0;
  final elbowX = placement.anchor.dx + direction * leadOut;
  return Path()
    ..moveTo(placement.anchor.dx, placement.anchor.dy)
    ..lineTo(elbowX, placement.anchor.dy)
    ..lineTo(elbowX, placement.attach.dy)
    ..lineTo(placement.attach.dx, placement.attach.dy);
}
