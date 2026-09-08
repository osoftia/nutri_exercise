import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/state/muscle_tamagotchi_state.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/organisms/interactive_body_map.dart';
import 'package:nutri_mobile_app/ui/organisms/social_share_card.dart';

void main() {
  final repaintKey = GlobalKey();

  Widget harness({
    int streak = 5,
    MuscleTamagotchiState? tamagotchi,
    String? message,
  }) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: SocialShareCard(
            repaintKey: repaintKey,
            tamagotchiState: tamagotchi ?? MuscleTamagotchiState(),
            streak: streak,
            motivationalMessage: message,
          ),
        ),
      ),
    );
  }

  testWidgets('the card is a RepaintBoundary with the given GlobalKey', (
    tester,
  ) async {
    await tester.pumpWidget(harness());

    final boundary = tester.widget<RepaintBoundary>(
      find.byKey(repaintKey),
    );
    expect(boundary, isNotNull);
  });

  testWidgets('the card renders the InteractiveBodyMap', (tester) async {
    await tester.pumpWidget(harness());

    expect(find.byType(InteractiveBodyMap), findsOneWidget);
  });

  testWidgets('the card shows the streak count with a flame', (tester) async {
    await tester.pumpWidget(harness(streak: 5));

    expect(find.byKey(const Key('streak_count')), findsOneWidget);
    expect(find.text('5 días'), findsOneWidget);
    expect(find.text('🔥'), findsOneWidget);
  });

  testWidgets('the card shows a motivational summary', (tester) async {
    await tester.pumpWidget(harness(streak: 5));

    expect(find.byKey(const Key('motivational_message')), findsOneWidget);
    expect(find.textContaining('racha'), findsWidgets);
  });

  testWidgets('a custom motivational message is used when provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(streak: 1, message: 'Custom message here'),
    );

    expect(find.text('Custom message here'), findsOneWidget);
  });
}