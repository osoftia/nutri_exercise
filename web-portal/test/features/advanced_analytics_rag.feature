@milestone_analytics @telemetry @ai-performance @rag @pgvector @analytics @angular @web
Feature: Advanced Analytics & RAG Inspector

  As an administrator
  I want a dedicated analytics workspace with mobile telemetry, AI performance, and vector database inspection
  So that I can monitor the Flutter app usage, the local Llama3 model, and debug the pgvector semantic search

  Background:
    Given the administrator is on the "/analytics" route of the Web Portal
    And the portal is configured with the "Dark Anatomy" theme
    And the analytics services are available

  # ---- Mobile Usage Metrics ----

  Scenario: Show active workout sessions
    Given the mobile app has reported telemetry
    When the analytics page loads
    Then the "Active Workout Sessions" metric is displayed
    And its value reflects the telemetry snapshot

  Scenario: Show the offline-first sync status
    Given the mobile app has pending offline items
    When the analytics page loads
    Then the sync status shows the number of pending items
    And the timestamp of the last successful sync is displayed

  Scenario: List recent mobile telemetry events
    Given telemetry events were recorded
    When the analytics page loads
    Then each telemetry event is rendered as a table row
    And the row shows the event type and its timestamp
    And the events are ordered newest first

  Scenario: Show an empty telemetry state
    Given no telemetry events were reported
    When the analytics page loads
    Then an empty state message is displayed
    And no telemetry rows are rendered

  # ---- AI Performance Analyzer ----

  Scenario: Show the average generation latency
    Given Llama3 has generated routines
    When the analytics page loads
    Then the average generation latency in milliseconds is displayed

  Scenario: Show the token throughput
    Given Llama3 has generated routines
    When the analytics page loads
    Then the token throughput in tokens per second is displayed

  Scenario: Chart the latency across recent generations
    Given latency samples were collected
    When the analytics page loads
    Then a bar chart renders one bar per generation sample

  Scenario: Show the RLHF feedback distribution
    Given interactions have been rated positive or negative
    When the analytics page loads
    Then the count of positive and negative ratings is shown
    And a chart shows the positive versus negative split

  # ---- Database & pgvector RAG Visualizer ----

  Scenario: List the database tables
    Given the PostgreSQL database is reachable
    When the RAG inspector loads
    Then every database table is listed with its row count

  Scenario: Inspect the rows of a table
    Given the administrator selects a table
    When the table rows are requested
    Then each row is rendered in a Material table
    And vector embedding columns show a preview of their values

  Scenario: Show the embedding metadata
    Given a table contains a pgvector embedding column
    Then the inspector shows the embedding dimension for that column

  Scenario: Run a semantic search over the embeddings
    Given the embeddings have been indexed
    When the administrator enters a query and requests a search
    Then the top matches are returned ordered by similarity
    And each match shows its similarity score

  Scenario: Show an error state when the database query fails
    Given the database is unreachable
    When the RAG inspector loads
    Then an error state with a "Retry" action is displayed
    And clicking "Retry" performs the query again