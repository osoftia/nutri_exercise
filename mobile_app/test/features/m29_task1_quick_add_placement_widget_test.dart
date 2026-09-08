import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/config/environment_config.dart';
import 'package:nutri_mobile_app/core/mocks/mock_diet_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_routine_repository.dart';
import 'package:nutri_mobile_app/core/providers/environment_provider.dart';
import 'package:nutri_mobile_app/core/providers/routine_provider.dart';
import 'package:nutri_mobile_app/core/providers/wizard_provider.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/organisms/interactive_body_map.dart';
import 'package:nutri_mobile_app/ui/pages/home_page.dart';
import 'package:provider/provider.dart';

Future<void> _pumpHome(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1000, 6000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => EnvironmentProvider(
            config: EnvironmentConfig.fromFlavor(Flavor.dev),
          ),
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

  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('there is exactly one Quick Add button', (tester) async {
    await _pumpHome(tester);

    expect(find.byKey(const Key('quick_add_button')), findsOneWidget);
  });

  testWidgets('Quick Add sits immediately below the body map, exclusively', (
    tester,
  ) async {
    await _pumpHome(tester);

    final quickAdd = find.byKey(const Key('quick_add_button'));
    final bodyMap = find.byType(InteractiveBodyMap).first;
    final profileCard = find.byKey(const Key('profile_edit_icon'));

    final quickAddRect = tester.getRect(quickAdd);
    final bodyMapRect = tester.getRect(bodyMap);

    // Immediately below the body map (small gap, no widget in between).
    expect(quickAddRect.top, greaterThanOrEqualTo(bodyMapRect.bottom));
    expect(quickAddRect.top, lessThan(bodyMapRect.bottom + 60));

    // The profile card is no longer between them (it sits above the map).
    if (profileCard.evaluate().isNotEmpty) {
      final profileRect = tester.getRect(profileCard);
      expect(profileRect.bottom, lessThanOrEqualTo(bodyMapRect.top));
    }
  });
}