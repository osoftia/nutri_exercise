import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_config.dart';

void main() {
  runApp(
    NutriApp(
      config: const AppConfig(
        name: 'qa',
        useMocks: false,
        apiUrl: 'https://qa-api.example.com',
      ),
    ),
  );
}
