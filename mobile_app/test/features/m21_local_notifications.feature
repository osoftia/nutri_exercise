Feature: Daily Reminder Notification & Text Logger

  As a user
  I want a daily local notification asking me what I ate and trained, and a
  quick text field to record my daily summary
  So that I can log my day in seconds without navigating the whole app

  Background:
    Given the mobile app is running
    And the notification service is initialized
    And notification permissions are granted

  Scenario: A daily reminder is scheduled for 8:00 PM
    Given the user has not disabled reminders
    When the app is launched
    Then a daily local notification is scheduled for "20:00"
    And the notification body is "What did you eat and train today?"

  Scenario: The daily reminder repeats every day
    Given a daily reminder is scheduled
    Then the notification repeats at the same time every day

  Scenario: Scheduling the reminder is idempotent
    Given a daily reminder is already scheduled
    When the app is launched again
    Then only one daily reminder remains scheduled

  Scenario: Tapping the notification opens the daily log sheet
    Given the app is running in the background
    And a daily reminder notification has been delivered
    When the user taps the notification
    Then the app opens directly into the daily log input sheet

  Scenario: Tapping the notification on a cold start opens the log sheet
    Given the app is not running
    And a daily reminder notification has been delivered
    When the user taps the notification
    Then the app launches and opens directly into the daily log input sheet

  Scenario: Saving a daily summary persists it
    Given the daily log sheet is open
    When the user types "Ate chicken and rice, trained chest" and taps save
    Then the summary is saved for today
    And the sheet closes

  Scenario: An existing summary is shown when the sheet reopens
    Given today's summary is "Ate chicken and rice, trained chest"
    When the daily log sheet is opened
    Then the input is pre-filled with "Ate chicken and rice, trained chest"

  Scenario: An empty summary is not saved
    Given the daily log sheet is open
    When the user taps save without typing anything
    Then no summary is saved
    And the sheet stays open

  Scenario: A denied permission does not crash the app
    Given notification permissions are denied
    When the app is launched
    Then the app starts normally
    And no reminder is scheduled
