Feature: Slimming effect from logging an exercise

  As a user in the gamified muscle loop,
  I want logging an exercise to slim the avatar's core/width,
  so that training counteracts the expansion caused by eating.

  Scenario: Logging an exercise reduces core fullness
    Given the tamagotchi has accumulated core fullness from eating
    When the user logs an exercise
    Then the core fullness decreases
    And the settled core scale (width) shrinks

  Scenario: Slimming clears any transient bloat
    Given the core is mid-bloat after eating
    When the user logs an exercise
    Then the bloat flag is cleared

  Scenario: Slimming never goes below zero
    Given a tamagotchi with zero core fullness
    When the user logs an exercise
    Then the core fullness stays at zero

  Scenario: The Home dashboard applies slimming when logging an exercise
    Given the dashboard is rendered
    When the user logs an exercise
    Then the tamagotchi slimming effect is applied