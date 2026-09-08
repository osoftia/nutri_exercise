Feature: Exercise response handler and calorie calculation

  As the app, I want the 9 PM alert response handled, so confirming a workout
  credits the burned calories and slims the tamagotchi.

  Scenario: Burned calories are calculated from today's exercises
    Given 2 exercises are logged today
    When the workout is confirmed
    Then the burned calories are 2 × 250

  Scenario: Confirming applies the slimming math to the tamagotchi
    Given the persisted core fullness is high
    When the workout is confirmed
    Then the stored core fullness decreases

  Scenario: The daily log records the burned calories
    Given the workout is confirmed
    Then today's SQLite entry stores the burned calories

  Scenario: "Not yet" does nothing
    Given the workout is not confirmed
    Then no progress or log changes happen