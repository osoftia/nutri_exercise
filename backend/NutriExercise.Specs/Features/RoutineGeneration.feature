Feature: Routine Generation with RAG
  As an AI fitness platform
  I want to generate exercise routines based on scientific documents
  So that users receive safe, accurate, and JSON-structured workouts

  Scenario: Generate a hypertrophy routine returning strict JSON
    Given the scientific database contains a document about "Hypertrophy and 10 weekly sets"
    And the LLM is configured to return strict JSON format
    When the user requests a routine for "ganar masa muscular"
    Then the augmented prompt must include the scientific context
    And the result must be a valid JSON containing a list of exercises
