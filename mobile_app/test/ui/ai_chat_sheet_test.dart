import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nutri_mobile_app/core/services/ai_chat_service.dart';
import 'package:nutri_mobile_app/core/state/ai_chat_controller.dart';
import 'package:nutri_mobile_app/core/theme/app_theme.dart';
import 'package:nutri_mobile_app/ui/molecules/ai_chat_sheet.dart';
import 'package:nutri_mobile_app/ui/molecules/offline_ai_dialog.dart';

class _FakeConnectivity extends ConnectivityPlatform {
  _FakeConnectivity(this._results);

  final List<ConnectivityResult> _results;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => _results;
}

class _ThrowingConnectivity extends ConnectivityPlatform {
  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    throw StateError('connectivity platform error');
  }
}

AiChatController _controllerWith(MockClient client) => AiChatController(
  service: AiChatService(baseUrl: 'http://test', client: client),
);

MockClient _okClient() => MockClient(
  (request) async =>
      http.Response(jsonEncode({'message': 'Here is your routine'}), 200),
);

void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    AiChatController? controller,
  }) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: SizedBox()),
      ),
    );
    showAiChatSheet(
      tester.element(find.byType(Scaffold)),
      controller ?? _controllerWith(_okClient()),
    );
    await tester.pumpAndSettle();
  }

  group('AiChatSheet', () {
    setUp(() {
      ConnectivityPlatform.instance = _FakeConnectivity([
        ConnectivityResult.wifi,
      ]);
    });

    testWidgets('opens with an input field and a send button', (tester) async {
      await pumpSheet(tester);

      expect(find.byType(AiChatSheet), findsOneWidget);
      expect(find.byKey(const Key('ai_chat_input')), findsOneWidget);
      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('ignores an empty message', (tester) async {
      await pumpSheet(tester);

      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      expect(find.byKey(const Key('ai_chat_bubble_0')), findsNothing);
      expect(find.text('Ask me to build a workout routine.'), findsOneWidget);
    });

    testWidgets('shows the user message and an assistant reply when online', (
      tester,
    ) async {
      await pumpSheet(tester);

      await tester.enterText(
        find.byKey(const Key('ai_chat_input')),
        'Push pull 4 days',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      await tester.pump();

      expect(find.text('Push pull 4 days'), findsOneWidget);

      await tester.pump();
      await tester.pump();

      expect(find.text('Here is your routine'), findsOneWidget);
    });

    testWidgets('shows a loading indicator while waiting for the reply', (
      tester,
    ) async {
      final completer = Completer<http.Response>();
      final client = MockClient((request) => completer.future);
      await pumpSheet(tester, controller: _controllerWith(client));

      await tester.enterText(
        find.byKey(const Key('ai_chat_input')),
        'Push pull 4 days',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('ai_chat_loading')), findsOneWidget);

      completer.complete(
        http.Response(jsonEncode({'message': 'Here is your routine'}), 200),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Here is your routine'), findsOneWidget);
      expect(find.byKey(const Key('ai_chat_loading')), findsNothing);
    });

    testWidgets('shows the Offline AI dialog when offline', (tester) async {
      ConnectivityPlatform.instance = _FakeConnectivity([
        ConnectivityResult.none,
      ]);

      await pumpSheet(tester);

      await tester.enterText(
        find.byKey(const Key('ai_chat_input')),
        'Push pull 4 days',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      await tester.pump();

      expect(find.byType(OfflineAiDialog), findsOneWidget);
      expect(find.text('Push pull 4 days'), findsOneWidget);
    });

    testWidgets('closing the sheet disposes the input controller cleanly', (
      tester,
    ) async {
      await pumpSheet(tester);

      await tester.enterText(find.byKey(const Key('ai_chat_input')), 'hi');
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(AiChatSheet), findsNothing);
    });

    testWidgets('submitting the field via keyboard action sends the message', (
      tester,
    ) async {
      await pumpSheet(tester);

      await tester.enterText(
        find.byKey(const Key('ai_chat_input')),
        'Push pull 4 days',
      );
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
      await tester.pump();

      expect(find.text('Push pull 4 days'), findsOneWidget);

      await tester.pump();
      await tester.pump();

      expect(find.text('Here is your routine'), findsOneWidget);
    });

    testWidgets('shows an error when the connectivity check fails', (
      tester,
    ) async {
      ConnectivityPlatform.instance = _ThrowingConnectivity();

      await pumpSheet(tester);

      await tester.enterText(
        find.byKey(const Key('ai_chat_input')),
        'Push pull 4 days',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      await tester.pump();

      expect(find.text('AI service unavailable right now.'), findsOneWidget);
    });

    testWidgets('shows an error when the backend returns a 500', (
      tester,
    ) async {
      final client = MockClient(
        (request) async => http.Response('{}', 500),
      );
      await pumpSheet(tester, controller: _controllerWith(client));

      await tester.enterText(
        find.byKey(const Key('ai_chat_input')),
        'Push pull 4 days',
      );
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      await tester.pump();

      expect(find.text('Push pull 4 days'), findsOneWidget);

      await tester.pump();
      await tester.pump();

      expect(
        find.text('The assistant is unavailable right now.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('ai_chat_error')), findsOneWidget);
    });
  });
}
