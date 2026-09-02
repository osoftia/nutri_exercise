@milestone_web_4 @rlhf @search @filter @datepicker @rxjs @angular @web
Feature: Advanced Search & Filtering — RLHF Dashboard

  As an administrator
  I want to search and filter the AI-generated routines by text and generation date
  So that I can quickly find specific interactions to review

  Background:
    Given the administrator is on the RLHF dashboard of the Web Portal
    And the portal is configured with the "Dark Anatomy" theme
    And the interaction service has recorded AI-generated routines

  Scenario: Search routines by text
    Given at least one routine contains the word "push"
    When the administrator types "push" in the search box
    And stops typing
    Then only routines matching "push" are displayed
    And the list header shows the number of matching routines

  Scenario: Search matches the prompt, the generated text, and the model
    Given routines whose prompt, generated text, or model contain the query
    When the administrator searches for a term
    Then every displayed routine contains the term in its prompt, generated text, or model

  Scenario: Rapid keystrokes are debounced into a single update
    When the administrator types "a", "ab", "abc" in quick succession
    Then the list is not updated while typing continues
    And the list updates once after typing pauses

  Scenario: Clearing the search restores the full list
    Given a text search is active
    When the administrator clears the search box
    Then all routines are displayed again

  Scenario: Filter routines by a date range
    Given routines were generated on different dates
    When the administrator selects a start date and an end date
    Then only routines generated within that range are displayed

  Scenario: Filter with only a start date
    When the administrator selects a start date only
    Then only routines generated on or after that date are displayed

  Scenario: Filter with only an end date
    When the administrator selects an end date only
    Then only routines generated on or before that date are displayed

  Scenario: Combine a text search with a date range
    When the administrator enters a text query and a date range
    Then only routines matching both conditions are displayed

  Scenario: Show an empty result state when nothing matches
    Given a search or filter combination matches no routine
    When the filters are applied
    Then a "no matching routines" message is displayed
    And no routine cards are rendered

  Scenario: Clear all filters
    Given one or more filters are active
    When the administrator clicks "Clear filters"
    Then all filters are reset
    And the full routine list is displayed