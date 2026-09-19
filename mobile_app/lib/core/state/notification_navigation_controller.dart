import 'package:flutter/foundation.dart';

/// Actions that a tapped (or launch) notification can request from the UI.
enum NotificationAction { openDailyLog, exerciseCompleted }

/// Holds a pending notification-triggered navigation request.
///
/// The shell listens to this notifier and opens the matching surface (e.g. the
/// daily log sheet) once a navigator is available, then [consume]s the action.
class NotificationNavigationController extends ChangeNotifier {
  NotificationAction? _pending;
  String? _exercisePayload;

  /// The action waiting to be handled, or `null` when nothing is pending.
  NotificationAction? get pending => _pending;

  /// The raw payload carried by a pending exercise check-in, if any.
  String? get exercisePayload => _exercisePayload;

  /// Requests the daily log sheet to be shown.
  void requestDailyLog() {
    _pending = NotificationAction.openDailyLog;
    notifyListeners();
  }

  /// Requests the post-workout completion summary to be shown.
  ///
  /// [payload] optionally carries the structured exercise check-in so the shell
  /// can present the exact completed sets/reps/load.
  void requestExerciseCompletion({String? payload}) {
    _pending = NotificationAction.exerciseCompleted;
    _exercisePayload = payload;
    notifyListeners();
  }

  /// Clears the pending action after it has been handled.
  void consume() {
    if (_pending == null && _exercisePayload == null) return;
    _pending = null;
    _exercisePayload = null;
    notifyListeners();
  }
}
