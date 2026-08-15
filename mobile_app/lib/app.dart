import 'package:flutter/material.dart';

import 'core/config/environment_config.dart';
import 'core/constants/api_constants.dart';
import 'core/data/diet_repository.dart';
import 'core/data/http_diet_repository.dart';
import 'core/data/http_routine_repository.dart';
import 'core/data/local_diet_repository.dart';
import 'core/data/local_routine_repository.dart';
import 'core/data/routine_repository.dart';
import 'core/mocks/mock_diet_repository.dart';
import 'core/mocks/mock_routine_repository.dart';
import 'core/theme/app_theme.dart';
import 'ui/pages/home_page.dart';

class NutriApp extends StatelessWidget {
  const NutriApp({super.key, required this.config});

  final EnvironmentConfig config;

  @override
  Widget build(BuildContext context) {
    final resolvedConfig = config.withDartDefineOverrides();
    final DietRepository dietRepository;
    final RoutineRepository routineRepository;
    if (resolvedConfig.useMockApi) {
      dietRepository = MockDietRepository();
      routineRepository = MockRoutineRepository(
        latency: resolvedConfig.mockLatency,
      );
    } else if (resolvedConfig.useLocalDatabase) {
      dietRepository = LocalDietRepository();
      routineRepository = LocalRoutineRepository();
    } else {
      dietRepository = HttpDietRepository(
        resolvedConfig.apiBaseUrl.isEmpty
            ? ApiConstants.baseUrl
            : resolvedConfig.apiBaseUrl,
        fallback: LocalDietRepository(),
      );
      routineRepository = HttpRoutineRepository(
        resolvedConfig.apiBaseUrl.isEmpty
            ? ApiConstants.baseUrl
            : resolvedConfig.apiBaseUrl,
        fallback: LocalRoutineRepository(),
      );
    }

    return MaterialApp(
      title: 'NutriExercise',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: HomePage(
        dietRepository: dietRepository,
        routineRepository: routineRepository,
      ),
    );
  }
}
