import 'dart:convert';

import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutri_mobile_app/core/mocks/mock_nutrition_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_profile_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_projection_repository.dart';
import 'package:nutri_mobile_app/core/mocks/mock_schedule_repository.dart';
import 'package:nutri_mobile_app/core/services/ai_chat_service.dart';
import 'package:nutri_mobile_app/core/state/ai_chat_controller.dart';
import 'package:nutri_mobile_app/core/state/nutrition_controller.dart';
import 'package:nutri_mobile_app/core/state/projection_controller.dart';
import 'package:nutri_mobile_app/core/state/schedule_controller.dart';
import 'package:nutri_mobile_app/core/state/user_profile_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/atoms/neumorphic_fab.dart';
import 'package:nutri_mobile_app/ui/molecules/ai_chat_sheet.dart';
import 'package:nutri_mobile_app/ui/pages/main_shell_page.dart';

class _FakeConnectivity extends ConnectivityPlatform {
  _FakeConnectivity(this._results);

  final List<ConnectivityResult> _results;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => _results;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ConnectivityPlatform.instance = _FakeConnectivity([
      ConnectivityResult.wifi,
    ]);
  });

  Future<void> pumpShell(WidgetTester tester) async {
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
          aiChatController: AiChatController(
            service: AiChatService(
              baseUrl: 'http://test',
              client: MockClient((request) async {
                final body = jsonDecode(request.body) as Map<String, dynamic>;
                return http.Response(
                  jsonEncode({
                    'message': 'Mock AI routine for: ${body['message']}',
                  }),
                  200,
                );
              }),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the shell shows a neumorphic Ask AI floating action button', (
    tester,
  ) async {
    await pumpShell(tester);

    expect(find.byType(NeumorphicFab), findsOneWidget);
    expect(find.byTooltip('Ask AI'), findsOneWidget);
  });

  testWidgets('tapping the FAB opens the AI chat sheet', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.byTooltip('Ask AI'));
    await tester.pumpAndSettle();

    expect(find.byType(AiChatSheet), findsOneWidget);
    expect(find.byKey(const Key('ai_chat_input')), findsOneWidget);
  });

  testWidgets('asking the AI online yields a generated routine', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.byTooltip('Ask AI'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('ai_chat_input')),
      'Push pull 4 days',
    );
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(
      find.textContaining('Mock AI routine for: Push pull 4 days'),
      findsOneWidget,
    );
  });
}
