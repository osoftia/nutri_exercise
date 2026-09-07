Feature: Background notification response handling

  As the notification system, I want action buttons handled in a background
  isolate, so that a meal is logged and the tamagotchi math runs without the
  user opening the app.

  Scenario: Pressing a meal action logs the meal to SQLite
    Given a meal action button is pressed
    When the background handler runs
    Then the meal is persisted for today
    And the notification is cleared

  Scenario: The tamagotchi bloat math runs on the persisted progress
    Given the tamagotchi progress has a core fullness
    When a meal action is pressed
    Then the stored core fullness increases towards 1.0 (clamped)

  Scenario: Non-meal actions do not write meals
    Given a notification is tapped without an action id
    When the background handler runs
    Then no meal is persisted