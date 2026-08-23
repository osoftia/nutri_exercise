import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_projection_repository.dart';
import 'package:nutri_mobile_app/core/models/user_profile.dart';
import 'package:nutri_mobile_app/core/state/projection_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/atoms/projection_avatar.dart';
import 'package:nutri_mobile_app/ui/pages/routines_page.dart';

void main() {
  Future<ProjectionController> pumpRoutines(
    WidgetTester tester, {
    FitnessGoal goal = FitnessGoal.muscleGain,
  }) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final controller = ProjectionController(
      repository: MockProjectionRepository(goal: goal),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: RoutinesPage(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  ProjectionAvatarPainter painter(WidgetTester tester) {
    final customPaint = tester.widget<CustomPaint>(
      find.byKey(const Key('projection_avatar')),
    );
    return customPaint.painter! as ProjectionAvatarPainter;
  }

  group('Body projection (Routines tab)', () {
    testWidgets('shows the timeline with four milestones', (tester) async {
      await pumpRoutines(tester);

      expect(find.byKey(const Key('timeline_0')), findsOneWidget);
      expect(find.byKey(const Key('timeline_1')), findsOneWidget);
      expect(find.byKey(const Key('timeline_3')), findsOneWidget);
      expect(find.byKey(const Key('timeline_6')), findsOneWidget);
    });

    testWidgets('baseline shows neutral shoulder and waist factors', (
      tester,
    ) async {
      await pumpRoutines(tester);

      expect(painter(tester).shoulderFactor, 0.5);
      expect(painter(tester).waistFactor, 0.5);
    });

    testWidgets('selecting 1m updates the summary and morphs the avatar', (
      tester,
    ) async {
      await pumpRoutines(tester);

      await tester.tap(find.byKey(const Key('timeline_1')));
      await tester.pumpAndSettle();

      expect(find.text('71.5 kg · Foundation'), findsOneWidget);
      expect(painter(tester).shoulderFactor, greaterThan(0.5));
    });

    testWidgets('selecting 6m shows the broadest shoulders for muscle gain', (
      tester,
    ) async {
      await pumpRoutines(tester);

      await tester.tap(find.byKey(const Key('timeline_6')));
      await tester.pumpAndSettle();

      expect(painter(tester).shoulderFactor, 1.0);
      expect(painter(tester).waistFactor, lessThan(0.5));
      expect(find.text('76.0 kg · Peak Build'), findsOneWidget);
    });

    testWidgets('fat loss plan slims the waist the most at 6m', (tester) async {
      await pumpRoutines(tester, goal: FitnessGoal.fatLoss);

      await tester.tap(find.byKey(const Key('timeline_6')));
      await tester.pumpAndSettle();

      expect(painter(tester).waistFactor, 0.25);
      expect(painter(tester).waistFactor, lessThan(0.5));
    });
  });
}
