import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/constants/tamagotchi_groups.dart';
import 'package:nutri_mobile_app/core/state/muscle_tamagotchi_state.dart';

void main() {
  group('tamagotchiGroupToRegions', () {
    test('maps each group to its visual regions', () {
      expect(
        tamagotchiGroupToRegions[MuscleTamagotchiGroup.chest],
        ['chest'],
      );
      expect(
        tamagotchiGroupToRegions[MuscleTamagotchiGroup.core],
        containsAll(['abs', 'back']),
      );
      expect(
        tamagotchiGroupToRegions[MuscleTamagotchiGroup.arms],
        containsAll(['arms', 'shoulders']),
      );
      expect(
        tamagotchiGroupToRegions[MuscleTamagotchiGroup.legs],
        ['legs'],
      );
    });

    test('covers every group exactly once', () {
      expect(tamagotchiGroupToRegions.length, 4);
    });
  });

  group('tamagotchiGroupForRegion', () {
    test('resolves a region id to its owning group', () {
      expect(
        tamagotchiGroupForRegion('chest'),
        MuscleTamagotchiGroup.chest,
      );
      expect(tamagotchiGroupForRegion('abs'), MuscleTamagotchiGroup.core);
      expect(tamagotchiGroupForRegion('back'), MuscleTamagotchiGroup.core);
      expect(tamagotchiGroupForRegion('shoulders'), MuscleTamagotchiGroup.arms);
    });

    test('returns null for an unknown region', () {
      expect(tamagotchiGroupForRegion('unknown'), isNull);
    });
  });

  group('tierColor', () {
    test('maps tier C to red', () {
      expect(tierColor(MuscleTier.c), const Color(0xFFEF4444));
    });

    test('maps tier B to yellow', () {
      expect(tierColor(MuscleTier.b), const Color(0xFFEAB308));
    });

    test('maps tier A to green', () {
      expect(tierColor(MuscleTier.a), const Color(0xFF22C55E));
    });

    test('maps tier S to gold', () {
      expect(tierColor(MuscleTier.s), const Color(0xFFFFD700));
    });
  });
}
