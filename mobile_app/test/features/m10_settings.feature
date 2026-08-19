Feature: Settings & Notifications Module

  As a user
  I want to manage my saved database records and notification preferences
  So that I can keep my routines up to date and control when I am reminded

  Background:
    Given the mobile app is running
    And the user has at least one saved routine record in the database

  Scenario: Opening the settings screen shows saved records
    Given the database contains the saved records "Monday" and "Tuesday"
    When the user opens the Settings screen
    Then the saved routine records "Monday" and "Tuesday" are listed
    And each record shows its focus area

  Scenario: Viewing a saved routine record
    Given the Settings screen is open
    When the user taps the record "Monday"
    Then the details of the "Monday" routine are shown
    And the details include its exercises, sets and reps

  Scenario: Editing a saved routine record
    Given the Settings screen is open
    And the record "Monday" is displayed
    When the user edits the focus area of "Monday" to "Push day"
    And the user saves the changes
    Then the record "Monday" now shows the focus "Push day"
    And the change is persisted in the database

  Scenario: Deleting a saved routine record
    Given the Settings screen is open
    And the record "Tuesday" is displayed
    When the user deletes the record "Tuesday"
    Then the record "Tuesday" is removed from the list
    And the record is removed from the database

  Scenario: Exercise alerts are disabled by default
    Given the user has not changed any notification preference
    When the user opens the notification preferences section
    Then the "Exercise alerts" toggle is off

  Scenario: Enabling exercise alerts
    Given the notification preferences section is open
    When the user toggles "Exercise alerts" to on
    Then the "Exercise alerts" toggle is on
    And the preference is persisted

  Scenario: Enabling food alerts
    Given the notification preferences section is open
    When the user toggles "Food alerts" to on
    Then the "Food alerts" toggle is on
    And the preference is persisted

  Scenario: Enabling daily intake reminders
    Given the notification preferences section is open
    When the user toggles "Daily intake reminders" to on
    Then the "Daily intake reminders" toggle is on
    And the preference is persisted

  Scenario: Notification preferences persist across screen changes
    Given the user has enabled "Exercise alerts"
    And the user has enabled "Food alerts"
    When the user leaves the Settings screen and returns
    Then the "Exercise alerts" toggle is still on
    And the "Food alerts" toggle is still on