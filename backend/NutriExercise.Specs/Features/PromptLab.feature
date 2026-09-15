Feature: Prompt Lab Calibration Endpoint
  As a developer
  I want an endpoint to test and calibrate AI responses
  So that I can find the best Temperature, Similarity Threshold, and System Prompts before releasing features to users

  Scenario: Successful AI generation with valid parameters
    Given the Prompt Lab API is running
    When a POST request is sent to "/api/PromptLab/run-query" with valid payload (Temp: 0.7, Threshold: 0.8)
    Then the response status should be 200 OK
    And the response should contain the "GeneratedResponse"
    And the response should contain the "RetrievedContextCount"
    And the vector search and AI model services must be called exactly once

  Scenario Outline: Validation of boundaries and missing data
    Given the Prompt Lab API is running
    When a POST request is sent to "/api/PromptLab/run-query" with <Temperature>, <Threshold>, <SystemPrompt>, and <TestQuery>
    Then the response status should be 400 Bad Request
    And the response should contain the error message <ErrorMessage>

    Examples:
      | Temperature | Threshold | SystemPrompt | TestQuery | ErrorMessage                                         |
      | -0.1        | 0.8       | "Prompt"     | "Query"   | "Temperature must be between 0.0 and 1.0."           |
      | 1.1         | 0.8       | "Prompt"     | "Query"   | "Temperature must be between 0.0 and 1.0."           |
      | 0.7         | -0.1      | "Prompt"     | "Query"   | "SimilarityThreshold must be between 0.0 and 1.0."   |
      | 0.7         | 1.1       | "Prompt"     | "Query"   | "SimilarityThreshold must be between 0.0 and 1.0."   |
      | 0.7         | 0.8       | ""           | "Query"   | "SystemPrompt is required."                          |
      | 0.7         | 0.8       | "Prompt"     | ""        | "TestQuery is required."                             |
