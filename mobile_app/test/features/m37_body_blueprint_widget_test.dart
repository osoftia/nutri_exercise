import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_diagram_view_model.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/segment_status.dart';
import 'package:nutri_mobile_app/ui/organisms/body_blueprint/body_blueprint_diagram.dart';
import 'package:nutri_mobile_app/ui/organisms/body_blueprint/body_segment_geometry.dart';

const _size = Size(720, 420);

BodyDiagramViewModel _viewModel() => const BodyDiagramViewModel(
      statuses: {
        BodySegment.chest: SegmentStatus.balanced,
        BodySegment.abdomen: SegmentStatus.warning,
        BodySegment.leftUpperArm: SegmentStatus.critical,
        BodySegment.rightUpperArm: SegmentStatus.balanced,
        BodySegment.leftThigh: SegmentStatus.noData,
        BodySegment.rightThigh: SegmentStatus.balanced,
      },
      callouts: [
        BodyCallout(
          segment: BodySegment.abdomen,
          label: 'STOMACH',
          value: '1.840 kcal',
        ),
        BodyCallout(segment: BodySegment.chest, label: 'CHEST', value: '4/4 sets'),
        BodyCallout(
          segment: BodySegment.leftThigh,
          label: 'LEGS',
          value: '12/12 sets',
        ),
      ],
    );

Widget _harness(
  BodyDiagramViewModel viewModel, {
  required ValueChanged<BodySegment>? onSelected,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: _size.width,
          height: _size.height,
          child: BodyBlueprintDiagram(
            viewModel: viewModel,
            onSegmentSelected: onSelected,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('M37 blueprint diagram widget', () {
    testWidgets('tapping an abdomen callout reports the abdomen segment',
        (tester) async {
      BodySegment? selected;
      await tester.pumpWidget(_harness(_viewModel(), onSelected: (s) => selected = s));

      await tester.tap(find.byKey(const Key('callout_abdomen')));
      await tester.pump();

      expect(selected, BodySegment.abdomen);
    });

    testWidgets('tapping the abdomen segment reports the abdomen segment',
        (tester) async {
      BodySegment? selected;
      await tester.pumpWidget(_harness(_viewModel(), onSelected: (s) => selected = s));

      final box = tester.renderObject<RenderBox>(
        find.byKey(const Key('body_blueprint_canvas')),
      );
      final local = BodySegmentGeometry.interiorPoint(BodySegment.abdomen, box.size);
      await tester.tapAt(box.localToGlobal(local));
      await tester.pump();

      expect(selected, BodySegment.abdomen);
    });

    testWidgets('tapping a limb segment reports that limb', (tester) async {
      BodySegment? selected;
      await tester.pumpWidget(_harness(_viewModel(), onSelected: (s) => selected = s));

      final box = tester.renderObject<RenderBox>(
        find.byKey(const Key('body_blueprint_canvas')),
      );
      final local = BodySegmentGeometry.interiorPoint(BodySegment.leftThigh, box.size);
      await tester.tapAt(box.localToGlobal(local));
      await tester.pump();

      expect(selected, BodySegment.leftThigh);
    });

    testWidgets('callout chips expose their label and value to screen readers',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_harness(_viewModel(), onSelected: (_) {}));

      final data = tester
          .getSemantics(find.byKey(const Key('callout_abdomen')))
          .getSemanticsData();
      expect(data.label, contains('STOMACH'));
      expect(data.value, contains('1.840 kcal'));

      handle.dispose();
    });

    testWidgets('callout chips keep a 48x48 touch target', (tester) async {
      await tester.pumpWidget(_harness(_viewModel(), onSelected: (_) {}));

      final chipSize = tester.getSize(find.byKey(const Key('callout_abdomen')));
      expect(chipSize.width, greaterThanOrEqualTo(48));
      expect(chipSize.height, greaterThanOrEqualTo(48));
    });
  });
}
