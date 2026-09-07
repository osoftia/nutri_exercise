Feature: Visual anatomy and exercise colors

  As a user, I want the body map to show the finer arm/leg regions and to
  light up the correct muscles when I select an exercise.

  Scenario: The body map renders the split arm and leg regions
    Given the dashboard is rendered for a day with arm work
    Then the Upper Arms region is visible in the map legend

  Scenario: Selecting an exercise paints its muscle colors
    Given an exercise card is shown
    When I select the exercise
    Then the body map applies the exercise region color overrides
    (primary red, secondary orange)

  Scenario: Override colors take precedence over tier colors
    Given the body map state has color overrides for a region
    Then the painted color for that region is the override color