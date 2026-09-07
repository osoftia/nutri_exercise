Feature: Weekly statistics panel

  As a user, I want to see the last 7 days of calories consumed vs burned,
  so that I can track my energy balance.

  Scenario: The panel shows the last seven days
    Given saved daily entries exist
    When I open the weekly statistics panel
    Then the seven most recent days are shown with consumed and burned
    calories

  Scenario: Missing days are zeroed
    Given only some days have entries
    When the weekly stats are computed
    Then days without entries show zero consumed and burned

  Scenario: The chart is animated
    Given the weekly panel is rendered
    Then consumed and burned bars animate to their values