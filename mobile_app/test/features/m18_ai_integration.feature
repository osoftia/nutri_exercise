Feature: AI Backend Integration

  As a user
  I want the AI chat to reach a real local Ollama model through the C# .NET API
  So that my workout questions are answered by the assistant instead of a mock

  Background:
    Given the mobile app is running
    And the device is online
    And the C# .NET API is reachable at the configured base URL

  Scenario: A successful Ollama response is rendered as an assistant message
    Given the chat sheet is open
    When the user types "Push pull 4 days" and taps send
    Then the chat shows a loading indicator
    And the chat sends a "POST /api/ai/chat" request with message "Push pull 4 days"
    And the API returns a successful response with the assistant's reply
    Then the chat shows the assistant's reply as an assistant message
    And the loading indicator is dismissed

  Scenario: The request carries the conversation history
    Given the chat sheet is open
    And the user already asked "Push pull 4 days" and the assistant replied
    When the user types "Add a leg day" and taps send
    Then the "POST /api/ai/chat" request body includes the previous user and assistant messages

  Scenario: A network timeout shows a graceful error and resets loading
    Given the chat sheet is open
    And the API delays its response beyond the chat timeout
    When the user types "Push pull 4 days" and taps send
    Then the chat shows a loading indicator
    And the chat eventually shows an error message "The assistant is taking too long. Please try again."
    And the loading indicator is dismissed
    And the user's message remains visible in the chat

  Scenario: A non-success HTTP status shows a graceful error
    Given the chat sheet is open
    And the API returns a 500 status for the chat request
    When the user types "Push pull 4 days" and taps send
    Then the chat shows an error message "The assistant is unavailable right now."
    And the loading indicator is dismissed

  Scenario: A malformed response body shows a graceful error
    Given the chat sheet is open
    And the API returns an invalid JSON body
    When the user types "Push pull 4 days" and taps send
    Then the chat shows an error message "The assistant is unavailable right now."
    And the loading indicator is dismissed

  Scenario: Sending while a request is in flight is ignored
    Given the chat sheet is open
    And a request is already in flight
    When the user types another message and taps send
    Then no additional AI request is made
    And the chat still shows a single loading indicator
