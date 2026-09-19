import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nutri_mobile_app/core/constants/api_constants.dart';
import 'package:nutri_mobile_app/core/services/ai_chat_service.dart';
import 'package:nutri_mobile_app/core/services/log_parse_service.dart';

/// Opt-in live smoke tests against the real backend + Ollama.
///
/// Run with:
/// `flutter test integration_test/backend_smoke_test.dart \
///    --dart-define=LIVE_BACKEND=true`
const bool _liveBackend = bool.fromEnvironment('LIVE_BACKEND');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'live /api/log/parse accepts the text field and returns structured data',
    (tester) async {
      final service = LogParseService(baseUrl: ApiConstants.baseUrl);

      final result = await service.parse(
        'I ate 200g of chicken breast and a bowl of rice',
      );

      // A 200 response proves the request body key matches ParseLogRequest
      // (the old `rawText` key produced a 400 from the backend).
      expect(result.calories, greaterThanOrEqualTo(0));
    },
    skip: !_liveBackend,
  );

  testWidgets(
    'live /api/aiproxy/chat returns a non-empty assistant reply',
    (tester) async {
      final service = AiChatService(baseUrl: ApiConstants.baseUrl);

      final reply = await service.sendMessage(
        message: 'Give me one beginner hypertrophy tip',
      );

      expect(reply.trim(), isNotEmpty);
    },
    skip: !_liveBackend,
  );
}
