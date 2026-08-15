import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/environment_config.dart';
import 'core/providers/environment_provider.dart';
import 'core/providers/routine_provider.dart';
import 'core/providers/wizard_provider.dart';
import 'core/theme/app_theme.dart';
import 'ui/pages/home_page.dart';

class NutriApp extends StatelessWidget {
  const NutriApp({super.key, required this.config});

  final EnvironmentConfig config;

  @override
  Widget build(BuildContext context) {
    final resolvedConfig = config.withDartDefineOverrides();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => EnvironmentProvider(config: resolvedConfig),
        ),
        ListenableProxyProvider<EnvironmentProvider, RoutineProvider>(
          update: (_, env, __) =>
              RoutineProvider(env.routineRepository)..loadRoutine(),
        ),
        ListenableProxyProvider<EnvironmentProvider, RoutineWizardProvider>(
          update: (_, env, __) => RoutineWizardProvider(env.routineRepository),
        ),
      ],
      child: MaterialApp(
        title: 'NutriExercise',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: Consumer<EnvironmentProvider>(
          builder: (context, env, _) => HomePage(
            dietRepository: env.dietRepository,
            routineRepository: env.routineRepository,
          ),
        ),
      ),
    );
  }
}