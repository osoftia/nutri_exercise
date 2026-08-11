import 'package:flutter/material.dart';

enum MuscleView { front, back }

class MuscleRegion {
  const MuscleRegion({
    required this.id,
    required this.label,
    required this.view,
    required this.normalizedPath,
  });

  final String id;
  final String label;
  final MuscleView view;

  /// Path defined in a normalized 0..1 box relative to the figure it belongs to.
  final Path normalizedPath;
}

Path _mirror(Path path) {
  return path.transform(
    (Matrix4.identity()
          ..translate(0.5, 0.0, 0.0)
          ..scale(-1.0, 1.0, 1.0)
          ..translate(-0.5, 0.0, 0.0))
        .storage,
  );
}

Path _frontSilhouette() {
  return Path()
    ..moveTo(0.44, 0.02)
    ..quadraticBezierTo(0.50, -0.03, 0.56, 0.02)
    ..lineTo(0.58, 0.09)
    ..lineTo(0.54, 0.13)
    ..quadraticBezierTo(0.70, 0.15, 0.73, 0.28)
    ..quadraticBezierTo(0.72, 0.30, 0.65, 0.32)
    ..lineTo(0.65, 0.50)
    ..quadraticBezierTo(0.70, 0.54, 0.68, 0.60)
    ..lineTo(0.67, 0.95)
    ..lineTo(0.53, 0.95)
    ..lineTo(0.47, 0.95)
    ..lineTo(0.33, 0.95)
    ..lineTo(0.35, 0.60)
    ..quadraticBezierTo(0.30, 0.54, 0.35, 0.50)
    ..lineTo(0.35, 0.32)
    ..quadraticBezierTo(0.28, 0.30, 0.27, 0.28)
    ..quadraticBezierTo(0.30, 0.15, 0.46, 0.13)
    ..lineTo(0.42, 0.09)
    ..close();
}

Path _leftArm() {
  return Path()
    ..moveTo(0.34, 0.18)
    ..quadraticBezierTo(0.18, 0.22, 0.21, 0.42)
    ..quadraticBezierTo(0.22, 0.52, 0.27, 0.58)
    ..lineTo(0.30, 0.55)
    ..quadraticBezierTo(0.27, 0.45, 0.29, 0.36)
    ..quadraticBezierTo(0.31, 0.25, 0.38, 0.22)
    ..close();
}

Path _leftPec() {
  return Path()
    ..moveTo(0.50, 0.20)
    ..quadraticBezierTo(0.45, 0.18, 0.39, 0.23)
    ..quadraticBezierTo(0.35, 0.30, 0.39, 0.35)
    ..quadraticBezierTo(0.44, 0.38, 0.50, 0.35)
    ..close();
}

Path _abs() {
  return Path()
    ..moveTo(0.44, 0.40)
    ..lineTo(0.56, 0.40)
    ..lineTo(0.56, 0.55)
    ..lineTo(0.44, 0.55)
    ..close();
}

Path _leftLeg() {
  return Path()
    ..moveTo(0.50, 0.66)
    ..quadraticBezierTo(0.42, 0.66, 0.38, 0.70)
    ..lineTo(0.36, 0.93)
    ..lineTo(0.46, 0.93)
    ..lineTo(0.47, 0.70)
    ..quadraticBezierTo(0.49, 0.67, 0.50, 0.66)
    ..close();
}

Path _back() {
  return Path()
    ..moveTo(0.45, 0.14)
    ..quadraticBezierTo(0.30, 0.15, 0.33, 0.23)
    ..quadraticBezierTo(0.36, 0.42, 0.44, 0.46)
    ..quadraticBezierTo(0.50, 0.49, 0.56, 0.46)
    ..quadraticBezierTo(0.64, 0.42, 0.67, 0.23)
    ..quadraticBezierTo(0.70, 0.15, 0.55, 0.14)
    ..close();
}

final Path frontSilhouette = _frontSilhouette();
final Path backSilhouette = _frontSilhouette();

final List<MuscleRegion> muscleRegions = _buildRegions();

List<MuscleRegion> _buildRegions() {
  final regions = <MuscleRegion>[];
  void addPair(String id, String label, MuscleView view, Path left) {
    regions
      ..add(
        MuscleRegion(id: id, label: label, view: view, normalizedPath: left),
      )
      ..add(
        MuscleRegion(
          id: id,
          label: label,
          view: view,
          normalizedPath: _mirror(left),
        ),
      );
  }

  addPair('chest', 'Chest', MuscleView.front, _leftPec());
  regions.add(
    MuscleRegion(
      id: 'abs',
      label: 'Abs',
      view: MuscleView.front,
      normalizedPath: _abs(),
    ),
  );
  addPair('arms', 'Arms', MuscleView.front, _leftArm());
  addPair('legs', 'Legs', MuscleView.front, _leftLeg());
  addPair('arms', 'Arms', MuscleView.back, _leftArm());
  addPair('legs', 'Legs', MuscleView.back, _leftLeg());
  regions.add(
    MuscleRegion(
      id: 'back',
      label: 'Back',
      view: MuscleView.back,
      normalizedPath: _back(),
    ),
  );
  return regions;
}

String muscleLabel(String id) {
  for (final region in muscleRegions) {
    if (region.id == id) return region.label;
  }
  return id;
}
