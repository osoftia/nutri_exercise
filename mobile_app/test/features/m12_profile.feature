Feature: User Profile Management

  As a user
  I want to view and edit my personal details on the Profile tab
  So that my name, age, weight, height and fitness goal are saved locally
  and reflected immediately in the app

  Background:
    Given the mobile app is running
    And the user is on the Profile tab

  Scenario: Viewing the profile shows the saved personal details
    Given the user has saved a profile with name "Jane Doe"
    When the Profile tab is shown
    Then the field "Name" shows "Jane Doe"
    And the field "Age" shows the saved value
    And the field "Weight" shows the saved value
    And the field "Height" shows the saved value
    And the field "Fitness Goal" shows "Muscle Gain"

  Scenario: Editing the profile details
    Given the Profile tab is shown
    When the user changes the "Name" to "Jane Doe"
    And the user changes the "Fitness Goal" to "Fat Loss"
    And the user saves the profile
    Then the Profile tab shows "Jane Doe"
    And the Profile tab shows "Fat Loss"

  Scenario: Weight and height accept numeric values
    Given the Profile tab is shown
    When the user sets "Weight" to "70"
    And the user sets "Height" to "175"
    And the user saves the profile
    Then the saved "Weight" is "70"
    And the saved "Height" is "175"

  Scenario: Profile details persist after leaving the Profile tab
    Given the user has saved a profile with name "Jane Doe"
    When the user leaves the Profile tab and returns
    Then the Profile tab still shows "Jane Doe"

  Scenario: Saving with an empty name is blocked
    Given the Profile tab is shown
    When the user clears the "Name" field and saves
    Then a validation message is shown
    And the profile is not changed

  Scenario: The profile form is rendered in the neumorphic style
    Given the Profile tab is shown
    Then the profile form is rendered inside a neumorphic container