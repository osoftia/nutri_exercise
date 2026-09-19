import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_diagram_view_model.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/callout_layout_table.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/segment_status.dart';
import 'package:nutri_mobile_app/ui/organisms/body_blueprint/body_blueprint_painter.dart';
import 'package:nutri_mobile_app/ui/organisms/body_blueprint/body_segment_geometry.dart';
import 'package:nutri_mobile_app/ui/organisms/body_blueprint/body_segment_palette.dart';
import 'package:nutri_mobile_app/ui/organisms/body_blueprint/callout_placement.dart';

const _size = Size(720, 420);

BodyDiagramViewModel _viewModel({
  Map<BodySegment, SegmentStatus> statuses = const {
    BodySegment.abdomen: SegmentStatus.warning,
  },
  List<BodyCallout> callouts = const [
    BodyCallout(segment: BodySegment.abdomen, label: 'STOMACH', value: '1.840 kcal'),
  ],
}) {
  return BodyDiagramViewModel(statuses: statuses, callouts: callouts);
}

void main() {
  group('M37 body segment palette', () {
    test('uses the documented stroke colours', () {
      expect(
        BodySegmentPalette.strokeFor(SegmentStatus.balanced),
        const Color(0xFF3B82F6),
      );
      expect(
        BodySegmentPalette.strokeFor(SegmentStatus.warning),
        const Color(0xFFF59E0B),
      );
      expect(
        BodySegmentPalette.strokeFor(SegmentStatus.critical),
        const Color(0xFFEF4444),
      );
      expect(
        BodySegmentPalette.strokeFor(SegmentStatus.noData),
        const Color(0xFF475569),
      );
    });

    test('fills every status at eighteen percent opacity', () {
      for (final status in SegmentStatus.values) {
        expect(
          BodySegmentPalette.fillFor(status),
          BodySegmentPalette.strokeFor(status).withValues(alpha: 0.18),
        );
      }
    });
  });

  group('M37 callout placement', () {
    final placements = layoutBodyCallouts(_size);

    test('places every configured callout in a gutter', () {
      expect(placements.length, bodyCalloutSlots.length);
      expect(
        placements.map((p) => p.side).toSet(),
        {CalloutSide.left, CalloutSide.right},
      );
    });

    test('never overlaps two callout chips', () {
      for (var i = 0; i < placements.length; i++) {
        for (var j = i + 1; j < placements.length; j++) {
          expect(
            placements[i].chipRect.overlaps(placements[j].chipRect),
            isFalse,
            reason: '${placements[i].segment.name} vs '
                '${placements[j].segment.name}',
          );
        }
      }
    });

    test('never overlaps the figure', () {
      final figure = BodySegmentGeometry.figureRect(_size);
      for (final placement in placements) {
        expect(
          figure.overlaps(placement.chipRect),
          isFalse,
          reason: placement.segment.name,
        );
      }
    });

    test('anchors every leader line inside its segment', () {
      final paths = BodySegmentGeometry.buildPaths(_size);
      for (final placement in placements) {
        expect(paths[placement.segment]!.contains(placement.anchor), isTrue);
        expect(buildLeaderPath(placement).getBounds().isEmpty, isFalse);
      }
    });

    test('reserves at least a 48x48 touch target per chip', () {
      for (final placement in placements) {
        expect(placement.chipRect.width, greaterThanOrEqualTo(48));
        expect(placement.chipRect.height, greaterThanOrEqualTo(48));
      }
    });
  });

  group('M37 body blueprint painter', () {
    test('repaints only when the view model changes', () {
      final first = BodyBlueprintPainter(viewModel: _viewModel());
      final same = BodyBlueprintPainter(viewModel: _viewModel());
      final changed = BodyBlueprintPainter(
        viewModel: _viewModel(
          statuses: const {BodySegment.abdomen: SegmentStatus.critical},
        ),
      );

      expect(first.shouldRepaint(same), isFalse);
      expect(first.shouldRepaint(changed), isTrue);
    });
  });

  group('M37 diagram view model', () {
    test('defaults missing segments to noData and scale 1.0', () {
      const viewModel = BodyDiagramViewModel();
      expect(viewModel.statusFor(BodySegment.head), SegmentStatus.noData);
      expect(viewModel.scaleFor(BodySegment.head), 1.0);
      expect(viewModel.calloutFor(BodySegment.head), isNull);
    });

    test('resolves status, scale and callout', () {
      const viewModel = BodyDiagramViewModel(
        statuses: {BodySegment.chest: SegmentStatus.balanced},
        scaleFactors: {BodySegment.chest: 1.2},
        callouts: [
          BodyCallout(segment: BodySegment.chest, label: 'CHEST', value: '4/4'),
        ],
        selectedSegment: BodySegment.chest,
      );
      expect(viewModel.statusFor(BodySegment.chest), SegmentStatus.balanced);
      expect(viewModel.scaleFor(BodySegment.chest), 1.2);
      expect(viewModel.calloutFor(BodySegment.chest)?.value, '4/4');
    });

    test('is value-equal and copies every field', () {
      const original = BodyDiagramViewModel(
        statuses: {BodySegment.head: SegmentStatus.balanced},
        callouts: [
          BodyCallout(segment: BodySegment.head, label: 'H', value: 'v'),
        ],
      );
      final copy = original.copyWith();
      expect(original, equals(copy));
      expect(original.hashCode, equals(copy.hashCode));

      expect(original.copyWith().statuses, original.statuses);
      expect(
        original.copyWith(selectedSegment: BodySegment.head).selectedSegment,
        BodySegment.head,
      );
      expect(
        original.copyWith(scaleFactors: {BodySegment.head: 1.5})
            .scaleFor(BodySegment.head),
        1.5,
      );
      expect(
        original.copyWith(statuses: {BodySegment.head: SegmentStatus.critical})
            .statusFor(BodySegment.head),
        SegmentStatus.critical,
      );
      expect(original.copyWith(callouts: const []).callouts, isEmpty);
      expect(original.toString(), contains('BodyDiagramViewModel'));

      expect(
        original,
        isNot(equals(original.copyWith(
          statuses: {BodySegment.head: SegmentStatus.critical},
        ))),
      );
      expect(
        original,
        isNot(equals(original.copyWith(
          statuses: {BodySegment.neck: SegmentStatus.balanced},
        ))),
      );
      expect(original, isNot(equals(const BodyDiagramViewModel())));
      expect(
        original,
        isNot(equals(original.copyWith(
          callouts: const [
            BodyCallout(segment: BodySegment.head, label: 'H', value: 'x'),
          ],
        ))),
      );
    });

    test('BodyCallout copies and compares', () {
      const callout = BodyCallout(
        segment: BodySegment.head,
        label: 'H',
        value: 'v',
      );
      expect(callout, equals(callout.copyWith()));
      expect(callout.hashCode, equals(callout.copyWith().hashCode));
      expect(callout.copyWith(label: 'Z').label, 'Z');
      expect(callout.copyWith(value: 'w').value, 'w');
      expect(
        callout.copyWith(segment: BodySegment.neck).segment,
        BodySegment.neck,
      );
      expect(callout, isNot(equals(callout.copyWith(value: 'x'))));
      expect(callout.toString(), contains('BodyCallout'));
    });

    test('layout slots are value objects and unique per gutter', () {
      const slot = BodyCalloutSlot(
        segment: BodySegment.chest,
        side: CalloutSide.right,
        slot: 0,
      );
      const same = BodyCalloutSlot(
        segment: BodySegment.chest,
        side: CalloutSide.right,
        slot: 0,
      );
      expect(slot, equals(same));
      expect(slot.hashCode, equals(same.hashCode));
      expect(
        slot,
        isNot(equals(const BodyCalloutSlot(
          segment: BodySegment.chest,
          side: CalloutSide.left,
          slot: 0,
        ))),
      );
      expect(slot.toString(), contains('BodyCalloutSlot'));

      final keys = bodyCalloutSlots.map((s) => '${s.side.name}-${s.slot}');
      expect(keys.toSet().length, bodyCalloutSlots.length);
    });
  });
}
