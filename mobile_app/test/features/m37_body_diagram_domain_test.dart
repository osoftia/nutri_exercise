import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/macro_balance.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/segment_balance.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/segment_balance_calculator.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/segment_balance_input.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/segment_status.dart';

/// One row of the "Segment status by imbalance score" Scenario Outline.
class _StatusExample {
  const _StatusExample(this.segment, this.trained, this.target, this.kcal, this.status);

  final String segment;
  final double trained;
  final double target;
  final double kcal;
  final String status;
}

/// One row of the "Imbalance thresholds" Scenario Outline.
class _ThresholdExample {
  const _ThresholdExample(this.kcal, this.status);

  final double kcal;
  final String status;
}

void main() {
  group('M37 body segment status (domain, pure)', () {
    const calculator = SegmentBalanceCalculator();
    late SegmentBalanceInput input;
    SegmentBalance? result;

    void givenBodySegment(String id) {
      input = SegmentBalanceInput(segment: BodySegment.values.byName(id));
    }

    void andVolumes({
      double trained = 0,
      double target = 0,
      double kcal = 0,
      MacroBalance macro = MacroBalance.none,
    }) {
      input = input.copyWith(
        trainedVolume: trained,
        targetVolume: target,
        calorieBalance: kcal,
        macroBalance: macro,
      );
    }

    void whenBodyDiagramComputed() {
      result = calculator.compute(input);
    }

    void thenStatus(String expected) {
      expect(result, isNotNull);
      expect(result!.status.name, expected);
    }

    const statusExamples = <_StatusExample>[
      _StatusExample('rightThigh', 12, 12, 0, 'balanced'),
      _StatusExample('rightThigh', 8, 12, 0, 'warning'),
      _StatusExample('rightThigh', 0, 12, 0, 'critical'),
      _StatusExample('chest', 4, 4, 0, 'balanced'),
      _StatusExample('chest', 3, 4, 0, 'warning'),
      _StatusExample('leftCalf', 3, 4, 0, 'warning'),
      _StatusExample('abdomen', 0, 0, 900, 'critical'),
      _StatusExample('abdomen', 0, 0, 0, 'noData'),
      _StatusExample('head', 0, 0, 0, 'noData'),
    ];

    for (final example in statusExamples) {
      test(
        '${example.segment} trained=${example.trained} '
        'target=${example.target} kcal=${example.kcal} -> ${example.status}',
        () {
          // Scenario Outline: Segment status by imbalance score
          givenBodySegment(example.segment);
          andVolumes(
            trained: example.trained,
            target: example.target,
            kcal: example.kcal,
          );
          whenBodyDiagramComputed();
          thenStatus(example.status);
        },
      );
    }

    const thresholdExamples = <_ThresholdExample>[
      _ThresholdExample(100, 'balanced'),
      _ThresholdExample(112, 'balanced'),
      _ThresholdExample(113, 'warning'),
      _ThresholdExample(150, 'warning'),
      _ThresholdExample(300, 'warning'),
      _ThresholdExample(301, 'critical'),
      _ThresholdExample(1500, 'critical'),
    ];

    for (final example in thresholdExamples) {
      test(
        'abdomen kcal=${example.kcal} -> ${example.status}',
        () {
          // Scenario Outline: Imbalance thresholds are inclusive at upper bound
          givenBodySegment('abdomen');
          andVolumes(kcal: example.kcal);
          whenBodyDiagramComputed();
          thenStatus(example.status);
        },
      );
    }

    test('missing training scores negative and critical', () {
      // Scenario: Missing training produces a negative imbalance score
      givenBodySegment('rightThigh');
      andVolumes(trained: 6, target: 12);
      whenBodyDiagramComputed();

      expect(result!.imbalanceScore, lessThan(0));
      thenStatus('critical');
      expect(result!.imbalanceScore, closeTo(-0.5, 0.0001));
    });

    test('caloric surplus scores positive and clamps at one', () {
      // Scenario: A caloric surplus produces a positive imbalance score
      givenBodySegment('abdomen');
      andVolumes(kcal: 900);
      whenBodyDiagramComputed();

      expect(result!.imbalanceScore, greaterThan(0));
      expect(result!.imbalanceScore, closeTo(1.0, 0.0001));
    });

    test('threshold constants are exposed for tuning', () {
      expect(SegmentBalanceCalculator.balancedThreshold, 0.15);
      expect(SegmentBalanceCalculator.warningThreshold, 0.40);
    });

    test('abdomen is driven by calories, limbs by training', () {
      expect(BodySegment.abdomen.driver, SegmentDriver.calorie);
      expect(BodySegment.rightThigh.driver, SegmentDriver.training);
      expect(BodySegment.leftForearm.driver, SegmentDriver.training);
    });

    test('value objects implement equality', () {
      const a = SegmentBalanceInput(segment: BodySegment.chest);
      const b = SegmentBalanceInput(segment: BodySegment.chest);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(calculator.compute(a), equals(calculator.compute(b)));
    });
  });

  group('M37 body segment value objects', () {
    const calculator = SegmentBalanceCalculator();

    test('MacroBalance reports deltas, average and copies', () {
      const macro = MacroBalance(
        proteinDeltaG: 30,
        carbsDeltaG: -60,
        fatDeltaG: 0,
      );
      expect(macro.hasAnyDelta, isTrue);
      expect(macro.averageDeltaG, closeTo(-10, 0.0001));
      expect(MacroBalance.none.hasAnyDelta, isFalse);

      final copy = macro.copyWith(proteinDeltaG: 99);
      expect(copy.proteinDeltaG, 99);
      expect(copy.carbsDeltaG, -60);
      expect(copy.fatDeltaG, 0);
      expect(copy, isNot(equals(macro)));
      expect(macro, equals(macro.copyWith()));
      expect(macro.hashCode, equals(macro.copyWith().hashCode));
      expect(macro.toString(), contains('MacroBalance'));
    });

    test('SegmentBalance copies, compares and prints', () {
      const balance = SegmentBalance(
        segment: BodySegment.chest,
        status: SegmentStatus.warning,
        imbalanceScore: -0.3,
      );
      final copy = balance.copyWith(status: SegmentStatus.critical);
      expect(copy.status, SegmentStatus.critical);
      expect(copy.segment, BodySegment.chest);
      expect(copy.imbalanceScore, -0.3);
      expect(copy, isNot(equals(balance)));
      expect(balance, equals(balance.copyWith()));
      expect(balance.hashCode, equals(balance.copyWith().hashCode));
      expect(balance.toString(), contains('SegmentBalance'));
    });

    test('SegmentBalanceInput copies, compares and prints', () {
      const input = SegmentBalanceInput(
        segment: BodySegment.rightThigh,
        trainedVolume: 10,
        targetVolume: 12,
      );
      final copy = input.copyWith(targetVolume: 20);
      expect(copy.targetVolume, 20);
      expect(copy.segment, BodySegment.rightThigh);
      expect(copy, isNot(equals(input)));
      expect(input, equals(input.copyWith()));
      expect(input.hashCode, equals(input.copyWith().hashCode));
      expect(input.toString(), contains('SegmentBalanceInput'));
    });

    test('a trained zero-target segment is balanced, not noData', () {
      final result = calculator.compute(
        const SegmentBalanceInput(
          segment: BodySegment.neck,
          trainedVolume: 5,
        ),
      );
      expect(result.status, SegmentStatus.balanced);
      expect(result.imbalanceScore, 0);
    });

    test('macro imbalance can push the abdomen into warning', () {
      final result = calculator.compute(
        const SegmentBalanceInput(
          segment: BodySegment.abdomen,
          macroBalance: MacroBalance(proteinDeltaG: 600),
        ),
      );
      expect(result.imbalanceScore, closeTo(0.2, 0.0001));
      expect(result.status, SegmentStatus.warning);
    });

    test('statusForScore maps each band', () {
      expect(calculator.statusForScore(0.0), SegmentStatus.balanced);
      expect(calculator.statusForScore(-0.15), SegmentStatus.balanced);
      expect(calculator.statusForScore(0.16), SegmentStatus.warning);
      expect(calculator.statusForScore(-0.40), SegmentStatus.warning);
      expect(calculator.statusForScore(0.41), SegmentStatus.critical);
    });
  });
}
