import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutri_mobile_app/core/config/ai_endpoint.dart';
import 'package:nutri_mobile_app/core/config/environment_config.dart';
import 'package:nutri_mobile_app/core/mocks/mock_daily_log_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_nutrition_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_profile_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_projection_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_schedule_repository.dart';
import 'package:nutri_mobile_app/core/services/ai_chat_service.dart';
import 'package:nutri_mobile_app/core/state/ai_chat_controller.dart';
import 'package:nutri_mobile_app/core/state/daily_log_controller.dart';
import 'package:nutri_mobile_app/core/state/notification_navigation_controller.dart';
import 'package:nutri_mobile_app/core/state/nutrition_controller.dart';
import 'package:nutri_mobile_app/core/state/projection_controller.dart';
import 'package:nutri_mobile_app/core/state/schedule_controller.dart';
import 'package:nutri_mobile_app/core/state/user_profile_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/atoms/neumorphic_fab.dart';
import 'package:nutri_mobile_app/ui/pages/main_shell_page.dart';

Widget _shell({required bool enableAI}) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: MainShellPage(
      profileController: UserProfileController(
        repository: MockProfileRepository(),
      ),
      scheduleController: ScheduleController(
        repository: MockScheduleRepository(),
      ),
      nutritionController: NutritionController(
        repository: MockNutritionRepository(),
      ),
      projectionController: ProjectionController(
        repository: MockProjectionRepository(),
      ),
      aiChatController: AiChatController(
        service: AiChatService(
          baseUrl: 'http://test',
          client: MockClient(
            (request) async => http.Response('{"message":"ok"}', 200),
          ),
        ),
      ),
      notificationNav: NotificationNavigationController(),
      dailyLogController: DailyLogController(
        repository: MockDailyLogRepository(),
      ),
      enableAI: enableAI,
    ),
  );
}

Future<void> _pumpSized(WidgetTester tester, Widget widget) async {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}

void main() {
  group('resolveAiChatUri (URL-resolution helper)', () {
    test('uses the base URL verbatim for a plain host', () {
      expect(
        resolveAiChatUri('http://192.168.1.6:5039').toString(),
        'http://192.168.1.6:5039/api/ai/chat',
      );
    });

    test('strips a single trailing slash', () {
      expect(
        resolveAiChatUri('http://host:5039/').toString(),
        'http://host:5039/api/ai/chat',
      );
    });

    test('strips multiple trailing slashes', () {
      expect(
        resolveAiChatUri('http://host:5039///').toString(),
        'http://host:5039/api/ai/chat',
      );
    });

    test('trims surrounding whitespace before resolving', () {
      expect(
        resolveAiChatUri('  http://host:5039/  ').toString(),
        'http://host:5039/api/ai/chat',
      );
    });

    test('falls back to ApiConstants.baseUrl on empty input', () {
      final uri = resolveAiChatUri('');
      expect(uri.path, '/api/ai/chat');
      expect(uri.toString().isNotEmpty, isTrue);
    });

    test('falls back to ApiConstants.baseUrl on blank input', () {
      final uri = resolveAiChatUri('   ');
      expect(uri.path, '/api/ai/chat');
    });

    test('resolveLogParseUri shares the same normalization', () {
      expect(
        resolveLogParseUri('http://host:5039/').toString(),
        'http://host:5039/api/log/parse',
      );
      expect(resolveLogParseUri('').path, '/api/log/parse');
      expect(
        resolveLogParseUri('http://host:5039///').toString(),
        'http://host:5039/api/log/parse',
      );
    });
  });

  group('AI flavor matrix', () {
    test('local flavor disables AI, dev/qa/prod enable it', () {
      expect(
        EnvironmentConfig.fromFlavor(Flavor.local).enableAI,
        isFalse,
      );
      expect(EnvironmentConfig.fromFlavor(Flavor.dev).enableAI, isTrue);
      expect(EnvironmentConfig.fromFlavor(Flavor.qa).enableAI, isTrue);
      expect(EnvironmentConfig.fromFlavor(Flavor.prod).enableAI, isTrue);
    });
  });

  group('MainShellPage AI entry point', () {
    testWidgets('renders no FAB or chat entry when enableAI is false', (
      tester,
    ) async {
      await _pumpSized(tester, _shell(enableAI: false));

      expect(find.byKey(const Key('ai_chat_fab')), findsNothing);
      expect(find.byType(NeumorphicFab), findsNothing);
      expect(find.text('Ask AI'), findsNothing);
      expect(find.byTooltip('Ask AI'), findsNothing);
      // The unrelated Daily Log entry point stays visible.
      expect(find.byKey(const Key('daily_log_fab')), findsOneWidget);
    });

    testWidgets('renders the AI chat FAB when enableAI is true', (
      tester,
    ) async {
      await _pumpSized(tester, _shell(enableAI: true));

      expect(find.byKey(const Key('ai_chat_fab')), findsOneWidget);
      expect(find.byType(NeumorphicFab), findsOneWidget);
    });
  });
}
