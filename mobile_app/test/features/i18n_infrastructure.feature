Feature: Multi-Language Infrastructure
  As a NutriExercise user
  I want to choose my app language and have it persist
  So that the app always opens in the language I understand

  Background:
    Given the mobile app is running

  Scenario: The language domain ships English and Spanish
    Given the supported languages are enumerated
    Then "en" and "es" are available
    And an unknown code falls back to English

  Scenario: The chosen language is persisted
    Given the user selects Spanish in the Profile tab
    Then the selection is saved locally
    When the app restarts
    Then the app opens in Spanish

  Scenario: The dictionary covers navigation, headers, dialogs and quick-adds
    Given the active language is Spanish
    Then the navigation label for routines is "Rutinas"
    And the nutrition header is "Nutrición"
    And the quick-add title is "Añadir rápido"
    And the add-food dialog title is localized

  Scenario: Switching languages refreshes the UI instantly
    Given the Profile tab shows the language switcher
    When the user switches to Spanish
    Then the surrounding labels update to Spanish without a restart
    And the language switcher shows "Español" as selected
