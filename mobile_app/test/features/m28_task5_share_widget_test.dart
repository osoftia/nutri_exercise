import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/config/environment_config.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_log_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_diet_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_routine_repository.dart';
import 'package:nutri_mobile_app/core/providers/environment_provider.dart';
import 'package:nutri_mobile_app/core/providers/routine_provider.dart';
import 'package:nutri_mobile_app/core/providers/wizard_provider.dart';
import 'package:nutri_mobile_app/core/services/share_progress_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/organisms/social_share_card.dart';
import 'package:nutri_mobile_app/ui/pages/home_page.dart';
import 'package:provider/provider.dart';

/// Records the share request without rasterizing (capture is covered by the
/// ShareProgressController test).
class _RecordingShareController extends ShareProgressController {
  _RecordingShareController() : super(share: (files, {text}) async {});

  int calls = 0;

  @override
  Future<String?> shareCard(
    GlobalKey repaintKey, {
    String? text,
    String fileName = 'share_progress.png',
  }) async {
    calls++;
    return null;
  }
}

Future<void> _pumpHome(
  WidgetTester tester, {
  required ShareProgressController shareController,
}) async {
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
          dailyLogRepository: MockDailyLogRepository(streak: 3),
          shareController: shareController,
        ),
      ),
    ),
  );

  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  testWidgets('Home dashboard shows the Share Progress button and hidden card', (
    tester,
  ) async {
    final controller = _RecordingShareController();

    await _pumpHome(tester, shareController: controller);

    expect(find.byKey(const Key('share_progress_button')), findsOneWidget);
    expect(find.byType(SocialShareCard), findsOneWidget);
    expect(find.text('3 días'), findsOneWidget);
  });

  testWidgets('tapping Share Progress triggers the share flow', (tester) async {
    final controller = _RecordingShareController();

    await _pumpHome(tester, shareController: controller);

    await tester.tap(find.byKey(const Key('share_progress_button')));
    await tester.pump();

    expect(controller.calls, 1);
  });
}