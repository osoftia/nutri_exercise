Feature: Stomach bloat visual scale

  As a user, I want the central torso/stomach vector to expand and contract in
  real-time as I log food, so the bloat feedback is immediate and visible.

  Scenario: Core fullness drives the settled stomach scale
    Given the tamagotchi has zero core fullness
    When I log a meal
    Then the settled core scale grows above 1.0

  Scenario: Successive meals retrigger the bloat animation
    Given the avatar is already bloating from a first meal
    When I log a second meal
    Then the bloat animation restarts from zero with the larger scale

  Scenario: Core render scale is a pure function of bloat state
    Given a settled scale, a bloating flag and an animation value
    Then the render scale overshoots while bloating and settles otherwise
