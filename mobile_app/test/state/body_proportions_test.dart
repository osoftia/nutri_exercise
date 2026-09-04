import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/state/body_proportions.dart';

void main() {
  group('body proportions', () {
    test('bmi computes weight over height squared (kg / m^2)', () {
      expect(bmi(170, 70), closeTo(24.221, 0.01));
      expect(bmi(180, 80), closeTo(24.691, 0.01));
      expect(bmi(170, 95), closeTo(32.872, 0.01));
    });

    test('widthFactorForBmi maps a normal BMI to a near-neutral factor', () {
      final factor = widthFactorForBmi(bmi(170, 70));
      expect(factor, closeTo(1.0, 0.15));
      expect(factor, lessThan(1.15));
      expect(factor, greaterThan(0.85));
    });

    test('widthFactorForBmi is monotonic — heavier is wider', () {
      final normal = widthFactorForBmi(bmi(170, 70));
      final heavy = widthFactorForBmi(bmi(170, 95));
      final slim = widthFactorForBmi(bmi(180, 60));

      expect(heavy, greaterThan(normal));
      expect(normal, greaterThan(slim));
    });

    test('widthFactorForBmi clamps to a sane range', () {
      expect(widthFactorForBmi(10), greaterThanOrEqualTo(0.7));
      expect(widthFactorForBmi(60), lessThanOrEqualTo(1.6));
    });
  });
}
