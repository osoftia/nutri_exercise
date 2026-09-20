Feature: Avatar, Nutrition Semantics, Grid & History Data
  As a NutriExercise user
  I want an organic shared avatar, meaningful stomach colours, a technical
  blueprint backdrop and correct history data
  So that both my Routines and Nutrition tabs look and behave like one polished product

  Background:
    Given the mobile app is running

  Scenario: Both tabs share the organic articulated silhouette
    Given the Routines tab is displayed
    Then the unified articulated body blueprint is rendered with soft curved sides
    When the user opens the Nutrition tab
    Then the same silhouette is rendered with the same torso curves and limb gaps

  Scenario: A healthy high-protein surplus turns the stomach green
    Given the day's food log is in caloric surplus
    And protein is at or above target and dominates the carb and fat deltas
    Then the abdomen segment status is "healthy"
    And the abdomen is painted with "#10B981"

  Scenario: A carb-led surplus does not turn the stomach green
    Given the day's food log is in caloric surplus
    And the carb or fat delta exceeds the protein delta
    Then the abdomen segment status is not "healthy"
    And the abdomen keeps its amber or red imbalance colour

  Scenario: The blueprint shows a technical grid
    Given the unified body blueprint is displayed
    Then a fine drafting grid is painted behind the figure
    And every fourth line is drawn as a brighter major line
    And a faint centre crosshair is drawn

  Scenario: The weekly summary uses the recorded burn
    Given a historical day recorded a burned-calorie value
    When the Weekly Stats view aggregates the last seven days
    Then the day's burned value is the recorded value
    And it is not recomputed from the flat per-exercise estimate

  Scenario: Confirming a workout marks the calendar
    Given a workout is confirmed on the Routines tab
    Then today's calendar entry stores the exercise names and burned calories
    And any nutrition already recorded for today is preserved
    And the calendar marks today as an active day

  Scenario: Reversing a workout clears the calendar burn
    Given a workout was confirmed today
    When the user unchecks the workout
    Then today's stored exercise names and burned calories are cleared
    And any nutrition already recorded for today is preserved
