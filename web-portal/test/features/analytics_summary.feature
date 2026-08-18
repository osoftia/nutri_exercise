@milestone_web_6 @rlhf @analytics @summary @signals @angular @web
Feature: RLHF Analytics Summary

  As an administrator
  I want a statistics overview at the top of the RLHF dashboard
  So that I can quickly assess the model's performance and the RLHF progress

  Background:
    Given the administrator is on the RLHF dashboard of the Web Portal
    And the portal is configured with the "Dark Anatomy" theme
    And the interaction service has recorded AI-generated routines

  Scenario: Show the total number of generated routines
    Given the interaction service has recorded 5 AI-generated routines
    When the dashboard loads
    Then the analytics summary shows "5" for total routines generated

  Scenario: Show the total number of reviewed routines
    Given 3 of the routines have a rating
    When the dashboard loads
    Then the analytics summary shows "3" for total reviewed

  Scenario: Show the positive and negative percentages
    Given 2 routines are rated positive and 1 routine is rated negative
    When the dashboard loads
    Then the summary shows the percentage of positive ratings
    And the summary shows the percentage of negative ratings

  Scenario: Percentages are relative to reviewed routines only
    Given some routines have no rating yet
    When the dashboard loads
    Then unrated routines do not affect the positive and negative percentages

  Scenario: Percentages sum to 100 when at least one routine is reviewed
    Given at least one routine has a rating
    When the dashboard loads
    Then positive percent plus negative percent equals 100

  Scenario: Show zero percentages when nothing has been reviewed
    Given no routine has a rating
    When the dashboard loads
    Then the positive percentage is 0
    And the negative percentage is 0

  Scenario: The summary updates after a routine is rated
    Given a routine that has not been rated
    When the administrator rates that routine positive
    Then the reviewed count increases by one
    And the positive percentage reflects the new rating

  Scenario: Percentages are rounded to whole numbers
    Given a rating mix that yields a fractional percentage
    When the dashboard loads
    Then the displayed percentages are whole numbers