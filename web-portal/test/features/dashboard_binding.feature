@milestone_web_3 @dashboard @binding @loading @errors @feedback @material @angular @web
Feature: Dashboard — AI Routine Data Binding

  As an administrator
  I want the dashboard to load AI-generated routines from the interaction service and bind them to the Material UI
  So that I can review generated routines and provide written feedback in a single view

  Background:
    Given the administrator is on the dashboard route of the Web Portal
    And the portal is configured with the "Dark Anatomy" theme
    And the interaction service is available

  Scenario: Load AI-generated routines when the dashboard initializes
    Given the interaction service has recorded AI-generated routines
    When the dashboard page loads
    Then a loading spinner is shown while the request is in flight
    And each AI-generated routine is rendered as a Material card
    And the routines are sorted by creation date, newest first

  Scenario: Show a loading spinner during the initial fetch
    Given the interaction service responds after a delay
    When the dashboard page loads
    Then the loading spinner remains visible until the response arrives
    And no routine cards are rendered while the spinner is visible

  Scenario: Show an empty state when no routines have been generated
    Given the interaction service returns an empty list
    When the dashboard page loads
    Then an empty state message is displayed
    And no routine cards are rendered

  Scenario: Show an error state when the initial fetch fails
    Given the interaction service is unreachable
    When the dashboard page loads
    Then an error state with a "Retry" action is displayed
    And no routine cards are rendered

  Scenario: Retry reloads the routines after an error
    Given the dashboard shows the error state
    When the administrator clicks "Retry"
    Then the interaction service is queried again
    And the routine cards are rendered if the request now succeeds

  Scenario: Bind AI-generated routine details to the Material card
    Given at least one AI-generated routine is displayed
    Then the card shows the prompt the routine was generated from
    And the card shows the model that generated the routine
    And the card shows the routine status
    And the card shows the generated routine text

  Scenario: Submit written feedback for an AI-generated routine
    Given at least one AI-generated routine is displayed
    When the administrator types feedback in the feedback field
    And submits the feedback
    Then the feedback is saved via the interaction service
    And a success confirmation is displayed
    And the submitted feedback is shown on the card

  Scenario: Reject empty feedback
    Given the feedback field of a routine card is empty
    When the administrator submits the feedback
    Then the form is marked as invalid
    And the "Feedback required" validation message is shown
    And no feedback request is sent

  Scenario: Feedback submission failure preserves the entered text
    Given the interaction service returns a server error when saving feedback
    When the administrator submits written feedback
    Then an error message is displayed
    And the feedback field keeps the entered text so it can be retried

  Scenario: Edit previously saved feedback
    Given a routine card has saved feedback
    When the administrator opens its feedback form
    Then the feedback field is pre-filled with the saved feedback
    When the administrator replaces the text and submits
    Then the feedback is updated via the interaction service
    And the new text is shown on the card