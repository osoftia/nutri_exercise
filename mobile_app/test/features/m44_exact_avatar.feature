Feature: Exact Avatar Silhouette & Data Views
  As a NutriExercise user
  I want an exact, slim, organic avatar, meaningful stomach colours, a technical
  grid backdrop and correct history data
  So that both my Routines and Nutrition tabs look and behave like one polished product

  Background:
    Given the mobile app is running

  Scenario: The silhouette is slim and organic on both tabs
    Given the unified body blueprint is displayed
    Then its arms, forearms, thighs and calves are slimmer than half a chest width
    And the torso sides are smooth curved contours
    And the elbow and knee joints keep a clean articulated gap
    When the user opens the Nutrition tab
    Then the same silhouette is rendered

  Scenario: A healthy high-protein surplus turns the stomach green
    Given the day's food log is in caloric surplus
    And protein is at or above target and dominates the carb and fat deltas
    Then the abdomen segment status is "healthy"
    And the abdomen is painted with "#10B981"

  Scenario: A carb-led surplus does not turn the stomach green
    Given the day's food log is in caloric surplus
    And the carb or fat delta exceeds the protein delta
    Then the abdomen segment status is not "healthy"

  Scenario: The blueprint shows a technical grid on both tabs
    Given the Routines tab is displayed
    Then the drafting grid is painted behind the figure
    When the user opens the Nutrition tab
    Then the drafting grid is painted behind the figure

  Scenario: The weekly summary uses the recorded burn
    Given a historical day recorded a burned-calorie value
    When the Weekly Stats view aggregates the last seven days
    Then the day's burned value is the recorded value

  Scenario: Confirming a workout marks the calendar
    Given a workout is confirmed on the Routines tab
    Then today's calendar entry stores the exercise names and burned calories
    And any nutrition already recorded for today is preserved
