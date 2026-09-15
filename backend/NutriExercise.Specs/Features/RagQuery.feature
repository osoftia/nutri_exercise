Feature: RAG Query Endpoint
  As a developer
  I want a RAG query endpoint
  So that the Angular frontend can retrieve augmented AI answers with telemetry

  Scenario: Successful RAG query with valid parameters
    Given the RAG API is running
    When a POST request is sent to "/api/rag/query" with a valid payload
    Then the RAG response status should be 200 OK
    And the RAG response should contain "GeneratedText"
    And the RAG response should contain "RetrievedContexts"
    And the RAG response should contain "Telemetry"
    And the RAG telemetry should report a non-negative latency
