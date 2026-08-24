import 'package:flutter_test/flutter_test.dart';
import 'package:nutri_mobile_app/core/mocks/mock_schedule_repository.dart';
import 'package:nutri_mobile_app/core/models/schedule_event.dart';

void main() {
  group('MockScheduleRepository', () {
    late List<ScheduleEvent> events;

    setUp(() async {
      events = await MockScheduleRepository().getEvents();
    });

    test('returns seeded events across the reference month', () {
      expect(events, isNotEmpty);

      final day5 = events.where(
        (e) => isSameDay(e.date, DateTime(2026, 8, 5)),
      );
      expect(
        day5.map((e) => e.title),
        containsAll(['Leg Day Workout', 'High Protein Breakfast']),
      );

      final day12 = events.where(
        (e) => isSameDay(e.date, DateTime(2026, 8, 12)),
      );
      expect(day12.map((e) => e.title), contains('Pull Day Workout'));
    });

    test('has events on marked workout days but not on day 3', () {
      for (final day in const [5, 12, 19, 26]) {
        expect(
          events.any((e) => isSameDay(e.date, DateTime(2026, 8, day))),
          isTrue,
          reason: 'expected an event on Aug $day',
        );
      }

      expect(
        events.any((e) => isSameDay(e.date, DateTime(2026, 8, 3))),
        isFalse,
        reason: 'day 3 must have no events',
      );
    });

    test('every event has a title, time and type', () {
      for (final event in events) {
        expect(event.title, isNotEmpty);
        expect(event.time, isNotEmpty);
        expect(ScheduleEventType.values, contains(event.type));
      }
    });
  });
}