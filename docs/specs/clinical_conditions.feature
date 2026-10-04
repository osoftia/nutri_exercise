Feature: Clinical food guidance
  Users can record conditions and see explainable food guidance using the
  nutrient details available to the app.

  Scenario: A high saturated-fat food is flagged for high cholesterol
    Given the user has selected high cholesterol
    And the selected condition severity is high
    And a food contains 8 grams of saturated fat per serving
    When the food is evaluated
    Then the verdict is a warning
    And the reason identifies saturated fat and high cholesterol
    And the food is presented with a red warning outline

  Scenario: A fiber-rich food is marked as supportive for high cholesterol
    Given the user has selected high cholesterol
    And a food contains 7 grams of fiber and 1 gram of saturated fat
    When the food is evaluated
    Then the verdict is beneficial
    And the reason explains the fiber-related support
    And the food is presented with a green support badge

  Scenario: A high-sugar high-glycemic food is flagged for diabetes
    Given the user has selected diabetes
    And a food contains 24 grams of sugar and has a glycemic index of 78
    When the food is evaluated
    Then the verdict is a warning
    And the reason identifies sugar or glycemic index

  Scenario: High purines are flagged for gout
    Given the user has selected gout
    And a food contains 220 milligrams of purines per serving
    When the food is evaluated
    Then the verdict is a warning
    And the reason identifies purines and gout

  Scenario: High sodium is flagged for hypertension
    Given the user has selected hypertension
    And a food contains 900 milligrams of sodium per serving
    When the food is evaluated
    Then the verdict is a warning
    And the reason identifies sodium and hypertension

  Scenario: Missing nutrient data is not presented as safe
    Given the user has selected diabetes
    And a food has no sugar, glycemic-index, or fiber details
    When the food is evaluated
    Then the verdict is unassessed
    And the explanation asks for more nutrition detail

  Scenario: Profile changes update food guidance immediately
    Given the user has no selected conditions
    And an oatmeal preset is visible in food search
    When the user selects the high cholesterol mock case
    Then the oatmeal verdict updates without reopening the Nutrition tab

  Scenario: A mock case is replaced by manual condition editing
    Given the high cholesterol mock case is active
    When the user changes a condition severity manually
    Then the selected patient case is cleared
    And the manually selected conditions remain active

  Scenario: Daily Symptoms remains a separate collapsed Profile section
    Given the Profile tab is open
    Then the Clinical Conditions accordion is visible and collapsed
    And the Daily Symptoms accordion is visible and collapsed
    When the user expands Clinical Conditions
    Then the condition controls and mock patient selector are shown
    And the Daily Symptoms section remains independently collapsible
