import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../services/ai_chat_service.dart';
import '../state/ai_chat_controller.dart';
import 'ai_endpoint_resolver.dart';
import 'environment_config.dart';

/// Builds the AI chat controller for [config], or returns `null` when the
/// active flavor disables AI (`enableAI == false`).
///
/// Keeping the decision (and the URL precedence) in one place lets the UI hide
/// every chat entry point by simply checking for `null`.
AiChatController? buildAiChatController(
  EnvironmentConfig config, {
  http.Client? client,
}) {
  if (!config.enableAI) return null;

  final baseUrl = AiEndpointResolver.resolveBaseUrl(
    dartDefineOverride: ApiConstants.dartDefineBaseUrl,
    flavorBaseUrl: config.apiBaseUrl,
    defaultBaseUrl: ApiConstants.defaultBaseUrl,
  );

  return AiChatController(
    service: AiChatService(baseUrl: baseUrl, client: client),
  );
}
