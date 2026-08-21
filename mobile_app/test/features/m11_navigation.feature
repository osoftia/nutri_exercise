Feature: Main Navigation, Mock Screens & Neumorphic Theming

  As a user
  I want a 4-tab bottom navigation shell with Montserrat typography and
  neumorphic styling, each tab showing basic mock content
  So that I can preview and navigate the core areas of the app
  (Routines, Nutrition, Schedule, Profile) before real data integration

  Background:
    Given the mobile app is running
    And the app theme uses the "Montserrat" font family
    And a neumorphic container style is applied to the bottom navigation bar

  Scenario: The bottom navigation shows the four main tabs
    Given the app shell is displayed
    Then the bottom navigation bar shows the tab "Routines"
    And the bottom navigation bar shows the tab "Nutrition"
    And the bottom navigation bar shows the tab "Schedule"
    And the bottom navigation bar shows the tab "Profile"

  Scenario: Navigating to the Routines tab
    Given the app shell is displayed
    When the user taps the "Routines" tab
    Then the Routines screen is shown
    And a list of mock routines is displayed

  Scenario: Navigating to the Nutrition tab
    Given the app shell is displayed
    When the user taps the "Nutrition" tab
    Then the Nutrition screen is shown
    And a mock nutrition plan is displayed

  Scenario: Navigating to the Schedule tab
    Given the app shell is displayed
    When the user taps the "Schedule" tab
    Then the Schedule screen is shown
    And a schedule calendar view is displayed

  Scenario: Navigating to the Profile tab
    Given the app shell is displayed
    When the user taps the "Profile" tab
    Then the Profile screen is shown
    And a static user profile is displayed

  Scenario: Each tab retains its mock content when revisited
    Given the user is on the "Nutrition" tab
    When the user navigates to the "Routines" tab
    And the user returns to the "Nutrition" tab
    Then the Nutrition screen is shown again
    And the mock nutrition plan is still displayed
