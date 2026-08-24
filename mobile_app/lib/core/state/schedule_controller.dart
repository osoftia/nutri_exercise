import 'package:flutter/foundation.dart';

import '../data/schedule_repository.dart';
import '../models/schedule_event.dart';

/// ChangeNotifier owning the calendar state: the visible month, the selected
/// date, and the derived daily agenda. Notifies listeners on every change so
/// the Schedule UI rebuilds dynamically.
class ScheduleController extends ChangeNotifier {
  ScheduleController({
    required ScheduleRepository repository,
    DateTime? initialMonth,
  }) : _repository = repository {
    final start = _startOfMonth(initialMonth ?? DateTime.now());
    _visibleMonth = start;
    _selectedDate = start;
  }

  final ScheduleRepository _repository;

  late DateTime _visibleMonth;
  late DateTime _selectedDate;
  List<ScheduleEvent> _events = const [];
  bool _isLoading = false;

  /// First day of the currently displayed month.
  DateTime get visibleMonth => _visibleMonth;

  DateTime get selectedDate => _selectedDate;

  bool get isLoading => _isLoading;

  /// Events falling on the selected date (drives the daily agenda).
  List<ScheduleEvent> get eventsForSelectedDate =>
      _events.where((e) => isSameDay(e.date, _selectedDate)).toList();

  /// Whether any event falls on [date] (drives day markers).
  bool hasEventsOn(DateTime date) =>
      _events.any((e) => isSameDay(e.date, date));

  /// Loads events from the repository and notifies.
  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    _events = await _repository.getEvents();
    _isLoading = false;
    notifyListeners();
  }

  /// Selects [date] (day precision) and notifies so the agenda updates.
  void selectDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  /// Moves the visible month forward and notifies.
  void nextMonth() {
    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    notifyListeners();
  }

  /// Moves the visible month backward and notifies.
  void previousMonth() {
    _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1, 1);
    notifyListeners();
  }

  static DateTime _startOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);
}