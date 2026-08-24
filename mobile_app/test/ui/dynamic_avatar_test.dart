import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/models/body_morph.dart';
import 'package:nutri_mobile_app/ui/atoms/dynamic_avatar.dart';

void main() {
  group('morphFactorFor', () {
    test('ratio 0.5 maps to 0.0 (thinnest)', () {
      expect(morphFactorFor(1000, 2000), closeTo(0.0, 0.0001));
    });

    test('ratio 1.0 maps to 0.5 (normal)', () {
      expect(morphFactorFor(2000, 2000), closeTo(0.5, 0.0001));
    });

    test('ratio 1.5 maps to 1.0 (widest)', () {
      expect(morphFactorFor(3000, 2000), closeTo(1.0, 0.0001));
    });

    test('clamps low ratios to 0.0', () {
      expect(morphFactorFor(0, 2000), closeTo(0.0, 0.0001));
    });

    test('clamps high ratios to 1.0', () {
      expect(morphFactorFor(4000, 2000), closeTo(1.0, 0.0001));
    });

    test('zero target returns a neutral morph', () {
      expect(morphFactorFor(1000, 0), closeTo(0.5, 0.0001));
    });
  });

  group('DynamicAvatar', () {
    testWidgets('renders a painter with the provided morph', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: DynamicAvatar(morph: 0.3))),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.byKey(const Key('dynamic_avatar')),
      );
      final painter = customPaint.painter! as DynamicAvatarPainter;
      expect(painter.morph, 0.3);
    });

    testWidgets('painter repaints when morph changes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: DynamicAvatar(morph: 0.1))),
      );
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: DynamicAvatar(morph: 0.9))),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.byKey(const Key('dynamic_avatar')),
      );
      final painter = customPaint.painter! as DynamicAvatarPainter;
      expect(painter.morph, 0.9);
    });
  });
}
