@rag @prompt-lab @pgvector @angular @web
Feature: RAG Prompt Lab

  As an administrator
  I want an interactive prompt laboratory to tune system prompts, temperature, and similarity thresholds
  So that I can iterate on RAG generation parameters and inspect latency metrics before deploying to the Flutter app

  Background:
    Given the administrator is on the "/rag-lab" route of the Web Portal
    And the portal is configured with the "Dark Anatomy" theme
    And the prompt lab services are available

  # ---- Default Values ----

  Scenario: Load the prompt lab with default parameter values
    When the prompt lab page loads
    Then the temperature slider displays a value of "0.7"
    And the similarity threshold slider displays a value of "0.8"
    And the system prompt textarea is empty
    And the query input is empty
    And no result panel is rendered

  # ---- Real-time System Prompt Binding ----

  Scenario: Bind the system prompt textarea reactively without pressing a button
    When the administrator types "You are a sports nutrition expert focused on dance recovery" into the system prompt textarea
    Then the reactive prompt state immediately contains "You are a sports nutrition expert focused on dance recovery"
    And no button press was required to update the state

  Scenario: Clear the system prompt textarea clears the reactive state
    Given the administrator has typed "You are a sports nutrition expert" into the system prompt textarea
    When the administrator clears the system prompt textarea
    Then the reactive prompt state is an empty string

  # ---- Executing a Test Query ----

  Scenario: Execute a test query and show a loading state
    Given the administrator has entered "Recovery routine after intense dance rehearsal" as the query
    When the administrator clicks the "Run Query" button
    Then the loading indicator is displayed
    And the "Run Query" button is disabled
    And the result panel is not yet rendered

  Scenario: Execute a test query and receive a mock response
    Given the administrator has entered "Recovery routine after intense dance rehearsal" as the query
    And the mock service is configured to respond after a delay
    When the administrator clicks the "Run Query" button
    And the mock response is delivered
    Then the loading indicator is hidden
    And the "Run Query" button is enabled again
    And the result panel is rendered

  # ---- Rendering the Mock Response with Latency Metrics ----

  Scenario: Render the mock answer text
    Given a test query has been executed and the mock response was delivered
    Then the result panel displays the answer text
    And the answer text contains recovery guidance content

  Scenario: Render matched sources from the mock response
    Given a test query has been executed and the mock response was delivered
    Then the result panel lists the matched sources
    And each matched source shows its title and similarity score
    And the matched sources are ordered by score descending

  Scenario: Display latency metrics after a test query
    Given a test query has been executed and the mock response was delivered
    Then the latency in milliseconds is displayed as a large metric number
    And the tokens per second value is displayed
    And the latency number uses the display-large typography scale

  # ---- Reset ----

  Scenario: Reset the prompt lab to default values
    Given the administrator has configured custom parameter values and executed a query
    When the administrator clicks the "Reset" button
    Then the temperature slider reverts to "0.7"
    And the similarity threshold slider reverts to "0.8"
    And the system prompt textarea is cleared
    And the query input is cleared
    And the result panel is removed