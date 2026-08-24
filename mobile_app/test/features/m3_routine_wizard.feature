@milestone_3 @wizard @routine @generation
Feature: AI Routine Wizard

  As a user
  I want to answer a multi-step questionnaire and generate a routine
  So that I receive a personalized workout plan matching my goals

  Background:
    Given the app is launched with the mock API enabled
    And I open the wizard via the "Ask AI" or floating action button
    Then the wizard starts on the Age step with a stepper showing 4 steps

  Scenario: Completing all steps leads to the confirmation step
    Given I am on the Age step
    When I enter an age of 28
    And I press Next
    Then I am on the Goal step
    When I select "Build Muscle"
    And I press Next
    Then I am on the Fitness Level step
    When I select "Intermediate"
    And I press Next
    Then I am on the Days step
    When I select 4 days per week
    And I press Next
    Then I reach the confirmation step
    And the preview shows "Age: 28, Goal: build_muscle, Level: intermediate, Days: 4"

  Scenario: The wizard blocks advancing until each step is valid
    Given I am on the Age step
    When I leave the age empty
    Then the Next button is disabled
    When I enter an age below 14
    Then the Next button is disabled
    When I enter an age of 28
    Then the Next button is enabled

  Scenario: The wizard validates the number of training days
    Given I am on the Days step
    When I select 1 day per week
    Then the Next button is disabled
    When I select 2 days per week
    Then the Next button is enabled
    When I select 7 days per week
    Then the Next button is disabled

  Scenario: The user can navigate back and edit earlier answers
    Given I have reached the Days step
    When I press the back button
    Then I return to the Fitness Level step
    And my previously selected "Intermediate" level is preserved
    When I press the back button to the Goal step
    And I select "Lose Weight" instead
    Then the confirmation preview reflects "Goal: lose_weight"

  Scenario: Backing out of the first step asks to discard progress
    Given I am on the Age step
    When I press the back button
    Then a dialog asks whether to discard the wizard progress
    When I confirm "Discard"
    Then the wizard closes and all answers are cleared

  Scenario: Generating a routine shows the loading state
    Given I have completed all four steps and reached the confirmation step
    When I press "Generate Routine"
    Then the GeneratingOverlay is shown with a shimmer and progress indicator
    And the navigation bar is hidden
    And the text "Generating your routine..." is displayed

  Scenario: A successful generation shows the result dialog
    Given the generation completes successfully
    Then the generated routine summary dialog appears
    And the dialog shows the mock-generated routine text

  Scenario: Applying the generated routine refreshes the dashboard
    Given the generated routine dialog is open
    When I press "Apply to Dashboard"
    Then the wizard closes
    And the dashboard reloads its routine list
    And the wizard state is reset for the next run
    And a snackbar confirms "Routine saved to your dashboard."

  Scenario: A generation failure shows the error state
    Given the routine repository throws an error during generation
    When generation completes with a failure
    Then the error card is shown with the message "Generation Failed"
    And a "Try Again" button restarts the generation
    And a "Go Back" button returns to the wizard