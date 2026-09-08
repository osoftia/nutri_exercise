Feature: Calendar and database sync

  As a user, I want the meals I log through Quick Add or the Daily Log action
  to be saved to SQLite for today, so the calendar immediately reflects them.

  Scenario: Quick Add persists today's entry
    Given the dashboard has a history repository
    When I tap Quick Add
    Then today's entry is stored with the added calories

  Scenario: The Daily Log action persists today's entry
    Given the dashboard has a history repository
    When I log a summary via the Daily Log action
    Then today's entry exists

  Scenario: The calendar marks the logged day
    Given today has a persisted entry
    When I open the calendar
    Then today's cell is marked as having an entry