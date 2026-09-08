import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/ui/organisms/interactive_body_map.dart';

void main() {
  group('selectionBaseColor', () {
    test('an explicit override wins over the fallback', () {
      expect(
        selectionBaseColor(
          overrides: const {'chest': Colors.red},
          regionId: 'chest',
          fallback: Colors.blue,
        ),
        Colors.red,
      );
    });

    test('falls back when the region has no override', () {
      expect(
        selectionBaseColor(
          overrides: const {'chest': Colors.red},
          regionId: 'upper_arms',
          fallback: Colors.blue,
        ),
        Colors.blue,
      );
    });

    test('falls back when overrides are empty', () {
      expect(
        selectionBaseColor(
          overrides: const {},
          regionId: 'chest',
          fallback: Colors.blue,
        ),
        Colors.blue,
      );
    });
  });

  group('sameRegionIdSet', () {
    test('matches identical and equal sets', () {
      const regions = {'chest', 'upper_arms'};
      expect(sameRegionIdSet(regions, regions), isTrue);
      expect(
        sameRegionIdSet(regions, {'upper_arms', 'chest'}),
        isTrue,
      );
    });

    test('rejects different contents', () {
      expect(
        sameRegionIdSet({'chest'}, {'chest', 'upper_arms'}),
        isFalse,
      );
      expect(
        sameRegionIdSet({'chest'}, {'upper_arms'}),
        isFalse,
      );
      expect(sameRegionIdSet(const {}, const {'chest'}), isFalse);
    });

    test('matches two empty sets', () {
      expect(sameRegionIdSet(const {}, const {}), isTrue);
    });
  });
}
