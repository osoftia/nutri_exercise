Feature: OS permissions for notifications

  As the app, I want to request the correct OS permissions at startup,
  so that notifications and exact alarms work on Android 13+.

  Scenario: Android notification permission is requested
    Given the notification plugin is available
    When the service initializes
    Then POST_NOTIFICATIONS runtime permission is requested on Android 13+

  Scenario: Exact alarm permission is requested
    Given the notification plugin is available
    When the service initializes
    Then the exact alarm permission is requested on Android

  Scenario: The plugin is initialized from main
    Given the app starts
    Then the notification plugin is initialized before the UI runs

  Scenario: The manifest declares the required permissions
    Given the Android manifest
    Then POST_NOTIFICATIONS, SCHEDULE_EXACT_ALARM and RECEIVE_BOOT_COMPLETED
    are declared