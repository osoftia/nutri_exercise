@milestone_38 @popups @nutrition
Feature: Interactive daily exercise and nutrition popup summaries

  As a user
  I want immediate summaries after confirming a workout and an itemized list of
  today's food with inline controls
  So that I can see my burn, recovery and intake update the avatar and blueprint

  Background:
    Given the app is running

  Scenario Outline: Confirming a workout summarises it and recovers muscles
    Given a completed workout "<exercise>" of <completed> of <planned> sets
    When the workout is confirmed
    Then the completion sheet shows "<exercise>"
    And the burned calories row reports "<burned>" kcal
    And the recovery status is "<recovery>"
    Examples:
      | exercise    | completed | planned | burned | recovery   |
      | Bench Press | 4         | 4       | 250    | recovered  |
      | Squat       | 2         | 4       | 250    | recovering |
      | Deadlift    | 0         | 3       | 0      | fatigued   |

  Scenario: Confirming a workout grows the targeted tamagotchi groups
    Given a fresh tamagotchi state
    And a completed "Bench Press" workout
    When the workout is confirmed
    Then the tamagotchi chest mass is greater than before
    And the completion sheet is displayed

  Scenario: The completion sheet has an empty state
    Given a workout with no completed exercises
    When the completion sheet is shown
    Then the completion sheet shows an empty state

  Scenario: Removing a food updates the sticky total and the avatar
    Given today has 3 logged foods
    When I remove the second food from the consumption list
    Then the consumption list has 2 items
    And the sticky total row shows the new sum
    And the tamagotchi core fullness decreases

  Scenario: Adding a food updates the sticky total
    Given today has 3 logged foods
    When I add a food from the consumption list
    Then the consumption list has 4 items
    And the sticky total row increases

  Scenario: Confirm workout action from a notification opens the sheet
    Given a pending "exerciseCompleted" notification action
    When the shell handles the pending action
    Then the completion sheet is displayed
