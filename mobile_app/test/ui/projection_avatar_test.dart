import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/ui/atoms/projection_avatar.dart';

void main() {
  group('ProjectionAvatarPainter', () {
    test('exposes shoulder and waist factors', () {
      const painter = ProjectionAvatarPainter(
        shoulderFactor: 0.8,
        waistFactor: 0.3,
      );
      expect(painter.shoulderFactor, 0.8);
      expect(painter.waistFactor, 0.3);
    });

    test('repaints when either factor changes', () {
      const a = ProjectionAvatarPainter(
        shoulderFactor: 0.5,
        waistFactor: 0.5,
      );
      const b = ProjectionAvatarPainter(
        shoulderFactor: 0.6,
        waistFactor: 0.5,
      );
      expect(a.shouldRepaint(b), isTrue);
    });
  });

  group('ProjectionAvatar', () {
    Future<ProjectionAvatarPainter> painter(
      WidgetTester tester,
      double shoulder,
      double waist,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectionAvatar(
              shoulderFactor: shoulder,
              waistFactor: waist,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final customPaint = tester.widget<CustomPaint>(
        find.byKey(const Key('projection_avatar')),
      );
      return customPaint.painter! as ProjectionAvatarPainter;
    }

    testWidgets('renders the given factors after settling', (tester) async {
      final p = await painter(tester, 0.8, 0.3);
      expect(p.shoulderFactor, 0.8);
      expect(p.waistFactor, 0.3);
    });

    testWidgets('morphs when factors change', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectionAvatar(shoulderFactor: 0.5, waistFactor: 0.5),
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectionAvatar(shoulderFactor: 1.0, waistFactor: 0.25),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final customPaint = tester.widget<CustomPaint>(
        find.byKey(const Key('projection_avatar')),
      );
      final p = customPaint.painter! as ProjectionAvatarPainter;
      expect(p.shoulderFactor, 1.0);
      expect(p.waistFactor, 0.25);
    });
  });
}
