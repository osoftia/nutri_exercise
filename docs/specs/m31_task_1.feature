Feature: Calendar visual repair

  As a user, I want the calendar popup to render cleanly on any screen size,
  without overflows or glitches.

  Scenario: The calendar renders on a narrow phone screen
    Given a 320px-wide screen
    When I open the calendar
    Then no layout overflow occurs and the day grid renders

  Scenario: The calendar renders on a large screen
    Given a wide/tall screen
    When I open the calendar
    Then the grid cells keep a sane height

  Scenario: Month navigation stays tidy
    Given the calendar is open
    When I navigate months
    Then the header label updates without overflow