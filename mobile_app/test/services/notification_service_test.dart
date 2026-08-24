import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/services/notification_service.dart';

class _FakeNotificationsPlatform extends FlutterLocalNotificationsPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    FlutterLocalNotificationsPlatform.instance = _FakeNotificationsPlatform();
  });

  group('NotificationService', () {
    test('initialize is idempotent', () async {
      final service = NotificationService();

      await service.initialize();
      await service.initialize();
    });

    test('scheduleWeeklyRoutine completes without throwing', () async {
      final service = NotificationService();

      await service.scheduleWeeklyRoutine(1, 3);
    });
  });
}
