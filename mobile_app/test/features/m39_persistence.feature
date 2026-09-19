@milestone_39 @persistence @sqlite
Feature: Durable body-detail data and unified workout confirmation

  As a user
  I want my food log and workout completions stored on-device and shared between
  the notification action and the popup UI
  So that my Tamagotchi and blueprint reflect real, restart-safe data

  Background:
    Given the app is running

  Scenario: Added food persists across a repository restart
    Given a local body-detail repository for "2026-09-18"
    When I save a food log with "2" items
    And a new repository reads the same database
    Then the food log still has "2" items
    And the total calories are preserved

  Scenario: Removing a food persists
    Given a local body-detail repository for "2026-09-18"
    And a saved food log with "3" items
    When I save the food log without the first item
    Then the reloaded food log has "2" items

  Scenario: Completed exercises persist per day
    Given a local body-detail repository for "2026-09-18"
    When I save "2" completed exercises
    Then the reloaded completions have "2" entries
    And the completion of "Bench Press" is "4" of "4" sets

  Scenario: The persisted completions overlay the planned workout
    Given a planned "chest" workout of "4" sets
    And a saved completion of "3" completed sets
    When the chest workout log is loaded
    Then the completed sets are "3"
    And the planned sets are "4"

  Scenario Outline: The controller persists food mutations
    Given a recording body-detail repository
    When I add a "<name>" food
    Then the repository saved a food log containing "<name>"
    And the Tamagotchi core fullness increased
    Examples:
      | name          |
      | Protein Shake |
      | Banana        |

  Scenario: Confirming a workout persists the completions
    Given a completion controller with a repository
    When I confirm a "Bench Press" workout
    Then the repository saved the completed exercises
    And the completion summary reports "250" kcal

  Scenario: Presenting persisted completions does not persist twice
    Given a completion controller with a repository
    And saved completions for "Bench Press"
    When I present the saved completions
    Then the repository did not save again

  Scenario: The notification handler records completed exercises
    Given the 9 PM exercise action is answered "Yes"
    Then the body-detail repository saved the completed exercises
