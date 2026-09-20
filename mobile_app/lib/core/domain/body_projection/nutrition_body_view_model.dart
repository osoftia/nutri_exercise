import 'body_diagram_view_model.dart';
import 'body_segment.dart';
import 'segment_status.dart';

/// Builds the shared blueprint view model for the Nutrition tab when the tab is
/// rendered without a body-detail controller.
///
/// The calorie ratio drives a uniform, responsive mass scale (thin when under
/// target, wide when over) and colours every segment by the day's surplus, so
/// the unified figure still reflects the logged calories.
BodyDiagramViewModel nutritionBodyViewModel({
  required double morph,
  required double calorieRatio,
}) {
  final scale = 0.7 + 0.6 * morph.clamp(0.0, 1.0);
  final status = switch (calorieRatio) {
    > 1.3 => SegmentStatus.critical,
    > 1.1 => SegmentStatus.warning,
    _ => SegmentStatus.balanced,
  };
  return BodyDiagramViewModel(
    statuses: {
      for (final segment in BodySegment.values) segment: status,
    },
    scaleFactors: {
      for (final segment in BodySegment.values) segment: scale,
    },
  );
}
