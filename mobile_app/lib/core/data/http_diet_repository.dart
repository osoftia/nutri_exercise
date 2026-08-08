import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/diet_models.dart';
import 'diet_repository.dart';

class HttpDietRepository implements DietRepository {
  HttpDietRepository(this.baseUrl);

  final String baseUrl;

  @override
  Future<List<DailyMenu>> getDailyMenus() async {
    final response = await http.get(Uri.parse('$baseUrl/api/v1/diets/menus'));
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((menu) => DailyMenu.fromJson(menu as Map<String, dynamic>))
        .toList();
  }
}
