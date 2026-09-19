import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_diagram_view_model.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/segment_status.dart';
import 'package:nutri_mobile_app/ui/organisms/body_blueprint/body_blueprint_painter.dart';

const _goldenSize = Size(720, 420);

SegmentStatus _statusFor(BodySegment segment) {
  switch (segment) {
    case BodySegment.chest:
    case BodySegment.rightUpperArm:
    case BodySegment.rightThigh:
      return SegmentStatus.balanced;
    case BodySegment.abdomen:
    case BodySegment.leftCalf:
      return SegmentStatus.warning;
    case BodySegment.leftUpperArm:
    case BodySegment.leftForearm:
      return SegmentStatus.critical;
    default:
      return SegmentStatus.noData;
  }
}

void main() {
  testWidgets('M37 body blueprint painter matches its golden', (tester) async {
    final viewModel = BodyDiagramViewModel(
      statuses: {
        for (final segment in BodySegment.values) segment: _statusFor(segment),
      },
      callouts: const [
        BodyCallout(segment: BodySegment.abdomen, label: 'STOMACH', value: '1.840 kcal'),
        BodyCallout(segment: BodySegment.chest, label: 'CHEST', value: '4/4 sets'),
        BodyCallout(segment: BodySegment.leftThigh, label: 'LEGS', value: '12/12 sets'),
      ],
    );

    await tester.pumpWidget(
      Center(
        child: RepaintBoundary(
          key: const Key('golden_boundary'),
          child: CustomPaint(
            size: _goldenSize,
            painter: BodyBlueprintPainter(viewModel: viewModel),
          ),
        ),
      ),
    );

    await expectLater(
      find.byKey(const Key('golden_boundary')),
      matchesGoldenFile('goldens/body_blueprint_painter.png'),
    );
  });
}
