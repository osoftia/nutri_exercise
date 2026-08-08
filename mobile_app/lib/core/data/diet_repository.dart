import '../models/diet_models.dart';

abstract interface class DietRepository {
  Future<List<DailyMenu>> getDailyMenus();
}
