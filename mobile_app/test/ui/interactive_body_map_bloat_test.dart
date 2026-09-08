import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/state/muscle_tamagotchi_state.dart';
import 'package:nutri_mobile_app/ui/organisms/interactive_body_map.dart';

void main() {
  group('coreRenderScale', () {
    test('returns the settled scale when not bloating', () {
      expect(
        coreRenderScale(settledScale: 1.2, bloating: false, bloatT: 0.0),
        1.2,
      );
      expect(
        coreRenderScale(settledScale: 1.0, bloating: false, bloatT: 0.9),
        1.0,
      );
    });

    test('overshoots at the start of the bloat and settles at the end', () {
      const settled = 1.2;
      final start = coreRenderScale(
        settledScale: settled,
        bloating: true,
        bloatT: 0.0,
      );
      final end = coreRenderScale(
        settledScale: settled,
        bloating: true,
        bloatT: 1.0,
      );

      expect(start, greaterThan(settled));
      expect(end, settled);
    });

    test('grows monotonically with fullness through the state', () {
      final state = MuscleTamagotchiState();
      final before = state.settledCoreScale();
      state.applyNutrition(800);
      final after = state.settledCoreScale();

      expect(after, greaterThan(before));
      expect(
        coreRenderScale(settledScale: after, bloating: true, bloatT: 0.0),
        greaterThan(
          coreRenderScale(settledScale: before, bloating: true, bloatT: 0.0),
        ),
      );
    });
  });

  group('shouldRestartBloat', () {
    test('starts a bloat that was not bloating', () {
      expect(
        shouldRestartBloat(
          bloating: true,
          fullness: 0.3,
          lastFullness: 0.0,
          wasBloating: false,
        ),
        isTrue,
      );
    });

    test('restarts when fullness increases mid-bloat', () {
      expect(
        shouldRestartBloat(
          bloating: true,
          fullness: 0.6,
          lastFullness: 0.3,
          wasBloating: true,
        ),
        isTrue,
      );
    });

    test('does not restart for unrelated changes mid-bloat', () {
      expect(
        shouldRestartBloat(
          bloating: true,
          fullness: 0.3,
          lastFullness: 0.3,
          wasBloating: true,
        ),
        isFalse,
      );
    });

    test('never restarts when not bloating', () {
      expect(
        shouldRestartBloat(
          bloating: false,
          fullness: 0.3,
          lastFullness: 0.0,
          wasBloating: true,
        ),
        isFalse,
      );
    });
  });

  testWidgets('successive meals keep the map bloating and restart the swell',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 200,
            child: _HarnessBody(),
          ),
        ),
      ),
    );
    await tester.pump();

    stateFor(tester).applyNutrition(600);
    await tester.pump(const Duration(milliseconds: 100));
    expect(painterFor(tester).coreBloating, isTrue);
    await tester.pump(const Duration(milliseconds: 100));
    final double bloatAfterFirst = painterFor(tester).bloat as double;
    expect(bloatAfterFirst, greaterThan(0.0));

    stateFor(tester).applyNutrition(600);
    await tester.pump(const Duration(milliseconds: 50));

    expect(painterFor(tester).coreBloating, isTrue);
    expect(painterFor(tester).bloat as double, lessThan(bloatAfterFirst));
    expect(stateFor(tester).settledCoreScale(), greaterThan(1.0));
  });
}

MuscleTamagotchiState stateFor(WidgetTester tester) {
  final dynamic harness = tester.state(find.byType(_HarnessBody));
  return harness.state as MuscleTamagotchiState;
}

dynamic painterFor(WidgetTester tester) {
  final painted = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(InteractiveBodyMap),
      matching: find.byType(CustomPaint),
    ),
  );
  return painted.painter!;
}

class _HarnessBody extends StatefulWidget {
  const _HarnessBody();

  @override
  State<_HarnessBody> createState() => _HarnessBodyState();
}

class _HarnessBodyState extends State<_HarnessBody> {
  final MuscleTamagotchiState state = MuscleTamagotchiState();

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InteractiveBodyMap(tamagotchiState: state);
  }
}
