Feature: Long-Term Body Projection & SQLite Planning

  As a user
  I want a long-term body projection engine on the Routines tab
  So that I can see how my body is projected to change over 1, 3 and 6 months
  from a persisted 6-month plan stored in SQLite

  Background:
    Given the mobile app is running
    And the user is on the Routines tab
    And a 6-month projection plan is stored in SQLite

  Scenario: The projection timeline offers current, 1, 3 and 6 month milestones
    Given the Routines tab is shown
    Then a timeline selector is displayed
    And the timeline shows the milestones "Now", "1m", "3m" and "6m"

  Scenario: The current milestone shows the baseline body
    Given the Routines tab is shown
    When the timeline selects "Now"
    Then the projection avatar shows the baseline shoulder factor "0.5"
    And the projection avatar shows the baseline waist factor "0.5"

  Scenario: Selecting the 1 month milestone updates the projected body
    Given the Routines tab is shown
    When the user selects the milestone "1m"
    Then the projection avatar morphs to the 1 month projected body
    And the milestone summary shows the projected weight and phase

  Scenario: Selecting the 6 month milestone shows the greatest change
    Given the Routines tab is shown
    When the user selects the milestone "6m"
    Then the projection avatar morphs to the 6 month projected body
    And the milestone summary shows the 6 month projected weight

  Scenario: A muscle-gain plan broadens the shoulders over time
    Given the plan goal is "Muscle Gain"
    When the user selects the milestone "6m"
    Then the shoulder factor is greater than the baseline "0.5"
    And the shoulder factor is the largest of all milestones

  Scenario: A fat-loss plan slims the waist over time
    Given the plan goal is "Fat Loss"
    When the user selects the milestone "6m"
    Then the waist factor is less than the baseline "0.5"
    And the waist factor is the smallest of all milestones

  Scenario: The projection plan persists in SQLite
    Given a projection plan has been saved
    When the plan is reloaded from the repository
    Then the milestones "1", "3" and "6" are restored with their projected weight
