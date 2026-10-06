Feature: Local error forensics and user-friendly alerts
  As an app user and maintainer
  I want network and server errors handled gracefully and recorded locally
  So that users can continue using the app and maintainers can diagnose failures

  Scenario: Network failure displays a friendly floating alert and records details
    Given an API request fails because the network is unavailable
    When the error handler captures the exception
    Then a non-blocking Spanish floating alert says "En este momento no hay conexión, intente más tarde"
    And SQLite stores the technical message, network error code, timestamp, and stack trace

  Scenario: HTTP error is recorded with its exact status code
    Given an API responds with HTTP 404 Not Found
    When the response is handled
    Then the local error record contains code "404" and the technical status message
    And the user sees a friendly message without raw server details

  Scenario: Timeout and malformed response are classified
    Given an API request times out or returns malformed JSON
    When the failure is captured
    Then the record identifies the timeout or parse category
    And the record includes a timestamp and stack trace

  Scenario: Review recorded errors from Profile Testing
    Given technical errors have been recorded locally
    When the user taps "Errores registrados" in Profile Pruebas
    Then the app shows errors newest first with exact local date and time
    And each item displays its error code and technical message
    And the stack trace can be expanded for debugging

  Scenario: Empty error history is explained
    Given no errors have been recorded
    When the user opens the error history
    Then the app shows a clear empty-state message
