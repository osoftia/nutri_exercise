Feature: Nutrition Dashboard, Neumorphic Stats & Dynamic Avatar

  As a user
  I want a nutrition dashboard with macro charts, a food intake logger and a
  dynamic human avatar on the Nutrition tab
  So that I can log food and immediately see calories, macronutrients and my
  body shape update

  Background:
    Given the mobile app is running
    And the user is on the Nutrition tab
    And the daily calorie target is "2000"
    And the user has consumed "1000" calories today

  Scenario: The dashboard shows consumed vs target calories
    When the Nutrition tab is shown
    Then the dashboard shows "1000" of "2000" kcal consumed

  Scenario: Macro rings show progress for protein, carbs and fat
    Given the Nutrition tab is shown
    Then a circular progress ring is shown for "Protein"
    And a circular progress ring is shown for "Carbs"
    And a circular progress ring is shown for "Fat"

  Scenario: The weekly bar chart shows seven days of statistics
    Given the Nutrition tab is shown
    Then a weekly bar chart is displayed
    And the bar chart shows "7" bars

  Scenario: Logging a quick meal increases consumed calories immediately
    Given the user has consumed "1000" calories today
    When the user taps the quick add "Grilled Chicken Bowl"
    And the meal adds "650" calories
    Then the dashboard shows "1650" kcal consumed
    And the consumed calories are persisted in the state

  Scenario: Logging food updates the protein macro ring
    Given the user has consumed "30" grams of protein
    When the user taps the quick add "Protein Shake"
    Then the protein progress increases
    And the dashboard reflects the new protein grams

  Scenario: The avatar morphs thinner when calories are below the target
    Given the user has consumed "1000" of "2000" calories
    When the Nutrition tab is shown
    Then the avatar morph factor is less than "0.5"

  Scenario: The avatar morphs wider when calories exceed the target
    Given the user has consumed "2200" of "2000" calories
    When the Nutrition tab is shown
    Then the avatar morph factor is greater than "0.5"

  Scenario: Logged food is reflected across charts and avatar
    Given the user has consumed "1000" of "2000" calories
    When the user logs a meal adding "650" calories
    Then the consumed calorie text increases
    And the avatar morph factor increases