@milestone_37 @body_diagram @projection
Feature: Projection chips drive the blueprint through a forecaster

  As a user
  I want the Now / 1m / 3m / 6m chips to ask the local AI forecaster for a
  projected body
  So that the blueprint figure and its segment statuses reflect my projected
  body composition

  Background:
    Given the blueprint diagram is mounted on the Routines tab

  Scenario: The Now milestone shows the current body composition
    Given a projection forecaster that projects chest scale "1.0" for month 0
    When the user selects the "Now" chip
    Then the chest segment scale is "1.0"

  Scenario Outline: Selecting a projection chip re-renders the diagram
    Given a projection forecaster that projects chest scale "<scale>" for month <month>
    When the user selects the "<chip>" chip
    Then the chest segment scale is "<scale>"
    And the projected chest status is "<status>"
    Examples:
      | chip | month | scale | status   |
      | 1m   | 1     | 1.2   | balanced |
      | 6m   | 6     | 2.0   | critical |

  Scenario: The rule-based forecaster scales segments from the morph factors
    Given a muscle-gain 6 month projection with shoulder "1.0" and waist "0.4"
    When the rule-based forecaster is asked for the projection
    Then the chest scale is "1.3"
    And the abdomen scale is "0.94"

  Scenario: The rule-based forecaster damps imbalances as the months pass
    Given a right-thigh workout completing "2" of "12" sets
    When the rule-based forecaster projects month "0" and month "6"
    Then the month "0" status is "critical"
    And the month "6" status is "warning"

  Scenario: A forecaster failure keeps the last diagram without crashing
    Given a projection forecaster that always fails
    When the user selects the "6m" chip
    Then the diagram still renders the current body
