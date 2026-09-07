Feature: Home layout and history access

  As a user, I want the Quick Add action directly under the body map and a
  prominent History button, so I can log meals and review past entries easily.

  Scenario: Quick Add sits directly below the body map drawing
    Given the Home dashboard is rendered
    Then the Quick Add button is located immediately below the
    InteractiveBodyMap drawing

  Scenario: History is accessible from the main app bar
    Given the main app is rendered with a history repository
    Then the app bar shows a Calendar/History action
    When I tap it
    Then the calendar history editor opens

  Scenario: No repository hides the history action
    Given the app has no history repository
    Then the app bar does not show the history action