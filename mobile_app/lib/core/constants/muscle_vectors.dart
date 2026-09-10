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
          // ignore: deprecated_member_use
          ..translate(0.5, 0.0, 0.0)
          // ignore: deprecated_member_use
          ..scale(-1.0, 1.0, 1.0)
          // ignore: deprecated_member_use
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

Path _leftUpperArm() {
  // M35 Task 2: bottom edge stops at y≈0.335–0.345, leaving a visible gap
  // before the forearm (top y≈0.365) so the arm never renders as one block.
  return Path()
    ..moveTo(0.34, 0.18)
    ..quadraticBezierTo(0.18, 0.22, 0.20, 0.335)
    ..lineTo(0.28, 0.345)
    ..quadraticBezierTo(0.30, 0.26, 0.38, 0.22)
    ..close();
}

Path _leftForearm() {
  // M35 Task 2: top edge starts at y≈0.365, gapped from the upper arm above.
  return Path()
    ..moveTo(0.20, 0.365)
    ..quadraticBezierTo(0.22, 0.48, 0.27, 0.58)
    ..lineTo(0.30, 0.55)
    ..lineTo(0.27, 0.45)
    ..lineTo(0.29, 0.365)
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

Path _leftThigh() {
  // M35 Task 2: bottom edge stops at y≈0.785, leaving a visible gap
  // before the calf (top y≈0.815) so the leg never renders as one block.
  return Path()
    ..moveTo(0.50, 0.66)
    ..lineTo(0.42, 0.66)
    ..lineTo(0.39, 0.785)
    ..lineTo(0.48, 0.785)
    ..close();
}

Path _leftCalf() {
  // M35 Task 2: top edge starts at y≈0.815, gapped from the thigh above.
  return Path()
    ..moveTo(0.48, 0.815)
    ..lineTo(0.39, 0.815)
    ..lineTo(0.36, 0.93)
    ..lineTo(0.46, 0.93)
    ..close();
}

Path _shoulders() {
  return Path()
    ..moveTo(0.35, 0.14)
    ..lineTo(0.65, 0.14)
    ..lineTo(0.68, 0.22)
    ..lineTo(0.32, 0.22)
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
  addPair('upper_arms', 'Upper Arms', MuscleView.front, _leftUpperArm());
  addPair('forearms', 'Forearms', MuscleView.front, _leftForearm());
  addPair('thighs', 'Thighs', MuscleView.front, _leftThigh());
  addPair('calves', 'Calves', MuscleView.front, _leftCalf());
  regions.add(
    MuscleRegion(
      id: 'shoulders',
      label: 'Shoulders',
      view: MuscleView.front,
      normalizedPath: _shoulders(),
    ),
  );
  addPair('upper_arms', 'Upper Arms', MuscleView.back, _leftUpperArm());
  addPair('forearms', 'Forearms', MuscleView.back, _leftForearm());
  addPair('thighs', 'Thighs', MuscleView.back, _leftThigh());
  addPair('calves', 'Calves', MuscleView.back, _leftCalf());
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

/// Region ids that form the split-limb anatomy: the arms render as Upper
/// Arms + Forearms and the legs as Thighs + Calves instead of single-block
/// limbs. The painter gives each of these its own outline/color identity.
const Set<String> splitLimbRegionIds = {
  'upper_arms',
  'forearms',
  'thighs',
  'calves',
};

/// Whether [id] is one of the split-limb segments in [splitLimbRegionIds].
bool isSplitLimbRegion(String id) => splitLimbRegionIds.contains(id);
