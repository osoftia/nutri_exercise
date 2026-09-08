import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/constants/muscle_vectors.dart';
import 'package:nutri_mobile_app/core/constants/tamagotchi_groups.dart';
import 'package:nutri_mobile_app/core/state/muscle_tamagotchi_state.dart';
import 'package:nutri_mobile_app/ui/organisms/interactive_body_map.dart';

const _testSize = Size(320, 200);

void main() {
  group('split anatomy registry', () {
    const splitIds = ['upper_arms', 'forearms', 'thighs', 'calves'];

    test('each split region exists on the front and back views', () {
      for (final id in splitIds) {
        final entries =
            muscleRegions.where((region) => region.id == id).toList();
        expect(entries.length, 4, reason: 'expected 4 entries for $id');
        expect(
          entries.map((region) => region.view).toSet(),
          {MuscleView.front, MuscleView.back},
          reason: 'expected front and back entries for $id',
        );
      }
    });

    test('each split region has a distinct label and a non-empty path', () {
      final labels = <String, String>{};
      for (final id in splitIds) {
        final entries =
            muscleRegions.where((region) => region.id == id).toList();
        for (final region in entries) {
          expect(region.normalizedPath.getBounds().isEmpty, isFalse);
        }
        labels[id] = entries.first.label;
      }
      expect(labels.values.toSet().length, splitIds.length);
      expect(labels['upper_arms'], 'Upper Arms');
      expect(labels['forearms'], 'Forearms');
      expect(labels['thighs'], 'Thighs');
      expect(labels['calves'], 'Calves');
    });

    test('no unified arms or legs blocks remain', () {
      final ids = muscleRegions.map((region) => region.id).toSet();
      expect(ids, isNot(contains('arms')));
      expect(ids, isNot(contains('legs')));
    });

    test('every region is driven by exactly one tamagotchi group', () {
      for (final region in muscleRegions) {
        expect(
          tamagotchiGroupForRegion(region.id),
          isA<MuscleTamagotchiGroup>(),
          reason: 'region ${region.id} has no owning group',
        );
      }
    });
  });

  group('split anatomy hit-testing', () {
    test('front-view taps resolve to the split regions', () {
      expect(muscleAt(const Offset(46.0, 63.6), _testSize)?.id, 'upper_arms');
      expect(muscleAt(const Offset(46.0, 95.6), _testSize)?.id, 'forearms');
      expect(muscleAt(const Offset(75.1, 133.5), _testSize)?.id, 'thighs');
      expect(muscleAt(const Offset(70.8, 153.9), _testSize)?.id, 'calves');
    });

    test('back-view taps resolve to the split regions', () {
      final upper = muscleAt(const Offset(201.2, 63.6), _testSize);
      expect(upper?.id, 'upper_arms');
      expect(upper?.view, MuscleView.back);
      final fore = muscleAt(const Offset(201.2, 95.6), _testSize);
      expect(fore?.id, 'forearms');
      expect(fore?.view, MuscleView.back);
      final thigh = muscleAt(const Offset(230.3, 133.5), _testSize);
      expect(thigh?.id, 'thighs');
      expect(thigh?.view, MuscleView.back);
      final calf = muscleAt(const Offset(225.9, 153.9), _testSize);
      expect(calf?.id, 'calves');
      expect(calf?.view, MuscleView.back);
    });

    test('seam taps hit the topmost painted region', () {
      expect(muscleAt(const Offset(60.6, 56.3), _testSize)?.id, 'shoulders');
    });

    test('taps outside every region return null', () {
      expect(muscleAt(const Offset(5, 5), _testSize), isNull);
    });
  });
}
