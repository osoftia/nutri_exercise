import 'body_segment.dart';
import 'segment_status.dart';

/// Immutable result of a single segment's balance computation.
class SegmentBalance {
  /// Creates a segment balance result.
  const SegmentBalance({
    required this.segment,
    required this.status,
    required this.imbalanceScore,
  });

  /// The evaluated segment.
  final BodySegment segment;

  /// The status the diagram should render for this segment.
  final SegmentStatus status;

  /// Signed score in `[-1.0, 1.0]`.
  ///
  /// Negative means missing training, positive means a caloric surplus that is
  /// not covered by training. `0` is on target and is also used for `noData`.
  final double imbalanceScore;

  /// Returns a copy of this result with the provided fields replaced.
  SegmentBalance copyWith({
    BodySegment? segment,
    SegmentStatus? status,
    double? imbalanceScore,
  }) {
    return SegmentBalance(
      segment: segment ?? this.segment,
      status: status ?? this.status,
      imbalanceScore: imbalanceScore ?? this.imbalanceScore,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SegmentBalance &&
      other.segment == segment &&
      other.status == status &&
      other.imbalanceScore == imbalanceScore;

  @override
  int get hashCode => Object.hash(segment, status, imbalanceScore);

  @override
  String toString() =>
      'SegmentBalance(segment: ${segment.name}, status: ${status.name}, '
      'imbalanceScore: $imbalanceScore)';
}
