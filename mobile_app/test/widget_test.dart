import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/app.dart';
import 'package:nutri_mobile_app/core/config/app_config.dart';
import 'package:nutri_mobile_app/core/config/environment_config.dart';
import 'package:nutri_mobile_app/core/mocks/mock_diet_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_routine_repository.dart';
import 'package:nutri_mobile_app/core/providers/environment_provider.dart';
import 'package:nutri_mobile_app/core/providers/routine_provider.dart';
import 'package:nutri_mobile_app/core/providers/wizard_provider.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/pages/home_page.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('home page renders mock routines and menus', (tester) async {
    tester.view.physicalSize = const Size(1000, 6000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) =>
                EnvironmentProvider(config: EnvironmentConfig.fromFlavor(Flavor.dev)),
          ),
          ListenableProxyProvider<EnvironmentProvider, RoutineProvider>(
            update: (_, env, __) =>
                RoutineProvider(env.routineRepository)..loadRoutine(),
          ),
          ListenableProxyProvider<EnvironmentProvider, RoutineWizardProvider>(
            update: (_, env, __) => RoutineWizardProvider(env.routineRepository),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: HomePage(
            dietRepository: MockDietRepository(),
            routineRepository: MockRoutineRepository(),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 50));

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

    await tester.pumpAndSettle();

    expect(find.text('Push Day'), findsOneWidget);
    expect(find.text('Nutrition'), findsOneWidget);
    expect(AppTheme.dark.scaffoldBackgroundColor, const Color(0xFF0F172A));
  });
}
