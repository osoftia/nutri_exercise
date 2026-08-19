/// The set of user-configurable notification preferences.
enum NotificationPrefType {
  exerciseAlerts('exercise_alerts', 'Exercise alerts'),
  foodAlerts('food_alerts', 'Food alerts'),
  dailyIntakeReminders('daily_intake_reminders', 'Daily intake reminders');

  const NotificationPrefType(this.key, this.label);

  /// Stable storage key used as the SQLite `pref_key`.
  final String key;

  /// User-facing label shown on the Settings screen.
  final String label;
}
