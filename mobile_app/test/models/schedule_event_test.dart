import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/models/schedule_event.dart';

void main() {
  group('ScheduleEvent model', () {
    test('constructs with all fields', () {
      final event = ScheduleEvent(
        date: DateTime(2026, 8, 5),
        title: 'Leg Day Workout',
        time: '07:00',
        type: ScheduleEventType.workout,
      );

      expect(event.date, DateTime(2026, 8, 5));
      expect(event.title, 'Leg Day Workout');
      expect(event.time, '07:00');
      expect(event.type, ScheduleEventType.workout);
    });

    test('isSameDay compares day precision', () {
      expect(
        isSameDay(DateTime(2026, 8, 5, 9, 30), DateTime(2026, 8, 5, 18, 0)),
        isTrue,
      );
      expect(
        isSameDay(DateTime(2026, 8, 5), DateTime(2026, 8, 6)),
        isFalse,
      );
    });
  });
}