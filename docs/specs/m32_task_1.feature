Feature: EXERCISE NOT test button

  As a user, I want a dedicated "EXERCISE NOT" button in the nutrition
  section, so I can trigger a test exercise notification payload instantly.

  Scenario: The button is shown in the notifications section
    Given a notification service is configured
    Then an "EXERCISE NOT" button is visible

  Scenario: Tapping the button triggers a test exercise notification
    Given the nutrition tab is shown
    When I tap "EXERCISE NOT"
    Then the test exercise notification is triggered