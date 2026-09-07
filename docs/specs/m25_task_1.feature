Feature: Quick Add button below the body map

  As a user on the Home dashboard,
  I want the nutrition "Quick Add" button to sit immediately below the
  InteractiveBodyMap drawing,
  so that logging a quick meal is the next natural action after seeing my
  muscle map.

  Scenario: Quick Add is positioned right under the body map
    Given the Home dashboard is rendered
    Then the Quick Add button is located directly below the InteractiveBodyMap
    And tapping it logs a default quick meal and updates the daily totals

  Scenario: Quick Add logs nutrition into the tamagotchi
    Given the Home dashboard is rendered
    When the user taps Quick Add
    Then the daily calories increase
    And the muscle tamagotchi applies the nutrition (bloat)