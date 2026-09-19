@milestone_41 @workout @toggle
Feature: Toggleable workout completion

  As a user
  I want to check and uncheck my workout completion
  So that the record and avatar update both ways

  Scenario: Checking the toggle records the workout
    Given a fresh tamagotchi and a recording repository
    When I toggle the workout on
    Then the repository saved the completed exercises
    And the tamagotchi chest mass grew

  Scenario: Unchecking the toggle reverses the record and the avatar
    Given a confirmed workout
    When I toggle the workout off
    Then the repository saved an empty completion list
    And the tamagotchi chest mass returned to baseline
    And the core fullness was restored

  Scenario: The routines tab shows a workout toggle
    Given the routines tab with a completion controller
    Then a "confirm_workout_toggle" is displayed
    And its value is false
