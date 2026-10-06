Feature: AI-assisted clinical nutrition report and offline suggested menus
  As a user managing health conditions
  I want a tailored educational report and meal suggestions
  So that I can review them later, including when offline

  Background:
    Given the user's active clinical conditions are stored locally
    And the user's food preferences are stored locally

  Scenario: Generate a report using active conditions and food preferences
    Given the user has active "Diabetes" and "High cholesterol" conditions
    And the user prefers vegetarian meals and dislikes mushrooms
    When the user taps "Obtener diagnóstico"
    Then the app sends each active condition and severity to the clinical report endpoint
    And the app includes the saved food preferences and current language
    And the app shows a loading state while the request is in progress
    And a valid report and suggested menus are saved to SQLite
    And the app shows a success message and offers to view the report

  Scenario: View a report and menus in the result sheet
    Given an AI report and suggested menus have been saved locally
    When the user opens the saved report
    Then the app shows the report summary and considerations
    And the app shows the suggested weekly menus and meals
    And the app explains that the content is educational and not medical advice

  Scenario: Reopen saved content offline
    Given the user has a previously saved AI report and menus
    And the device has no internet connection
    When the user opens the clinical conditions section
    Then the most recent report and menus are loaded from SQLite
    And the user can view them without making a network request

  Scenario: Fall back safely when the service is unavailable
    Given the user has a previously saved report
    And the clinical report endpoint is unavailable or returns malformed data
    When the user requests a new report
    Then the previous report remains available locally
    And the app reports that generation failed without discarding saved content

  Scenario: Prevent generation without active conditions
    Given the user has no active clinical conditions
    When the user views the clinical conditions section
    Then the generate action is disabled
    And the app explains that at least one condition must be selected
