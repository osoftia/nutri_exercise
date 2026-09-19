import 'body_segment.dart';

/// The gutter a blueprint callout is anchored to.
enum CalloutSide {
  /// Left-hand annotation gutter.
  left,

  /// Right-hand annotation gutter.
  right,
}

/// A declarative placement rule for a single blueprint callout.
///
/// The [slot] is the zero-based vertical position within its [side]; the
/// painter/widget derive the actual pixels from it, so no developer ever
/// hand-tunes coordinates for a callout.
class BodyCalloutSlot {
  /// Creates a slot rule for [segment].
  const BodyCalloutSlot({
    required this.segment,
    required this.side,
    required this.slot,
  });

  /// The annotated segment.
  final BodySegment segment;

  /// The gutter holding the chip.
  final CalloutSide side;

  /// Zero-based vertical position within the gutter.
  final int slot;

  @override
  bool operator ==(Object other) =>
      other is BodyCalloutSlot &&
      other.segment == segment &&
      other.side == side &&
      other.slot == slot;

  @override
  int get hashCode => Object.hash(segment, side, slot);

  @override
  String toString() =>
      'BodyCalloutSlot(segment: ${segment.name}, side: ${side.name}, '
      'slot: $slot)';
}

/// The single source of truth for callout placement.
///
/// Add, remove or re-order callouts here — never inside the painter. The list
/// order is irrelevant; [BodyCalloutSlot.slot] and [BodyCalloutSlot.side]
/// decide where a chip lands.
const List<BodyCalloutSlot> bodyCalloutSlots = [
  BodyCalloutSlot(
    segment: BodySegment.leftUpperArm,
    side: CalloutSide.left,
    slot: 0,
  ),
  BodyCalloutSlot(
    segment: BodySegment.abdomen,
    side: CalloutSide.left,
    slot: 1,
  ),
  BodyCalloutSlot(
    segment: BodySegment.leftThigh,
    side: CalloutSide.left,
    slot: 2,
  ),
  BodyCalloutSlot(
    segment: BodySegment.chest,
    side: CalloutSide.right,
    slot: 0,
  ),
  BodyCalloutSlot(
    segment: BodySegment.rightUpperArm,
    side: CalloutSide.right,
    slot: 1,
  ),
  BodyCalloutSlot(
    segment: BodySegment.rightThigh,
    side: CalloutSide.right,
    slot: 2,
  ),
];
