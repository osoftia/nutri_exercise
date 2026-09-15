Feature: Weekly Planner & Routine Duplication
  As a coach I want to plan routines across days of the week with body-zone tags
  so that athletes can repeat focused work (e.g. recovery) on training days

  Scenario: Tagging a routine with custom Body Zones
    Given a routine column "Recovery Flow" with no body zones
    When I add body zones "Legs" and "Core"
    Then the column shows badges "Legs" and "Core" and persists them

  Scenario: Assigning a routine column to a specific Day of the Week
    Given a routine column "Recovery Flow" assigned to "Monday"
    When I assign it to "Wednesday"
    Then the column appears in the Wednesday lane and no longer in Monday

  Scenario: Duplicating a specific routine across multiple days
    Given a recovery routine column assigned to "Monday" with 2 exercises
    When I duplicate it to "Monday", "Wednesday" and "Friday" dance rehearsal days
    Then 3 day-columns exist with the same exercises and body zones

  Scenario: Filtering the board by Day of the Week
    Given columns assigned to "Monday" and "Friday"
    When I select the "Friday" day filter
    Then only Friday columns are visible
