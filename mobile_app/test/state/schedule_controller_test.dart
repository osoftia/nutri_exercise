import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_schedule_repository.dart';
import 'package:nutri_mobile_app/core/state/schedule_controller.dart';

void main() {
  late ScheduleController controller;

  setUp(() {
    controller = ScheduleController(
      repository: MockScheduleRepository(),
      initialMonth: DateTime(2026, 8),
    );
  });

  group('ScheduleController', () {
    test('load populates events and starts on the reference month', () async {
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.load();

      expect(controller.visibleMonth, DateTime(2026, 8, 1));
      expect(controller.hasEventsOn(DateTime(2026, 8, 5)), isTrue);
      expect(controller.hasEventsOn(DateTime(2026, 8, 3)), isFalse);
      expect(notifications, greaterThan(0));
    });

    test('selectDate updates the agenda for that date and notifies', () async {
      await controller.load();

      controller.selectDate(DateTime(2026, 8, 5));
      expect(
        controller.eventsForSelectedDate.map((e) => e.title),
        containsAll(['Leg Day Workout', 'High Protein Breakfast']),
      );

      controller.selectDate(DateTime(2026, 8, 3));
      expect(controller.eventsForSelectedDate, isEmpty);
    });

    test('nextMonth and previousMonth shift the visible month', () async {
      await controller.load();

      controller.nextMonth();
      expect(controller.visibleMonth, DateTime(2026, 9, 1));

      controller.previousMonth();
      controller.previousMonth();
      expect(controller.visibleMonth, DateTime(2026, 7, 1));
    });
  });
}