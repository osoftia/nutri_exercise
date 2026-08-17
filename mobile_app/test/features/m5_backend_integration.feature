@milestone_5 @backend @api @offline @ollama
Feature: Backend API Integration

  As a user
  I want the app to request routines from the C# .NET backend powered by RAG and Ollama
  So that I get AI-generated workouts while keeping offline-first resilience when the backend is unreachable

  Background:
    Given the app is launched in a flavor that uses the remote API
    And the API base URL points to the Mac's local network address (port 5039)
    And the Local SQLite repository is configured as the fallback

  Scenario: Successfully generating a routine via the API
    Given the backend and Ollama are reachable
    And I have completed the AI Routine Wizard with valid preferences
    When I tap "Generate"
    Then the app posts the wizard preferences to the /api/routine/generate endpoint
    And the response is parsed into the WorkoutDay model
    And the generated routine is saved to the local SQLite database
    And the Home Page refreshes to display the new routine
    And the result dialog shows the AI-generated description

  Scenario: Successfully loading the routine list via the API
    Given the backend is reachable
    When the Home Page requests the weekly routines
    Then the app calls the /api/routine endpoint
    And each returned routine is mapped to the WorkoutDay model
    And the dashboard renders the routines from the API response

  Scenario: Network drops during generation falls back to SQLite
    Given the backend is unreachable
    When I tap "Generate" after completing the wizard
    Then the API request fails
    And the app falls back to the local SQLite repository to generate a routine offline
    And the routine is generated from the local exercise library
    And the result dialog shows a notice that the routine was generated offline
    And the Home Page updates with the offline-generated routine

  Scenario: Network drops while loading routines falls back to SQLite
    Given the backend is unreachable
    When the Home Page requests the weekly routines
    Then the app falls back to the local SQLite database
    And the dashboard renders the previously saved routines
    And no error screen is shown

  Scenario: Backend request times out
    Given the backend takes longer than the configured request timeout to respond
    When I tap "Generate"
    Then the request is aborted after the timeout
    And the app falls back to the local SQLite repository
    And the user still receives a generated routine

  Scenario: Backend returns a 500 error when Ollama is unreachable
    Given the backend is reachable but Ollama is not running
    When I tap "Generate"
    Then the backend responds with a 500 status code
    And the app does not crash
    And the app falls back to the local SQLite repository
    And the user receives a locally generated routine instead

  Scenario: Backend returns a 400 error for invalid preferences
    Given the wizard preferences are empty or malformed
    When the app posts the preferences to the API
    Then the backend responds with a 400 status code
    And the app surfaces a friendly validation message
    And no routine is persisted

  Scenario: Backend returns an unexpected response body
    Given the backend responds with a 200 status but an unparseable body
    When the app parses the response
    Then the app treats the response as malformed
    And the app falls back to the local SQLite repository
    And the user still receives a generated routine

  Scenario: API routines persist locally for future offline use
    Given a routine was generated successfully through the API
    When I completely close and restart the application with no network access
    Then the Home Page loads the saved routine from SQLite
    And the generated routine is still displayed