Feature: Success forensic logging and safe diagnosis regeneration

  Scenario: Persist a successful clinical diagnosis exchange
    Given the clinical report service returns a valid diagnosis response
    When the user generates a diagnosis
    Then the raw request body, response body, request URL and timestamp are stored locally
    And the report is offered for offline viewing

  Scenario: Review successful responses from the Profile Pruebas section
    Given successful exchanges have been recorded locally
    When the user opens "Respuestas exitosas"
    Then the app lists each exchange with its local time, status, label and URL
    And each record expands to reveal the raw request and response bodies

  Scenario: Bind to the exact backend payload
    Given the service responds with "diagnosticReport" and "mealSuggestions"
    When the report is parsed
    Then the UI shows the exact report text and meal suggestions
    And no generic educational placeholder content is substituted when fields are absent

  Scenario: Confirm before overwriting a saved diagnosis
    Given a valid diagnosis is already saved locally
    When the user taps "Obtener diagnóstico"
    Then the app asks "¿Está seguro de que desea volver a generar el diagnóstico?"
    And the saved diagnosis is replaced only after the user confirms

  Scenario: Generate without confirmation when nothing is saved
    Given no diagnosis is saved locally
    When the user taps "Obtener diagnóstico"
    Then the app generates the report without a confirmation prompt
