Feature: Voice Input (Speech-to-Text) for the Wizard

  As a user completing the wizard
  I want to dictate my answers using my voice
  So that I can fill in the input fields faster and hands-free

  Background:
    Given the mobile app is running on a device with a microphone
    And the wizard input field "Training goal" is visible and focused

  Scenario: Requesting microphone permission on first use
    Given the user has never granted microphone access
    When the user taps the microphone icon in the wizard input field
    Then the app requests microphone permission from the operating system
    And the microphone icon changes to a pulsing "Listening..." state
    And the wizard input field shows a placeholder "Listening..."

  Scenario: Tapping the microphone icon starts listening and updates the UI
    Given the user has already granted microphone access
    When the user taps the microphone icon in the wizard input field
    Then the app starts listening for speech
    And the microphone icon animates with a pulsing glow
    And the text "Listening..." is displayed next to the microphone icon
    And the wizard input field is marked as read-only while listening

  Scenario: Converting speech to text and populating the input field
    Given the app is listening for speech
    When the user speaks "Increase my weekly training volume"
    Then the app converts the speech to text "Increase my weekly training volume"
    And the wizard input field is populated with "Increase my weekly training volume"
    And the app stops listening
    And the microphone icon returns to its idle state

  Scenario: Handling microphone permission denial
    Given the app has requested microphone permission
    And the user denies the permission
    Then the app does not start listening
    And the app displays an error message "Microphone permission is required to use voice input"
    And the microphone icon remains in its idle state
    And the wizard input field remains editable by keyboard

  Scenario: Handling unrecognized speech
    Given the app is listening for speech
    When the user speaks but no words are recognized
    Then the app stops listening
    And the app displays the message "Sorry, I did not understand that. Please try again."
    And the microphone icon returns to its idle state
    And the wizard input field keeps its previous value

  Scenario: Handling speech recognition errors
    Given the app is listening for speech
    When the speech recognition service returns an error
    Then the app stops listening
    And the app displays an error message "Voice input failed. Please try again."
    And the microphone icon returns to its idle state
    And the wizard input field keeps its previous value