import '../models/schedule_event.dart';

/// Contract for reading scheduled events shown in the calendar agenda.
abstract interface class ScheduleRepository {
  /// Returns all known events (mock-seeded for M13).
  Future<List<ScheduleEvent>> getEvents();
}