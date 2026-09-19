import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/config/ai_chat_factory.dart';
import 'package:nutri_mobile_app/core/config/ai_endpoint_resolver.dart';
import 'package:nutri_mobile_app/core/config/environment_config.dart';
import 'package:nutri_mobile_app/core/mocks/mock_body_detail_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_log_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_nutrition_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_profile_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_projection_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_schedule_repository.dart';
import 'package:nutri_mobile_app/core/services/rule_based_muscle_gap_advisor.dart';
import 'package:nutri_mobile_app/core/state/ai_chat_controller.dart';
import 'package:nutri_mobile_app/core/state/body_detail_controller.dart';
import 'package:nutri_mobile_app/core/state/daily_log_controller.dart';
import 'package:nutri_mobile_app/core/state/notification_navigation_controller.dart';
import 'package:nutri_mobile_app/core/state/nutrition_controller.dart';
import 'package:nutri_mobile_app/core/state/projection_controller.dart';
import 'package:nutri_mobile_app/core/state/schedule_controller.dart';
import 'package:nutri_mobile_app/core/state/user_profile_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/atoms/neumorphic_fab.dart';
import 'package:nutri_mobile_app/ui/pages/main_shell_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AiEndpointResolver.resolveBaseUrl', () {
    test('prefers the dart-define override over flavor and default', () {
      final resolved = AiEndpointResolver.resolveBaseUrl(
        dartDefineOverride: 'http://define:5039',
        flavorBaseUrl: 'http://flavor:5039',
        defaultBaseUrl: 'http://default:5039',
      );

      expect(resolved, 'http://define:5039');
    });

    test('falls back to the flavor URL when no override is set', () {
      final resolved = AiEndpointResolver.resolveBaseUrl(
        dartDefineOverride: '',
        flavorBaseUrl: 'http://flavor:5039',
        defaultBaseUrl: 'http://default:5039',
      );

      expect(resolved, 'http://flavor:5039');
    });

    test('falls back to the built-in default when both are empty', () {
      final resolved = AiEndpointResolver.resolveBaseUrl(
        dartDefineOverride: '',
        flavorBaseUrl: '',
        defaultBaseUrl: 'http://default:5039',
      );

      expect(resolved, 'http://default:5039');
    });
  });

  group('buildAiChatController', () {
    test('returns null when the flavor disables AI', () {
      final controller = buildAiChatController(
        EnvironmentConfig.fromFlavor(Flavor.local),
      );

      expect(controller, isNull);
    });

    test('returns a controller when the flavor enables AI', () {
      final controller = buildAiChatController(
        EnvironmentConfig.fromFlavor(Flavor.dev),
      );

      expect(controller, isA<AiChatController>());
    });

    test('returns a controller for a custom flavor with an apiBaseUrl', () {
      const config = EnvironmentConfig(
        name: 'staging',
        useMockApi: false,
        apiBaseUrl: 'http://10.0.2.2:5039',
        enableAI: true,
      );

      expect(buildAiChatController(config), isA<AiChatController>());
    });
  });

  group('AI entry point visibility', () {
    Future<void> pumpShell(
      WidgetTester tester, {
      required AiChatController? aiChatController,
    }) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: MainShellPage(
            profileController: UserProfileController(
              repository: MockProfileRepository(),
            ),
            scheduleController: ScheduleController(
              repository: MockScheduleRepository(),
              initialMonth: DateTime(2026, 8),
            ),
            nutritionController: NutritionController(
              repository: MockNutritionRepository(),
            ),
            projectionController: ProjectionController(
              repository: MockProjectionRepository(),
            ),
            bodyDetailController: BodyDetailController(
              repository: MockBodyDetailRepository(),
              advisor: const RuleBasedMuscleGapAdvisor(),
            ),
            aiChatController: aiChatController,
            notificationNav: NotificationNavigationController(),
            dailyLogController: DailyLogController(
              repository: MockDailyLogRepository(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders no chat entry point when AI is disabled', (
      tester,
    ) async {
      await pumpShell(tester, aiChatController: null);

      expect(find.byType(NeumorphicFab), findsNothing);
      expect(find.byTooltip('Ask AI'), findsNothing);
      // The Daily Log FAB must still be available.
      expect(find.byKey(const Key('daily_log_fab')), findsOneWidget);
    });

    testWidgets('renders the Ask AI FAB when AI is enabled', (tester) async {
      await pumpShell(
        tester,
        aiChatController: buildAiChatController(
          EnvironmentConfig.fromFlavor(Flavor.dev),
        ),
      );

      expect(find.byTooltip('Ask AI'), findsOneWidget);
    });
  });
}
