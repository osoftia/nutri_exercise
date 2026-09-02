import 'package:flutter/foundation.dart';

import '../config/environment_config.dart';
import '../constants/api_constants.dart';
import '../data/api_routine_repository.dart';
import '../data/diet_repository.dart';
import '../data/http_diet_repository.dart';
import '../data/local_diet_repository.dart';
import '../data/local_routine_repository.dart';
import '../data/routine_repository.dart';
import '../mocks/mock_diet_repository.dart';
import '../mocks/mock_routine_repository.dart';

/// Runtime-switchable repository factory.
///
/// Holds the active [Flavor] and exposes the matching repository
/// implementations. Call [setFlavor] to switch Mock / Local / API at
/// runtime; listeners (RoutineProvider, RoutineWizardProvider) rebuild.
class EnvironmentProvider extends ChangeNotifier {
  EnvironmentProvider({required EnvironmentConfig config}) : _config = config;

  EnvironmentConfig _config;
  late DietRepository _dietRepository = _buildDietRepository();
  late RoutineRepository _routineRepository = _buildRoutineRepository();

  EnvironmentConfig get config => _config;
  Flavor get flavor => _config.flavor;
  DietRepository get dietRepository => _dietRepository;
  RoutineRepository get routineRepository => _routineRepository;

  void setFlavor(Flavor flavor) {
    if (flavor == _config.flavor) return;
    _config = EnvironmentConfig.fromFlavor(flavor);
    _dietRepository = _buildDietRepository();
    _routineRepository = _buildRoutineRepository();
    notifyListeners();
  }

  DietRepository _buildDietRepository() {
    if (_config.useMockApi) return MockDietRepository();
    if (_config.useLocalDatabase) return LocalDietRepository();
    return HttpDietRepository(
      _config.apiBaseUrl.isEmpty ? ApiConstants.baseUrl : _config.apiBaseUrl,
      fallback: LocalDietRepository(),
    );
  }

  RoutineRepository _buildRoutineRepository() {
    if (_config.useMockApi) {
      return MockRoutineRepository(latency: _config.mockLatency);
    }
    if (_config.useLocalDatabase) return LocalRoutineRepository();
    return ApiRoutineRepository(
      _config.apiBaseUrl.isEmpty ? ApiConstants.baseUrl : _config.apiBaseUrl,
      fallback: LocalRoutineRepository(),
    );
  }
}