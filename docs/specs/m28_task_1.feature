Feature: Social sharing dependencies

  As the app, I want the packages needed to export and share an image of my
  progress, so that social sharing is possible.

  Scenario: The share package is available
    Given the pubspec
    Then share_plus is declared as a dependency

  Scenario: The path provider is available
    Given the pubspec
    Then path_provider is declared as a dependency