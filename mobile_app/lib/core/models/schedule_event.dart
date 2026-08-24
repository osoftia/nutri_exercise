/// Categories of scheduled events shown in the daily agenda.
enum ScheduleEventType { workout, meal, rest }

/// A single scheduled event tied to a day in the calendar.
class ScheduleEvent {
  const ScheduleEvent({
    required this.date,
    required this.title,
    required this.time,
    required this.type,
  });

  final DateTime date;
  final String title;

  /// Display label for the event time, e.g. '07:00'.
  final String time;
  final ScheduleEventType type;
}

/// Whether [a] and [b] fall on the same calendar day.
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;