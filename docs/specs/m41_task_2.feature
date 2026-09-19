@milestone_41 @tamagotchi @blueprint
Feature: Tamagotchi-driven segment scaling on the blueprint

  As a user
  I want my muscle growth and stomach bloat to visibly scale the blueprint
  figure again

  Scenario Outline: Segment thickness follows the tamagotchi mass
    Given a tamagotchi with "<group>" mass of <mass>
    When the tamagotchi scale factors are computed
    Then the "<segment>" scale is "<scale>"
    Examples:
      | group | mass | segment    | scale |
      | chest | 0.5  | chest      | 1.0   |
      | chest | 1.0  | chest      | 1.25  |
      | arms  | 0.0  | leftForearm| 0.75  |
      | legs  | 1.0  | rightCalf  | 1.25  |

  Scenario: Stomach bloat scales the abdomen
    Given a tamagotchi with core fullness "0.8"
    When the tamagotchi scale factors are computed
    Then the "abdomen" scale is greater than "0.75"

  Scenario: Growing a muscle updates the diagram view model
    Given a blueprint controller backed by a fresh tamagotchi
    When the chest muscle grows
    Then the chest diagram scale increases
    And the controller notified its listeners

  Scenario: Changing the view model animates the figure
    Given a diagram showing chest scale "1.0"
    When the view model changes to chest scale "2.0"
    And the animation has not finished
    Then the painted chest scale is between "1.0" and "2.0"
