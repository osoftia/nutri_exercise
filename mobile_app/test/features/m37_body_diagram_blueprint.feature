@milestone_37 @body_diagram @blueprint
Feature: Blueprint body diagram with split limbs and annotation callouts

  As a user
  I want a schematic body diagram with tappable segments and blueprint callouts
  So that I can inspect any body part and its live training / nutrition values

  Background:
    Given a body diagram view model with a status for every segment

  Scenario: The diagram exposes all twelve body segments
    When the figure is laid out at "720x420"
    Then the figure has a path for each of the 12 segments
    And arms and legs each expose an upper and a lower segment

  Scenario Outline: Segment fill and stroke reflect the segment status
    Given the segment "<segment>" has status "<status>"
    When the diagram is painted
    Then the segment "<segment>" uses the stroke colour "<stroke>" and an 18% fill
    Examples:
      | segment    | status   | stroke  |
      | rightThigh | balanced | #3B82F6 |
      | rightThigh | warning  | #F59E0B |
      | rightThigh | critical | #EF4444 |
      | head       | noData   | #475569 |

  Scenario: Arms and legs are split with connected joints
    When the figure is laid out at "720x420"
    Then the "leftUpperArm" and "leftForearm" paths connect at the elbow
    And the "leftThigh" and "leftCalf" paths connect at the knee

  Scenario: The figure keeps its aspect ratio at any width
    Given the figure is laid out at "300x400" as layout "A"
    And the figure is laid out at "600x800" as layout "B"
    Then the aspect ratio of "A" and "B" is the same within 0.001

  Scenario Outline: Tapping a segment resolves its body segment
    Given the figure is laid out at "360x420"
    When I tap the centre of "<segment>"
    Then the hit test resolves to "<segment>"
    Examples:
      | segment      |
      | head         |
      | neck         |
      | chest        |
      | abdomen      |
      | leftUpperArm |
      | leftForearm  |
      | rightThigh   |
      | leftCalf     |

  Scenario: Callouts sit in the gutters without overlapping anything
    When the callouts are laid out at "720x420"
    Then every configured callout has a leader line to its segment anchor
    And no two callout chips overlap
    And no callout chip overlaps the figure

  Scenario: Tapping a callout opens the same detail callback as its segment
    Given the diagram has callouts and a selection callback
    When I tap the "abdomen" callout
    Then the selection callback receives "abdomen"
    And tapping the "abdomen" segment also receives "abdomen"

  Scenario: Callout chips are accessible
    Given the diagram has callouts and a selection callback
    When the callouts are laid out at "720x420"
    Then every callout exposes a semantic label and value
    And every callout tap target is at least 48 by 48
