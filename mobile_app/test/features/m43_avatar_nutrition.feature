Feature: Avatar, Nutrition & Action Unification
  As a NutriExercise user
  I want portion-aware food logging, live nutrition colour semantics and a single
  shared body blueprint with standardized actions
  So that both my Routines and Nutrition tabs feel like one coherent product

  Background:
    Given the mobile app is running
    And the shared body blueprint is displayed on the active tab

  Scenario: Quick-add asks for the portion before logging
    Given the Nutrition tab shows the quick-add preset "Oatmeal & Berries"
    When the user taps the quick-add
    Then a centered gram dialog appears
    And the gram field defaults to "100 g"

  Scenario: A canceled quick-add logs nothing
    Given the quick-add gram dialog is open for "Oatmeal & Berries"
    When the user cancels the dialog
    Then no food is logged
    And the consumed calories are unchanged

  Scenario: A custom portion scales the entry proportionally
    Given the quick-add gram dialog is open for "Oatmeal & Berries"
    When the user enters "200" grams and confirms
    Then the logged calories are doubled
    And the logged protein, carbs and fat are doubled
    And the Tamagotchi stomach mass grows in proportion to the logged calories

  Scenario: Adding food colours the abdomen dynamically
    Given the shared body blueprint has no food data for today
    When the user logs a portion of food
    Then the abdomen segment's SegmentStatus moves out of "noData"
    And the abdomen is painted with the matching status colour

  Scenario: The nutrition summary aggregates every item
    Given foods have been logged on the Nutrition tab
    When the user opens the Daily Nutrition Summary
    Then the sticky totals show the summed calories
    And the sticky totals show the number of items
    And the sticky totals show the summed protein, carbs and fat

  Scenario: Both tabs share one articulated blueprint
    Given the Routines tab is displayed
    Then the unified articulated body blueprint is rendered
    When the user opens the Nutrition tab
    Then the same unified articulated body blueprint is rendered
    And the figure's limbs are split at the elbow and knee by a visible joint gap

  Scenario: Both tabs standardize the floating actions
    Given the Routines tab is displayed
    Then the History FAB sits beside the avatar
    And the Daily Routine Summary action sits beside the History FAB
    When the user opens the Nutrition tab
    Then the History FAB sits beside the avatar
    And the Daily Nutrition Summary action sits beside the History FAB
