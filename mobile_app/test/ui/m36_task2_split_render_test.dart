import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/constants/muscle_vectors.dart';
import 'package:nutri_mobile_app/core/state/muscle_tamagotchi_state.dart';
import 'package:nutri_mobile_app/ui/organisms/interactive_body_map.dart';

const _testSize = Size(320, 200);

Rect _boundsOf(String id, MuscleView view) {
  final region = muscleRegions.firstWhere(
    (r) => r.id == id && r.view == view,
  );
  return region.normalizedPath.getBounds();
}

void main() {
  group('forced split-limb canvas paths (M36)', () {
    test('every split segment has an explicit draw offset', () {
      for (final id in ['upper_arms', 'forearms', 'thighs', 'calves']) {
        expect(
          splitLimbDrawOffsets.containsKey(id),
          isTrue,
          reason: '$id needs its own drawing offset',
        );
      }
    });

    test('joint neighbours are pushed apart (opposing vertical offsets)', () {
      final upper = splitLimbDrawOffsets['upper_arms']!;
      final fore = splitLimbDrawOffsets['forearms']!;
      final thigh = splitLimbDrawOffsets['thighs']!;
      final calf = splitLimbDrawOffsets['calves']!;
      expect(upper.dy, lessThan(0));
      expect(fore.dy, greaterThan(0));
      expect(thigh.dy, lessThan(0));
      expect(calf.dy, greaterThan(0));
    });

    test('shifted arm/leg bounds stay disjoint with a wider gap', () {
      for (final view in MuscleView.values) {
        final upper = _boundsOf('upper_arms', view);
        final fore = _boundsOf('forearms', view);
        final thigh = _boundsOf('thighs', view);
        final calf = _boundsOf('calves', view);

        final shiftedUpper = upper.shift(
          Offset(0, splitLimbDrawOffsets['upper_arms']!.dy),
        );
        final shiftedFore = fore.shift(
          Offset(0, splitLimbDrawOffsets['forearms']!.dy),
        );
        final shiftedThigh = thigh.shift(
          Offset(0, splitLimbDrawOffsets['thighs']!.dy),
        );
        final shiftedCalf = calf.shift(
          Offset(0, splitLimbDrawOffsets['calves']!.dy),
        );

        expect(shiftedUpper.overlaps(shiftedFore), isFalse);
        expect(shiftedThigh.overlaps(shiftedCalf), isFalse);
        expect(
          shiftedFore.top - shiftedUpper.bottom,
          greaterThan(fore.top - upper.bottom),
          reason: '$view arm gap must widen',
        );
        expect(
          shiftedCalf.top - shiftedThigh.bottom,
          greaterThan(calf.top - thigh.bottom),
          reason: '$view leg gap must widen',
        );
      }
    });

    test('joint constants sit inside the vector gaps', () {
      for (final view in MuscleView.values) {
        expect(
          splitArmJointY,
          greaterThan(_boundsOf('upper_arms', view).bottom),
        );
        expect(splitArmJointY, lessThan(_boundsOf('forearms', view).top));
        expect(splitLegJointY, greaterThan(_boundsOf('thighs', view).bottom));
        expect(splitLegJointY, lessThan(_boundsOf('calves', view).top));
      }
    });

    test('pinned taps still resolve to their gapped segments', () {
      expect(muscleAt(const Offset(46.0, 63.6), _testSize)?.id, 'upper_arms');
      expect(muscleAt(const Offset(46.0, 95.6), _testSize)?.id, 'forearms');
      expect(muscleAt(const Offset(75.1, 133.5), _testSize)?.id, 'thighs');
      expect(muscleAt(const Offset(70.8, 153.9), _testSize)?.id, 'calves');
    });
  });

  testWidgets('split body map smoke-renders with live state', (tester) async {
    final state = MuscleTamagotchiState()
      ..applyGrowth(const [MuscleTamagotchiGroup.arms]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: InteractiveBodyMap(tamagotchiState: state)),
      ),
    );
    await tester.pump();
    expect(find.byType(InteractiveBodyMap), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
