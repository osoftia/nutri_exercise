Feature: Interactive daily meal reminders

  As the notification system, I want three daily meal reminders with dynamic
  meal action buttons, so that the user can quick-log a meal straight from the
  notification.

  Scenario: Three daily reminders are scheduled
    Given the notification service is initialized
    When I schedule the daily meal reminders
    Then breakfast (8 AM), lunch (1 PM) and dinner (7 PM) reminders are scheduled

  Scenario: Each reminder carries the dynamic meals as action buttons
    Given a meal repository with history
    When I schedule the daily meal reminders
    Then each reminder injects its 3 meals as notification actions

  Scenario: Defaults are used when no history exists
    Given no meal history
    When I schedule the daily meal reminders
    Then each reminder injects the default meals for its slot

  Scenario: Reminders are replaced rather than duplicated
    Given reminders were scheduled before
    When I schedule the daily meal reminders again
    Then the previous reminder ids are cancelled first