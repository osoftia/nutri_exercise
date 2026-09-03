Feature: Daily Log Parsing
  As a mobile app user
  I want to submit a free-text log of my meals and workouts
  So that the AI extracts my consumed calories, macros, and exercised muscles into strict JSON

  Scenario: Extract macros and muscles from a natural language log
    Given the user submits the text: "Hoy comí pollo, 600 calorias, y entrené pecho"
    And the AI service is mocked to return a valid extraction JSON
    When the log parsing endpoint is called
    Then the response should contain 600 calories
    And the exercised muscles should include "Chest"
