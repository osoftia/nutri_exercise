@milestone_37 @body_diagram @domain
Feature: Body segment status reflects training and nutrition balance

  As a user
  I want every body segment of the blueprint diagram to be classified from my
  logged training volume and my calorie/macro balance
  So that the diagram can mark the segments that lag behind or that are
  overloaded without enough training to justify it

  Background:
    Given the pure segment balance calculator is available

  Scenario Outline: Segment status by imbalance score
    Given a body segment "<segment>"
    And a trained volume of <trained> and a target volume of <target>
    And a calorie balance of <kcal> kcal
    When the body diagram is computed
    Then the segment "<segment>" should be rendered as "<status>"

    Examples:
      | segment    | trained | target | kcal | status   |
      | rightThigh | 12      | 12     | 0    | balanced |
      | rightThigh | 8       | 12     | 0    | warning  |
      | rightThigh | 0       | 12     | 0    | critical |
      | chest      | 4       | 4      | 0    | balanced |
      | chest      | 3       | 4      | 0    | warning  |
      | leftCalf   | 3       | 4      | 0    | warning  |
      | abdomen    | 0       | 0      | 900  | critical |
      | abdomen    | 0       | 0      | 0    | noData   |
      | head       | 0       | 0      | 0    | noData   |

  Scenario Outline: Imbalance thresholds are inclusive at their upper bound
    Given a body segment "abdomen"
    And a calorie balance of <kcal> kcal
    When the body diagram is computed
    Then the segment "abdomen" should be rendered as "<status>"

    Examples:
      | kcal | status   |
      | 100  | balanced |
      | 112  | balanced |
      | 113  | warning  |
      | 150  | warning  |
      | 300  | warning  |
      | 301  | critical |
      | 1500 | critical |

  Scenario: Missing training produces a negative imbalance score
    Given a body segment "rightThigh"
    And a trained volume of 6 and a target volume of 12
    When the body diagram is computed
    Then the imbalance score should be negative
    And the segment "rightThigh" should be rendered as "critical"

  Scenario: A caloric surplus produces a positive imbalance score
    Given a body segment "abdomen"
    And a calorie balance of 900 kcal
    When the body diagram is computed
    Then the imbalance score should be positive
    And the imbalance score is clamped to the maximum "1.0"
