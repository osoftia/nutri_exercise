Feature: Widget to image exporter

  As the app, I want to capture a RepaintBoundary as a PNG and save it to the
  temporary directory, so it can be shared.

  Scenario: The boundary is captured as PNG
    Given a rendered RepaintBoundary with a GlobalKey
    When I capture it
    Then PNG bytes are produced

  Scenario: The PNG is saved to the temporary directory
    Given PNG bytes
    When I save them to the temporary directory
    Then a file is created with those bytes

  Scenario: The exporter rejects a non-boundary key
    Given a key not attached to a RepaintBoundary
    When I capture it
    Then an error is thrown