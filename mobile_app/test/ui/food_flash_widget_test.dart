import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/models/log_parse_response.dart';
import 'package:nutri_mobile_app/core/state/muscle_tamagotchi_state.dart';
import 'package:nutri_mobile_app/ui/organisms/interactive_body_map.dart';

dynamic _mapPainter(WidgetTester tester) {
  final painted = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(InteractiveBodyMap),
      matching: find.byType(CustomPaint),
    ),
  );
  return painted.painter!;
}

void main() {
  testWidgets('food log flashes the stomach red for 2 seconds', (
    tester,
  ) async {
    final tamagotchi = MuscleTamagotchiState();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InteractiveBodyMap(
            tamagotchiState: tamagotchi,
            animate: false,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(_mapPainter(tester).foodFlash as bool, isFalse);

    tamagotchi.applyMeal(
      const LogParseResponse(calories: 650, protein: 45, fat: 18),
    );
    await tester.pump();

    expect(_mapPainter(tester).foodFlash as bool, isTrue);

    await tester.pump(MuscleTamagotchiState.foodFlashDuration);
    await tester.pump(const Duration(milliseconds: 100));

    expect(_mapPainter(tester).foodFlash as bool, isFalse);
  });
}
