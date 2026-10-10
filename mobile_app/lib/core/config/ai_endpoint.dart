import '../constants/api_constants.dart';

/// Resolves the full chat URI for `POST /api/ai/chat`.
///
/// Trims trailing slashes from [baseUrl] and falls back to
/// [ApiConstants.baseUrl] when [baseUrl] is blank, so every flavor
/// (dev/local/qa/prod) and `--dart-define=API_BASE_URL=...` override
/// produces the same canonical endpoint.
Uri resolveAiChatUri(String baseUrl) {
  final trimmed = baseUrl.trim();
  final normalized =
      trimmed.isEmpty ? ApiConstants.baseUrl : _stripTrailingSlashes(trimmed);
  return Uri.parse('$normalized${ApiConstants.aiChatPath}');
}

/// Resolves the full parse URI for `POST /api/log/parse` with the same
/// normalization rules as [resolveAiChatUri].
Uri resolveLogParseUri(String baseUrl) {
  final trimmed = baseUrl.trim();
  final normalized =
      trimmed.isEmpty ? ApiConstants.baseUrl : _stripTrailingSlashes(trimmed);
  return Uri.parse('$normalized${ApiConstants.logParsePath}');
}

String _stripTrailingSlashes(String value) {
  var end = value.length;
  while (end > 0 && value[end - 1] == '/') {
    end--;
  }
  return value.substring(0, end);
}
