import 'body_segment.dart';
import 'segment_status.dart';

/// A short blueprint annotation attached to a body segment.
class BodyCallout {
  /// Creates a callout for [segment] with a short [label] and one-line [value].
  const BodyCallout({
    required this.segment,
    required this.label,
    required this.value,
  });

  /// The annotated segment.
  final BodySegment segment;

  /// Short, usually uppercase, label (e.g. `STOMACH`).
  final String label;

  /// One-line live value (e.g. `1.840 kcal`).
  final String value;

  /// Returns a copy with the provided fields replaced.
  BodyCallout copyWith({
    BodySegment? segment,
    String? label,
    String? value,
  }) {
    return BodyCallout(
      segment: segment ?? this.segment,
      label: label ?? this.label,
      value: value ?? this.value,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BodyCallout &&
      other.segment == segment &&
      other.label == label &&
      other.value == value;

  @override
  int get hashCode => Object.hash(segment, label, value);

  @override
  String toString() =>
      'BodyCallout(segment: ${segment.name}, label: $label, value: $value)';
}

/// Immutable snapshot of everything the blueprint diagram needs to render.
///
/// The painter only draws this object; all computation (statuses, callout
/// text, projection scale factors) happens outside the widget tree. Equality is
/// value-based so `shouldRepaint` can compare view models directly.
class BodyDiagramViewModel {
  /// Creates a diagram view model.
  const BodyDiagramViewModel({
    this.statuses = const {},
    this.scaleFactors = const {},
    this.callouts = const [],
    this.selectedSegment,
  });

  /// Per-segment status; missing segments default to [SegmentStatus.noData].
  final Map<BodySegment, SegmentStatus> statuses;

  /// Per-segment thickness multiplier for projections; missing segments are
  /// drawn at their baseline scale of `1.0`.
  final Map<BodySegment, double> scaleFactors;

  /// The annotations declared for this snapshot.
  final List<BodyCallout> callouts;

  /// The segment currently selected, if any.
  final BodySegment? selectedSegment;

  /// Status for [segment], defaulting to [SegmentStatus.noData].
  SegmentStatus statusFor(BodySegment segment) =>
      statuses[segment] ?? SegmentStatus.noData;

  /// Thickness multiplier for [segment], defaulting to `1.0`.
  double scaleFor(BodySegment segment) => scaleFactors[segment] ?? 1.0;

  /// The callout attached to [segment], if one was declared.
  BodyCallout? calloutFor(BodySegment segment) {
    for (final callout in callouts) {
      if (callout.segment == segment) return callout;
    }
    return null;
  }

  /// Returns a copy with the provided fields replaced.
  BodyDiagramViewModel copyWith({
    Map<BodySegment, SegmentStatus>? statuses,
    Map<BodySegment, double>? scaleFactors,
    List<BodyCallout>? callouts,
    BodySegment? selectedSegment,
  }) {
    return BodyDiagramViewModel(
      statuses: statuses ?? this.statuses,
      scaleFactors: scaleFactors ?? this.scaleFactors,
      callouts: callouts ?? this.callouts,
      selectedSegment: selectedSegment ?? this.selectedSegment,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BodyDiagramViewModel &&
      _mapEquals(other.statuses, statuses) &&
      _mapEquals(other.scaleFactors, scaleFactors) &&
      _listEquals(other.callouts, callouts) &&
      other.selectedSegment == selectedSegment;

  @override
  int get hashCode => Object.hash(
        _mapHash(statuses),
        _mapHash(scaleFactors),
        Object.hashAll(callouts),
        selectedSegment,
      );

  @override
  String toString() =>
      'BodyDiagramViewModel(statuses: ${statuses.length}, '
      'scaleFactors: ${scaleFactors.length}, callouts: ${callouts.length}, '
      'selectedSegment: ${selectedSegment?.name})';
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) return false;
  }
  return true;
}

int _mapHash<K, V>(Map<K, V> map) =>
    Object.hashAllUnordered(map.entries.map((e) => Object.hash(e.key, e.value)));

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
