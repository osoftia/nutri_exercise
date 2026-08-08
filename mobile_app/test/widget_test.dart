import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/app.dart';
import 'package:nutri_mobile_app/core/config/app_config.dart';
import 'package:nutri_mobile_app/core/mocks/mock_diet_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_routine_repository.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/pages/home_page.dart';

void main() {
  testWidgets('home page renders mock routines and menus', (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: HomePage(
          dietRepository: MockDietRepository(),
          routineRepository: MockRoutineRepository(),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Admin Dashboard'), findsOneWidget);
    expect(find.text('Weekly Routines'), findsOneWidget);
    expect(find.text('Monday'), findsOneWidget);
    expect(find.text('Daily Menus'), findsOneWidget);
    expect(find.text('2026-08-07'), findsOneWidget);
  });

  testWidgets('NutriApp dev config uses mocks and applies theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      const NutriApp(config: AppConfig(name: 'dev', useMocks: true)),
    );

    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Admin Dashboard'), findsOneWidget);
    expect(AppTheme.dark.scaffoldBackgroundColor, const Color(0xFF0F172A));
  });
}
