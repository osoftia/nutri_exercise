Feature: Schedule & Calendar View

  As a user
  I want an interactive neumorphic calendar with a daily agenda on the
  Schedule tab
  So that I can select a date and see the mock events scheduled for that day

  Background:
    Given the mobile app is running
    And the user is on the Schedule tab
    And the calendar is showing the reference month "August 2026"

  Scenario: The calendar shows the month with days and a weekday header
    Given the Schedule tab is shown
    Then the calendar shows the month "August 2026"
    And the calendar shows the weekday header "Mo" to "Su"
    And the calendar shows the day tiles from "1" to "31"

  Scenario: Selecting a date shows its events in the daily agenda
    Given the calendar is showing "August 2026"
    When the user selects the date "5"
    Then the daily agenda shows "Leg Day Workout"
    And the daily agenda shows "High Protein Breakfast"

  Scenario: Selecting a date with no events shows an empty agenda message
    Given the calendar is showing "August 2026"
    When the user selects the date "3"
    Then the daily agenda shows "No events scheduled"
    And no event titles are displayed

  Scenario: Selecting another date updates the agenda dynamically
    Given the calendar is showing "August 2026"
    When the user selects the date "12"
    Then the daily agenda shows "Pull Day Workout"
    And the agenda no longer shows "Leg Day Workout"

  Scenario: Days that have events are marked on the calendar
    Given the calendar is showing "August 2026"
    Then the day "5" is marked as having events
    And the day "12" is marked as having events

  Scenario: Navigating to the next month updates the calendar
    Given the calendar is showing "August 2026"
    When the user taps the next month control
    Then the calendar shows the month "September 2026"

  Scenario: Navigating to the previous month updates the calendar
    Given the calendar is showing "August 2026"
    When the user taps the previous month control
    Then the calendar shows the month "July 2026"

  Scenario: The calendar and agenda are rendered in the neumorphic style
    Given the Schedule tab is shown
    Then the calendar is rendered inside a neumorphic container
    And the daily agenda is rendered inside a neumorphic container