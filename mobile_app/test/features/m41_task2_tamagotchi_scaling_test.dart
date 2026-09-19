import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_diagram_view_model.dart';
import 'package:nutri_mobile_app/core/domain/body_projection/body_segment.dart';
import 'package:nutri_mobile_app/core/mocks/mock_body_detail_repository.dart';
import 'package:nutri_mobile_app/core/services/rule_based_muscle_gap_advisor.dart';
import 'package:nutri_mobile_app/core/services/tamagotchi_scale_mapper.dart';
import 'package:nutri_mobile_app/core/state/body_detail_controller.dart';
import 'package:nutri_mobile_app/core/state/muscle_tamagotchi_state.dart';
import 'package:nutri_mobile_app/ui/organisms/body_blueprint/body_blueprint_diagram.dart';
import 'package:nutri_mobile_app/ui/organisms/body_blueprint/body_blueprint_painter.dart';

void main() {
  group('M41 tamagotchi scale mapper', () {
    double scaleFor(
      BodySegment segment, {
      double chestMass = 0.5,
      double armsMass = 0.5,
      double legsMass = 0.5,
      double coreFullness = 0.0,
    }) {
      final scales = tamagotchiScaleFactors(
        mass: (group) => switch (group) {
          MuscleTamagotchiGroup.chest => chestMass,
          MuscleTamagotchiGroup.arms => armsMass,
          MuscleTamagotchiGroup.legs => legsMass,
          MuscleTamagotchiGroup.core => 0.5,
        },
        coreFullness: coreFullness,
      );
      return scales[segment]!;
    }

    test('baseline mass maps to a neutral scale', () {
      expect(scaleFor(BodySegment.chest), closeTo(1.0, 0.0001));
    });

    test('full muscle mass hypertrophies the segment', () {
      expect(scaleFor(BodySegment.chest, chestMass: 1.0), closeTo(1.25, 0.0001));
      expect(scaleFor(BodySegment.rightCalf, legsMass: 1.0), closeTo(1.25, 0.0001));
      expect(scaleFor(BodySegment.leftForearm, armsMass: 0.0), closeTo(0.75, 0.0001));
    });

    test('core fullness bloats the abdomen', () {
      expect(scaleFor(BodySegment.abdomen, coreFullness: 0.8), closeTo(1.15, 0.0001));
      expect(
        scaleFor(BodySegment.abdomen, coreFullness: 0.8),
        greaterThan(scaleFor(BodySegment.abdomen)),
      );
    });
  });

  group('M41 controller tamagotchi scaling', () {
    test('growing a muscle increases the diagram scale and notifies', () {
      final tamagotchi = MuscleTamagotchiState();
      final controller = BodyDetailController(
        repository: MockBodyDetailRepository(),
        advisor: const RuleBasedMuscleGapAdvisor(),
        tamagotchi: tamagotchi,
      );
      final before = controller.buildViewModel().scaleFor(BodySegment.chest);
      var notifications = 0;
      controller.addListener(() => notifications++);

      tamagotchi.applyGrowth(const [MuscleTamagotchiGroup.chest]);

      expect(
        controller.buildViewModel().scaleFor(BodySegment.chest),
        greaterThan(before),
      );
      expect(notifications, greaterThan(0));
      controller.dispose();
    });

    test('feeding the tamagotchi bloats the abdomen scale', () {
      final tamagotchi = MuscleTamagotchiState();
      final controller = BodyDetailController(
        repository: MockBodyDetailRepository(),
        advisor: const RuleBasedMuscleGapAdvisor(),
        tamagotchi: tamagotchi,
      );
      final before = controller.buildViewModel().scaleFor(BodySegment.abdomen);

      tamagotchi.applyNutrition(1000);

      expect(
        controller.buildViewModel().scaleFor(BodySegment.abdomen),
        greaterThan(before),
      );
      controller.dispose();
    });
  });

  group('M41 animated blueprint', () {
    testWidgets('interpolates the chest scale while animating', (tester) async {
      const size = Size(720, 420);
      Widget build(BodyDiagramViewModel viewModel) => MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: size.width,
                height: size.height,
                child: BodyBlueprintDiagram(
                  viewModel: viewModel,
                  animationDuration: const Duration(milliseconds: 400),
                ),
              ),
            ),
          );

      await tester.pumpWidget(
        build(const BodyDiagramViewModel(
          scaleFactors: {BodySegment.chest: 1.0},
        )),
      );
      await tester.pumpWidget(
        build(const BodyDiagramViewModel(
          scaleFactors: {BodySegment.chest: 2.0},
        )),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final painter = tester
          .widget<CustomPaint>(find.byKey(const Key('body_blueprint_paint')))
          .painter! as BodyBlueprintPainter;
      final scale = painter.viewModel.scaleFor(BodySegment.chest);
      expect(scale, greaterThan(1.0));
      expect(scale, lessThan(2.0));

      await tester.pumpAndSettle();
    });
  });
}
