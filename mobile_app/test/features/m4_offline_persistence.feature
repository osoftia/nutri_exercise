@milestone_4 @offline @sqlite @persistence
Feature: Offline Persistence with SQLite

  As a user
  I want my generated routines to be saved locally
  So that I can view my workout plan even if I close the app or lose internet

  Scenario: Saving a newly generated routine
    Given the environment is set to "Local SQLite"
    And I have completed the AI Routine Wizard
    When I tap "Generate"
    Then the routine should be saved to the local database
    And I should see the routine on the Home Page

  Scenario: Surviving an app restart
    Given I have a saved routine in the local database
    When I completely close and restart the application
    Then the Home Page should immediately load and display the saved routine