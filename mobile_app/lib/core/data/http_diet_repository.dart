import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/diet_models.dart';
import 'diet_repository.dart';
import '../services/global_error_handler.dart';
import '../services/http_timeout_configuration.dart';

class HttpDietRepository implements DietRepository {
  HttpDietRepository(
    this.baseUrl, {
    DietRepository? fallback,
    Duration? timeout,
  })  : _fallback = fallback,
        _timeoutOverride = timeout;

  final String baseUrl;
  final DietRepository? _fallback;
  final Duration? _timeoutOverride;
  Duration get timeout =>
      _timeoutOverride ?? HttpTimeoutConfiguration.currentTimeout;

  @override
  Future<List<DailyMenu>> getDailyMenus() async {
    final uri = Uri.parse('$baseUrl/api/v1/diets/menus');
    try {
      final response = await http.get(uri).timeout(timeout);
      if (response.statusCode != 200) {
        throw AppHttpStatusException(
          response.statusCode,
          response.reasonPhrase ?? 'HTTP error',
        );
      }
      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((menu) => DailyMenu.fromJson(menu as Map<String, dynamic>))
          .toList();
    } catch (error, stackTrace) {
      await ErrorHandlerRegistry.capture(error, stackTrace, requestUri: uri);
      return _fallback?.getDailyMenus() ?? <DailyMenu>[];
    }
  }
}
