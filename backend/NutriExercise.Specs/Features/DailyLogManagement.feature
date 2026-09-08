Feature: Daily Log Management
  As a mobile app user
  I want to delete and filter my daily logs
  So that I can keep my history accurate and find entries by date

  Scenario: Delete an existing log
    Given a daily log with id "3fa85f64-5717-4562-b3fc-2c963f66afa6" exists
    When the user deletes that log
    Then the response should return 204 No Content

  Scenario: Delete a non-existent log
    Given no daily log with id "00000000-0000-0000-0000-000000000000" exists
    When the user deletes that log
    Then the response should return 404 Not Found

  Scenario: Logs are returned newest first by default
    Given the database contains a log created today
    And the database contains a log created yesterday
    When the user requests the daily log history
    Then the first log in the response should be the one created today

  Scenario: Logs are filtered by date range
    Given the database contains a log from "2026-09-01"
    And the database contains a log from "2026-09-05"
    When the user requests logs between "2026-09-01" and "2026-09-03"
    Then the response should contain only the log from "2026-09-01"