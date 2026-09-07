import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureLocalTimeZone();

  // Initialize the notification plugin up front so Android 13+ runtime
  // permissions (POST_NOTIFICATIONS + exact alarms) are requested before the
  // UI runs. NutriApp reuses this instance for scheduling and tap handling.
  final notificationService = NotificationService();
  try {
    await notificationService.initialize();
  } catch (_) {
    // Notifications are non-critical: never crash startup when the platform
    // channel is unavailable (e.g. in tests without a registered plugin).
  }

  runApp(
    NutriApp(
      config: const AppConfig(name: 'dev', useMocks: false),
      notificationService: notificationService,
    ),
  );
}