@milestone_41 @blueprint @geometry
Feature: Fluid anatomical joints on the blueprint figure

  As a user
  I do not want the schematic body to look like detached floating shapes

  Scenario: Arms and legs connect at the elbow and knee
    Given the figure is laid out at "720x420"
    Then the upper arm touches the forearm
    And the thigh touches the calf

  Scenario: The torso chain is connected
    Given the figure is laid out at "720x420"
    Then the neck touches the head
    And the chest touches the neck
    And the abdomen touches the thighs

  Scenario: The shoulders connect the arms to the chest
    Given the figure is laid out at "720x420"
    Then the upper arm overlaps the chest bounds

  Scenario: The blueprint silhouette is preserved
    Given the figure is laid out at "720x420"
    Then every segment still has a distinct path
    And the figure keeps its aspect ratio
