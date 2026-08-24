@milestone_1 @environment @mock
Feature: Environment Switching between Mock and API

  As a developer
  I want to toggle the app between Mock, Local, and API data sources
  So that I can develop and demo without a backend while still testing real HTTP

  Background:
    Given the app is launched with the "dev" flavor which uses the mock API
    And the dashboard shows the Admin Dashboard with the settings menu in the AppBar

  Scenario: Toggle from Mock to API via the settings menu
    Given the app is running against the mock repositories with a 500ms artificial latency
    When I tap the settings icon in the AppBar
    And I select the "prod" flavor from the popup menu
    Then the routine repository is rebuilt as an HTTP-backed repository with fallback to the local database
    And the diet repository is rebuilt as an HTTP-backed repository with fallback to the local database
    And the dashboard reloads the routine from the newly selected repository

  Scenario: Switching flavors recreates the routine provider and reloads data
    When I switch from "dev" to "local" using the settings menu
    Then the RoutineProvider is recreated with the local SQLite repository
    And the routine list is reloaded from the local database
    And the currently selected day and muscle highlight are reset to defaults

  Scenario: Selecting the currently active flavor does nothing
    Given the app is running with the "dev" flavor
    When I select "dev" from the settings menu
    Then the existing repositories are left untouched
    And no reload of the dashboard data is triggered

  Scenario: Flavor configuration selects the correct repository stack
    Given the flavor matrix maps "dev" to useMockApi=true and useLocalDatabase=false
    And the flavor matrix maps "local" to useMockApi=false and useLocalDatabase=true
    And the flavor matrix maps "prod" to useMockApi=false and useLocalDatabase=false
    When the app resolves the configuration for each flavor
    Then "dev" uses the mock repositories
    And "local" uses the SQLite repositories
    And "prod" uses the HTTP repositories with a local database fallback

  Scenario: HTTP failure falls back to the local database
    Given the app is running in the "prod" flavor against an unreachable API
    When the routine repository request fails
    Then the routine data is served from the local SQLite database fallback
    And the dashboard still renders routine data