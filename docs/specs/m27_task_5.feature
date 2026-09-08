Feature: Reactive meal notifications

  As a user, I want immediate feedback after logging a meal, so I know whether
  to do my routine or how much of my burned calories I recovered.

  Scenario: No exercise logged today
    Given no exercises are logged today
    When a meal is logged
    Then a notification says "Remember to do your routine!"

  Scenario: Exercises logged today
    Given exercises are logged today
    When a meal is logged
    Then a notification says I recovered X of the Y calories burned

  Scenario: The UI exposes a test notifications toggle and button
    Given the nutrition tab is shown
    Then a Test Notifications button is available
    And a reactive-notifications toggle is shown