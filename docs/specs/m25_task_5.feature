Feature: Calendar history and editor

  As a user,
  I want to open a calendar that shows my daily logged nutrition and
  exercises stored in SQLite,
  so that I can review and edit past entries.

  Scenario: The calendar lists days that have logged data
    Given daily entries exist in SQLite
    When I open the calendar history popup
    Then the days with entries are marked
    And tapping a marked day shows its calories and exercises

  Scenario: A past entry can be edited and saved
    Given I open a day in the calendar editor
    When I update the calories and exercises and save
    Then the updated entry is persisted in SQLite

  Scenario: A past entry can be deleted
    Given I open an existing day in the calendar editor
    When I choose to delete it
    Then the entry is removed from SQLite