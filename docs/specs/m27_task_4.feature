Feature: Diet gamification by food quality

  As the gamified nutrition system, I want healthy and unhealthy foods to
  behave differently on the tamagotchi avatar.

  Scenario: A healthy meal is classified
    Given a parsed meal with high protein and low fat
    Then the meal is healthy

  Scenario: An unhealthy meal is classified
    Given a parsed meal with low protein and high fat
    Then the meal is unhealthy

  Scenario: Healthy meals grow muscle vectors
    Given the tamagotchi at baseline
    When a healthy meal is applied
    Then arms, legs and chest mass increase

  Scenario: Unhealthy meals increase stomach bloat
    Given the tamagotchi at baseline
    When an unhealthy meal is applied
    Then the core fullness (stomach bloat) increases