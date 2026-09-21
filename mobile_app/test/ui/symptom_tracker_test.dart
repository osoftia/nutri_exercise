import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_symptom_repository.dart';
import 'package:nutri_mobile_app/core/models/symptom_log.dart';
import 'package:nutri_mobile_app/core/state/symptom_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/atoms/circular_icon_button.dart';
import 'package:nutri_mobile_app/ui/molecules/symptom_tracker.dart';

void main() {
  Future<SymptomController> pumpTracker(
    WidgetTester tester, {
    List<SymptomLog>? seed,
  }) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repository = MockSymptomRepository(seed);
    final controller = SymptomController(
      repository: repository,
      date: DateTime(2026, 9, 21),
    );
    await controller.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: SymptomTracker(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  group('SymptomTracker (M45 Task 2)', () {
    testWidgets('renders a circular button for every symptom', (tester) async {
      await pumpTracker(tester);

      expect(find.byKey(const Key('symptom_tracker')), findsOneWidget);
      for (final type in SymptomType.values) {
        expect(find.byKey(Key('symptom_${type.name}')), findsOneWidget);
      }
      expect(find.byType(CircularIconButton), findsNWidgets(4));
    });

    testWidgets('tapping a symptom cycles its severity and persists it', (
      tester,
    ) async {
      final controller = await pumpTracker(tester);

      await tester.tap(find.byKey(const Key('symptom_pain')));
      await tester.pumpAndSettle();

      expect(controller.levelOf(SymptomType.pain), 1);
      expect(find.textContaining('Pain: Mild'), findsOneWidget);
    });

    testWidgets('shows a long-press tooltip explaining the symptom', (
      tester,
    ) async {
      await pumpTracker(tester);

      await tester.longPress(find.byKey(const Key('symptom_energy')));
      await tester.pumpAndSettle();

      expect(
        find.text('Energy — tap to cycle severity'),
        findsWidgets,
      );
    });

    testWidgets('hydrates a seeded reading into the readout', (tester) async {
      await pumpTracker(
        tester,
        seed: const [
          SymptomLog(
            date: '2026-09-21',
            symptom: SymptomType.discomfort,
            level: 2,
          ),
        ],
      );

      expect(find.textContaining('Body discomfort: Moderate'), findsOneWidget);
    });

    testWidgets('shows an empty-state caption when nothing is logged', (
      tester,
    ) async {
      await pumpTracker(tester);

      expect(find.text('No symptoms logged today.'), findsOneWidget);
    });
  });
}
