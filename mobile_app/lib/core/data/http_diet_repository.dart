import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/diet_models.dart';
import 'diet_repository.dart';

class HttpDietRepository implements DietRepository {
  HttpDietRepository(this.baseUrl, {DietRepository? fallback})
    : _fallback = fallback;

  final String baseUrl;
  final DietRepository? _fallback;

  static const Duration _timeout = Duration(seconds: 10);

  @override
  Future<List<DailyMenu>> getDailyMenus() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/v1/diets/menus'))
          .timeout(_timeout);
      if (response.statusCode != 200) {
        throw http.ClientException(
          'Unexpected status code ${response.statusCode}',
          Uri.parse('$baseUrl/api/v1/diets/menus'),
        );
      }
      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((menu) => DailyMenu.fromJson(menu as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _fallback?.getDailyMenus() ?? <DailyMenu>[];
    }
  }
}
