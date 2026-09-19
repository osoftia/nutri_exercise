Feature: Smart Autocomplete Logger & Profile Quick-Edit

  As a user
  I want my profile defaults to be sensible, my profile info visible next to my avatar,
  and my daily log input to suggest previous entries and cache exact matches
  So that I can log meals faster and avoid redundant AI calls

  Background:
    Given the mobile app is running
    And the user has not yet saved a profile

  Scenario: Profile defaults are set to 60 kg and 1.70 m
    When the user opens the profile form for the first time
    Then the weight field is pre-filled with "60"
    And the height field is pre-filled with "170"

  Scenario: A profile info card with an edit icon is displayed next to the avatar
    Given the user has saved a profile with weight "70" kg and height "175" cm
    When the user views the home page
    Then a profile info card is visible next to the avatar
    And the card displays "70 kg" and "175 cm"
    And the card has an edit (pencil) icon

  Scenario: Tapping the edit icon navigates to the profile page
    Given the profile info card is visible
    When the user taps the edit icon
    Then the app navigates to the profile page

  Scenario: The DailyLogSheet text input provides autocomplete suggestions
    Given the user has previously logged "Ate chicken and rice"
    And the user has previously logged "Ate salmon and quinoa"
    When the user opens the DailyLogSheet
    And the user types "Ate" in the text input
    Then the autocomplete dropdown shows "Ate chicken and rice"
    And the autocomplete dropdown shows "Ate salmon and quinoa"

  Scenario: Selecting an autocomplete suggestion fills the input
    Given the autocomplete dropdown shows "Ate chicken and rice"
    When the user taps "Ate chicken and rice"
    Then the text input is filled with "Ate chicken and rice"

  Scenario: Exact text match bypasses the backend and loads from cache
    Given the user has previously logged "Ate chicken and rice"
    And the backend parsed it as "650 kcal, 45g protein, 18g fat"
    When the user submits "Ate chicken and rice" in the DailyLogSheet
    Then the app does NOT call the backend AI parser
    And the app loads the cached parsed data "650 kcal, 45g protein, 18g fat"
    And the daily totals are updated with "650 kcal, 45g protein, 18g fat"

  Scenario: Non-exact text match calls the backend
    Given the user has previously logged "Ate chicken and rice"
    When the user submits "Ate chicken and vegetables" in the DailyLogSheet
    Then the app calls the backend AI parser
    And the backend returns the parsed data
    And the daily totals are updated with the parsed data

  Scenario: The cache stores both raw text and parsed JSON
    Given the user submits "Ate chicken and rice"
    And the backend parses it as "650 kcal, 45g protein, 18g fat"
    When the user queries the local database
    Then the database contains the raw text "Ate chicken and rice"
    And the database contains the parsed JSON "650 kcal, 45g protein, 18g fat"
