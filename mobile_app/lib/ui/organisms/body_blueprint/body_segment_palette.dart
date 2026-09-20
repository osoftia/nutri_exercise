import 'package:flutter/material.dart';

import '../../../core/domain/body_projection/segment_status.dart';

/// Flat blueprint palette: outlined shapes only, no gradients or shadows.
abstract final class BodySegmentPalette {

  /// Colour used for an on-target segment.
  static const Color balanced = Color(0xFF3B82F6);

  /// Colour used for a healthy, protein-led calorie surplus (`#10B981`).
  static const Color healthy = Color(0xFF10B981);

  /// Colour used for a mildly imbalanced segment.
  static const Color warning = Color(0xFFF59E0B);

  /// Colour used for a strongly imbalanced segment.
  static const Color critical = Color(0xFFEF4444);

  /// Colour used when a segment has no data for the reference day.
  static const Color noData = Color(0xFF475569);

  /// Opacity of every status fill.
  static const double fillOpacity = 0.18;

  /// Stroke colour for [status].
  static Color strokeFor(SegmentStatus status) {
    switch (status) {
      case SegmentStatus.balanced:
        return balanced;
      case SegmentStatus.healthy:
        return healthy;
      case SegmentStatus.warning:
        return warning;
      case SegmentStatus.critical:
        return critical;
      case SegmentStatus.noData:
        return noData;
    }
  }

  /// Soft fill colour for [status] (`18%` of the stroke colour).
  static Color fillFor(SegmentStatus status) =>
      strokeFor(status).withValues(alpha: fillOpacity);
}
