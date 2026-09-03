import 'package:flutter/foundation.dart';

/// Actions that a tapped (or launch) notification can request from the UI.
enum NotificationAction { openDailyLog }

/// Holds a pending notification-triggered navigation request.
///
/// The shell listens to this notifier and opens the matching surface (e.g. the
/// daily log sheet) once a navigator is available, then [consume]s the action.
class NotificationNavigationController extends ChangeNotifier {
  NotificationAction? _pending;

  /// The action waiting to be handled, or `null` when nothing is pending.
  NotificationAction? get pending => _pending;

  /// Requests the daily log sheet to be shown.
  void requestDailyLog() {
    _pending = NotificationAction.openDailyLog;
    notifyListeners();
  }

  /// Clears the pending action after it has been handled.
  void consume() {
    if (_pending == null) return;
    _pending = null;
    notifyListeners();
  }
}
