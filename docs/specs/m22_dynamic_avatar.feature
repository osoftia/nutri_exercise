Feature: Dynamic BMI Avatar & Nutrition Visualizer

  As a user
  I want my daily nutrition totals and body profile to be reflected on my
  Tamagotchi avatar
  So that I can see at a glance what I ate and how my body proportions change

  Background:
    Given the mobile app is running
    And a fresh tamagotchi state is active
    And the user has a saved profile

  Scenario: Daily nutrition totals are shown after saving a log
    Given the user saves a daily log "Ate a 650 kcal chicken bowl"
    And the AI parser returns "650" calories, "45" grams of protein and
      "18" grams of fat
    When the daily totals are rendered
    Then the UI displays a daily total of "650" kcal
    And the UI displays a daily total of "45" g of protein
    And the UI displays a daily total of "18" g of fat

  Scenario: The avatar scales its width from the profile height and weight
    Given the user profile has height "170" cm and weight "70" kg
    When the baseline avatar is rendered
    Then the avatar body width factor corresponds to the user's BMI
    And the base matrices are adjusted for a normal or slimmer body

  Scenario: A heavier profile renders a wider baseline avatar
    Given the user profile has height "170" cm and weight "95" kg
    When the baseline avatar is rendered
    Then the avatar body width factor is greater than for a "70" kg user
      of the same height

  Scenario: Eating makes the core region bloat and turn red
    Given the user saves a daily log totalling "650" kcal
    When the nutrition result is applied to the tamagotchi state
    Then the "Core" region temporarily turns red
    And the "Core" region expands beyond its settle size
    And after the animation settles the "Core" region is slightly larger
      than before, proportional to the calories consumed

  Scenario: Multiple meals accumulate the core expansion
    Given the user has already saved a log totalling "400" kcal
    When the user saves to reach a daily total of "1000" kcal
    Then the settled "Core" size after "1000" kcal is larger than the
      settled "Core" size after "400" kcal
