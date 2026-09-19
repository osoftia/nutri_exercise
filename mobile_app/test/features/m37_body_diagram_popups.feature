@milestone_37 @body_diagram @popups
Feature: Body diagram detail popups for food and training gaps

  As a user
  I want to tap the blueprint diagram and inspect what I ate or how a muscle
  group is tracking against its plan
  So that I can close a nutrition or training gap without leaving the routine

  Background:
    Given the app is running and the user is on the Routines tab
    And the blueprint diagram is mounted on the Routines tab

  Scenario: Tapping the stomach callout opens the daily food list
    Given today has 3 logged foods
    When I tap the "STOMACH" callout
    Then a draggable bottom sheet with 3 food items is displayed
    And the total calories row shows the sum of the items

  Scenario: Adding a food from the popup updates the total
    Given today has 3 logged foods
    When I tap the "STOMACH" callout
    And I tap the "Add food" action
    Then the food list contains 4 items
    And the total calories row includes the added food

  Scenario: Tapping a muscle callout opens the exercise list with an AI suggestion
    Given "rightThigh" has 2 planned exercises
    When I tap the "rightThigh" callout
    Then a draggable bottom sheet with 2 exercise items is displayed
    And the completed versus planned row is displayed
    And the local AI suggestion to close the gap is displayed

  Scenario: The food popup has an empty state
    Given today has no logged foods
    When I tap the "STOMACH" callout
    Then the food sheet shows an empty state
    And the "Add food" action is still available

  Scenario: The exercise popup has an empty state
    Given "chest" has no planned exercises
    When I tap the "chest" callout
    Then the exercise sheet shows an empty state

  Scenario: Tapping a segment opens the same popup as its callout
    Given today has 3 logged foods
    When I tap the "abdomen" segment
    Then a draggable bottom sheet with 3 food items is displayed

  Scenario Outline: Segment statuses are assembled from logs and targets
    Given a food log totalling <kcal> kcal against a target of <target> kcal
    And a "<segment>" workout with <completed> of <planned> sets completed
    When the body diagram view model is assembled
    Then the "<segment>" status is "<status>"
    Examples:
      | segment    | kcal | target | completed | planned | status   |
      | rightThigh | 0    | 2000   | 12        | 12      | balanced |
      | rightThigh | 0    | 2000   | 6         | 12      | critical |
      | rightThigh | 0    | 2000   | 9         | 12      | warning  |
      | abdomen    | 2900 | 2000   | 0         | 0       | critical |
      | abdomen    | 0    | 2000   | 0         | 0       | noData   |
