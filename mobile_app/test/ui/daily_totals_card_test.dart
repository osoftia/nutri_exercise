import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/models/log_parse_response.dart';
import 'package:nutri_mobile_app/core/state/daily_nutrition_state.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/molecules/daily_totals_card.dart';

void main() {
  testWidgets('renders the three daily macro totals and calories', (
    tester,
  ) async {
    final state = DailyNutritionState();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: DailyTotalsCard(state: state)),
      ),
    );

    expect(find.byKey(const Key('daily_calories_total')), findsOneWidget);
    expect(find.byKey(const Key('daily_protein_total')), findsOneWidget);
    expect(find.byKey(const Key('daily_fat_total')), findsOneWidget);
  });

  testWidgets('shows the accumulated values after entries are added', (
    tester,
  ) async {
    final state = DailyNutritionState();
    state.add(const LogParseResponse(calories: 650, protein: 45, fat: 18));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: DailyTotalsCard(state: state)),
      ),
    );

    expect(find.text('650 kcal'), findsOneWidget);
    expect(find.text('45 g'), findsOneWidget);
    expect(find.text('18 g'), findsOneWidget);
  });
}
