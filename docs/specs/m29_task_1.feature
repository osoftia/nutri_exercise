Feature: Quick Add placement

  As a user, I want the Quick Add button exactly under the body map, so the
  next natural action after viewing my muscles is logging a meal.

  Scenario: Quick Add sits immediately below the body map
    Given the Home dashboard is rendered
    Then the Quick Add button is located directly below the InteractiveBodyMap
    And no other widget sits between them

  Scenario: Only one Quick Add button exists
    Given the Home dashboard is rendered
    Then there is exactly one Quick Add button