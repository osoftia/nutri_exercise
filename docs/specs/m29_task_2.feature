Feature: Daily Log header action button

  As a user, I want a quick action next to the "Daily Log" section header,
  so I can open the quick logging sheet instantly.

  Scenario: The Daily Log section shows an action button
    Given the Home dashboard is rendered with a daily log controller
    Then a "Daily Log" section header is shown
    And an action button sits right next to it

  Scenario: Tapping the action button opens the quick logging sheet
    Given the Home dashboard is rendered
    When I tap the Daily Log action button
    Then the daily check-in sheet opens

  Scenario: No controller hides the section
    Given the Home dashboard has no daily log controller
    Then the Daily Log section is not shown