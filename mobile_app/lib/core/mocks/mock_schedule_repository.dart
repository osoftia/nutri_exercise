import '../data/schedule_repository.dart';
import '../models/schedule_event.dart';

/// In-memory test double seeded with events on fixed August 2026 dates so
/// calendar/agenda tests are deterministic.
class MockScheduleRepository implements ScheduleRepository {
  static final List<ScheduleEvent> _events = [
    ScheduleEvent(
      date: _aug(5),
      title: 'Leg Day Workout',
      time: '07:00',
      type: ScheduleEventType.workout,
    ),
    ScheduleEvent(
      date: _aug(5),
      title: 'High Protein Breakfast',
      time: '08:00',
      type: ScheduleEventType.meal,
    ),
    ScheduleEvent(
      date: _aug(12),
      title: 'Pull Day Workout',
      time: '07:00',
      type: ScheduleEventType.workout,
    ),
    ScheduleEvent(
      date: _aug(12),
      title: 'Grilled Salmon Lunch',
      time: '13:00',
      type: ScheduleEventType.meal,
    ),
    ScheduleEvent(
      date: _aug(19),
      title: 'Push Day Workout',
      time: '07:00',
      type: ScheduleEventType.workout,
    ),
    ScheduleEvent(
      date: _aug(26),
      title: 'Leg Day Workout',
      time: '07:00',
      type: ScheduleEventType.workout,
    ),
    ScheduleEvent(
      date: _aug(26),
      title: 'Post-workout Shake',
      time: '10:00',
      type: ScheduleEventType.meal,
    ),
  ];

  @override
  Future<List<ScheduleEvent>> getEvents() async => List.of(_events);

  static DateTime _aug(int day) => DateTime(2026, 8, day);
}