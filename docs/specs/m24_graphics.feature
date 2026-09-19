Feature: Advanced Graphics and Exercise Color Mapping

  As a user logging an exercise
  I want the body map to highlight exactly the muscles that exercise activates
  So that I can see primary and secondary activation instantly with smooth transitions

  Background:
    Given the Tamagotchi state is initialized
    And the InteractiveBodyMap is visible

  Scenario: Exercise selection maps to specific muscle groups
    When the user selects the exercise "Bench Press"
    Then the ExerciseMuscleMapper resolves primary regions to "chest"
    And the ExerciseMuscleMapper resolves secondary regions to "arms", "shoulders"
    And the mapped region ids exist in the muscle vectors registry

  Scenario: Targeted regions update with primary and secondary activation colors
    When the user selects the exercise "Bench Press"
    Then the Tamagotchi state sets a color override for region "chest" to primary Red
    And the Tamagotchi state sets color overrides for regions "arms", "shoulders" to secondary Orange
    And regions not targeted by the exercise keep their default muscle color

  Scenario: Clearing the selection removes all color overrides
    Given a color override is active for region "chest"
    When the user clears the exercise selection
    Then the Tamagotchi state contains no region color overrides
    And region "chest" renders with its default muscle color

  Scenario: Color overrides animate smoothly via TweenAnimationBuilder
    Given a color override changes region "chest" from its default color to Red
    When the InteractiveBodyMap rebuilds with the new overrides
    Then the region color transitions smoothly over the animation duration
    And the transition does not snap instantly to the final color

  Scenario: New selection replaces the previous overrides without residue
    Given region "chest" has a primary Red override from "Bench Press"
    When the user selects the exercise "Squat"
    Then the override for region "chest" is removed
    And the new targeted regions carry the new primary and secondary overrides
    And no stale overrides from "Bench Press" remain

  Scenario: Visual debugging and edge-case rendering
    Given the Tamagotchi state is in debug inspection mode
    When an unknown exercise name is resolved
    Then the mapper returns empty primary and secondary region lists
    And the InteractiveBodyMap renders every region with its default muscle color
    And an unknown region id in the overrides is ignored without throwing
