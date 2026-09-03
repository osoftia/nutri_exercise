import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/state/notification_navigation_controller.dart';

void main() {
  group('NotificationNavigationController', () {
    test('starts with no pending action', () {
      final controller = NotificationNavigationController();

      expect(controller.pending, isNull);
    });

    test('requestDailyLog sets a pending openDailyLog action', () {
      final controller = NotificationNavigationController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.requestDailyLog();

      expect(controller.pending, NotificationAction.openDailyLog);
      expect(notifications, greaterThan(0));
    });

    test('consume clears the pending action', () {
      final controller = NotificationNavigationController();
      controller.requestDailyLog();

      controller.consume();

      expect(controller.pending, isNull);
    });
  });
}
