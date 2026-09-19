@milestone_41 @nutrition @blueprint
Feature: Nutrition tab action button

  As a user
  I want a nutrition action button on the Nutrition tab
  So that I can open the daily nutrition summary and see the stomach segment
  update

  Scenario: The Nutrition tab shows the action button
    Given the Nutrition tab with a body-detail controller
    Then a "nutrition_action_button" is displayed

  Scenario: Tapping the action button opens the nutrition summary
    Given the Nutrition tab with a body-detail controller
    When I tap the "nutrition_action_button"
    Then the "body_food_sheet" is displayed

  Scenario: Adding a food from the summary bloats the stomach segment
    Given the Nutrition tab with a tamagotchi-backed controller
    When I add a food from the nutrition summary
    Then the abdomen scale increases
