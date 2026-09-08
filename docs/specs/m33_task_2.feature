Feature: Exercise slimming and eating bloat UI trigger

  As a user, I want every food log and completed exercise to update the home
  page avatar immediately with a smooth animation.

  Scenario: Food logs notify listeners
    Given the tamagotchi state
    When I log nutrition or a meal
    Then listeners are notified exactly once per log

  Scenario: Exercise logs notify listeners
    Given the tamagotchi state
    When I log a completed exercise
    Then listeners are notified and any bloat is cleared

  Scenario: Silent operations stay silent
    Given empty overrides and a settled core
    When I clear overrides or settle the core
    Then no redundant notification fires
