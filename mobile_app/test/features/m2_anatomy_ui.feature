@milestone_2 @anatomy @ui @interaction
Feature: Bidirectional Body Map and Exercise Card Interaction

  As a user
  I want to select a muscle region on the body map and tap exercise cards
  So that I can visually understand which muscles each exercise targets

  Background:
    Given the app is launched with a routine loaded
    And the dashboard shows the Muscle Map and the Exercises sections
    And a workout day is selected

  Scenario: Tapping a muscle region highlights matching exercise cards
    Given the body map shows the front and back silhouettes with tappable regions
    When I tap the "Chest" region on the body map
    Then the "Chest" region is highlighted in the accent color with a glow
    And the exercise cards whose muscle group maps to "Chest" are visually highlighted
    And the legend row shows the active muscle regions

  Scenario: Tapping a muscle region highlights all matching exercises
    Given I tap the "arms" region on the body map
    Then both "Biceps" and "Triceps" exercise cards are highlighted
    And no other exercise cards are highlighted

  Scenario: Tapping an exercise card selects its muscle region on the body map
    Given the exercises list shows cards for the selected day
    When I tap an exercise card with muscle group "Legs"
    Then the body map highlights the "legs" region
    And the exercise card is shown as selected

  Scenario: Tapping the same muscle region again clears the selection
    Given the "Chest" region is currently selected on the body map
    When I tap the "Chest" region again
    Then the selection is cleared
    And no exercise cards remain highlighted

  Scenario: Selecting a different day resets the muscle selection
    Given the "Chest" region is selected on the body map
    When I tap another workout day in the Weekly Routines list
    Then the muscle region selection is cleared
    And the exercise list updates to show the new day's exercises

  Scenario: Active regions reflect the exercises of the selected day
    Given the selected day contains Chest, Shoulders, and Triceps exercises
    Then the body map marks the "chest", "shoulders", and "arms" regions as active in the primary color
    And the legend row lists "Chest", "Shoulders", and "Arms"
    And regions with no exercises remain neutral and non-highlighted

  Scenario: A day with no exercises shows the empty state
    Given the selected day has no exercises
    Then the Exercises section shows the message "Select a day to view exercises."
    And no muscle regions are marked as active