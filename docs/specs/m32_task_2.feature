Feature: 9 PM exercise notification schedule

  As the app, I want a daily notification at 9:00 PM asking if I completed my
  workout routines, so I can confirm and get credit.

  Scenario: The reminder is scheduled at 21:00 daily
    Given the notification service is initialized
    When I schedule the exercise reminder
    Then a daily 21:00 reminder is scheduled

  Scenario: The reminder carries Yes / Not-yet actions
    Given the exercise reminder is scheduled
    Then it includes Yes and Not-yet action buttons

  Scenario: Rescheduling replaces the previous reminder
    Given the reminder was scheduled before
    When I schedule it again
    Then the previous id is cancelled first