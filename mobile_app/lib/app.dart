import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
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

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final DietRepository dietRepository;
    final RoutineRepository routineRepository;
    if (config.useMocks) {
      dietRepository = MockDietRepository();
      routineRepository = MockRoutineRepository();
    } else if (config.useLocalDatabase) {
      dietRepository = LocalDietRepository();
      routineRepository = LocalRoutineRepository();
    } else {
      dietRepository = HttpDietRepository(
        ApiConstants.baseUrl,
        fallback: LocalDietRepository(),
      );
      routineRepository = HttpRoutineRepository(
        ApiConstants.baseUrl,
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
