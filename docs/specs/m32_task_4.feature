Feature: Verification of the 9 PM exercise notification

  As the team, I want automated coverage of the scheduling and response logic,
  so regressions are caught.

  Scenario: The 9 PM schedule is covered
    Given the exercise reminder scheduler
    Then tests assert the 21:00 daily schedule, the Yes/Not-yet actions, and
    the cancel-before-reschedule behaviour

  Scenario: The response calculator is covered
    Given the exercise response handler
    Then tests assert burned-calorie math, the slimming calculation, the
    SQLite update, and the "Not yet" no-op

  Scenario: The project verifies cleanly
    When I run flutter analyze and flutter test
    Then there are no analysis issues and all tests pass