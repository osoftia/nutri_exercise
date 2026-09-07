Feature: Top meals from history

  As the notification system, I want the most frequent meals for a meal slot,
  so that interactive reminders offer relevant quick-log actions.

  Scenario: No history falls back to defaults
    Given there are no saved meals for breakfast
    When I query the top meals for breakfast
    Then I get "Huevos con arepa", "Avena", "Frutas"

  Scenario: History yields the most frequent meals
    Given saved meal history contains repeated meals for lunch
    When I query the top meals for lunch
    Then I get the 3 most frequent meal names

  Scenario: Defaults are defined per meal slot
    Given the meal presets
    Then breakfast, lunch and dinner each have 3 default meals