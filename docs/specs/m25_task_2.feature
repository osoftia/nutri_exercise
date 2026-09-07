Feature: Select and log an exercise

  As a user in the Routines/Exercises section,
  I want to select an exercise and mark it as logged for the day,
  so that my completed training is recorded.

  Scenario: Tapping an exercise selects its muscle region
    Given the dashboard shows exercises for the selected day
    When the user taps an exercise card
    Then the matching muscle region is highlighted on the body map

  Scenario: An exercise can be logged and unlogged
    Given the dashboard shows exercises for the selected day
    When the user taps the log control on an exercise
    Then the exercise is recorded as logged
    And tapping the log control again removes the log