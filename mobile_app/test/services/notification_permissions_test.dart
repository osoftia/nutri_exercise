import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/services/notification_service.dart';

class _PermissionAndroidPlatform extends AndroidFlutterLocalNotificationsPlugin {
  int notificationsRequested = 0;
  int exactAlarmRequested = 0;

  @override
  Future<bool> initialize(
    AndroidInitializationSettings initializationSettings, {
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
        onDidReceiveBackgroundNotificationResponse,
  }) async {
    return true;
  }

  @override
  Future<bool?> requestNotificationsPermission() async {
    notificationsRequested++;
    return true;
  }

  @override
  Future<bool?> requestExactAlarmsPermission() async {
    exactAlarmRequested++;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('initialize requests the Android notification and exact alarm permissions',
      () async {
    final platform = _PermissionAndroidPlatform();
    FlutterLocalNotificationsPlatform.instance = platform;
    final service = NotificationService();

    await service.initialize();

    expect(platform.notificationsRequested, 1);
    expect(platform.exactAlarmRequested, 1);
  });

  test('initialize is idempotent and only requests permissions once', () async {
    final platform = _PermissionAndroidPlatform();
    FlutterLocalNotificationsPlatform.instance = platform;
    final service = NotificationService();

    await service.initialize();
    await service.initialize();

    expect(platform.notificationsRequested, 1);
    expect(platform.exactAlarmRequested, 1);
  });
}