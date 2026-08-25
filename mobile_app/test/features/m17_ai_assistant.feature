Feature: Neumorphic AI Assistant & Tech Debt Cleanup

  As a user
  I want to reach an AI assistant from anywhere in the app via a neumorphic
  floating action button that opens a chat
  So that I can ask for a generated workout routine without leaving my tab

  Background:
    Given the mobile app is running
    And the user is on the main shell

  Scenario: The AI assistant is reachable from every tab
    Given the main shell is shown
    Then a neumorphic "Ask AI" floating action button is displayed

  Scenario: Tapping the button opens a neumorphic chat sheet
    Given the main shell is shown
    When the user taps the "Ask AI" button
    Then a neumorphic chat sheet opens
    And the chat sheet shows a text input field
    And the chat sheet shows a send button

  Scenario: Asking the AI while online shows the generated routine
    Given the device is online
    And the chat sheet is open
    When the user types "Push pull 4 days" and taps send
    Then the user's message "Push pull 4 days" appears in the chat
    And the assistant replies with a generated routine

  Scenario: Sending an empty message is ignored
    Given the chat sheet is open
    When the user taps send without typing anything
    Then no message is added to the chat
    And no AI request is made

  Scenario: Asking the AI while offline shows the offline dialog
    Given the device is offline
    And the chat sheet is open
    When the user types "Push pull 4 days" and taps send
    Then the Offline AI dialog is shown
    And no generated routine is shown

  Scenario: Closing the chat sheet does not leak the input controller
    Given the chat sheet is open
    When the user closes the chat sheet
    Then the chat sheet is dismissed
    And no disposed-controller exception is raised

  Scenario: Legacy tech debt is removed
    Given the app codebase
    Then the legacy dashboard "Ask AI" widget is removed
    And the infinite muscle-map glow animation is removed
