import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:nutri_mobile_app/core/config/ai_endpoint.dart';
import 'package:nutri_mobile_app/core/constants/api_constants.dart';
import 'package:nutri_mobile_app/core/services/ai_chat_service.dart';
import 'package:nutri_mobile_app/core/services/log_parse_service.dart';

/// Live backend bridge smoke test (M37-A/B).
///
/// Run against the running .NET API:
/// `flutter test integration_test/ai_bridge_smoke_test.dart
/// --dart-define=API_BASE_URL=http://192.168.1.6:5039`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('live POST /api/log/parse accepts {"text": ...}', (
    tester,
  ) async {
    final service = LogParseService(baseUrl: ApiConstants.baseUrl);
    final uri = resolveLogParseUri(ApiConstants.baseUrl);

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': 'Ate chicken and rice'}),
    );

    expect(
      response.statusCode,
      200,
      reason: 'Backend must accept {"text"} at $uri',
    );
    final parsed = await service.parse('Ate chicken and rice');
    expect(parsed.calories, greaterThanOrEqualTo(0));
  });

  testWidgets('live POST /api/ai/chat returns an assistant message', (
    tester,
  ) async {
    final service = AiChatService(baseUrl: ApiConstants.baseUrl);
    final reply = await service.sendMessage(message: 'Say hello briefly');

    expect(reply.isNotEmpty, isTrue);
  });
}
