Feature: Tamagotchi Interactive Avatar

  As a user
  I want a gamified "Tamagotchi-style" body avatar whose muscles grow, shrink
  and change colour based on my workout consistency
  So that I am motivated to train each muscle group regularly and can see at a
  glance which parts of my body are lagging behind

  Background:
    Given the mobile app is running
    And the user is viewing the avatar screen
    And the avatar is backed by a fresh tamagotchi state

  Scenario: The avatar renders the four tamagotchi muscle groups
    Given the avatar screen is shown
    Then the avatar shows the muscle groups "Core", "Arms", "Chest" and "Legs"
    And each muscle group has a mass value between "0.0" and "1.0"

  Scenario: A fresh avatar starts at a neutral baseline
    Given the tamagotchi state is fresh
    Then the mass of "Core", "Arms", "Chest" and "Legs" is "0.5"
    And every muscle group is rendered at its baseline size

  Scenario: Completing a routine grows the targeted muscle groups
    Given the tamagotchi state is fresh
    And the user completes a routine targeting "Chest"
    When the growth is applied
    Then the mass of "Chest" is greater than "0.5"
    And the mass of "Core", "Arms" and "Legs" is unchanged

  Scenario: Growth is clamped at the maximum mass
    Given the mass of "Chest" is "0.95"
    When the user completes a routine targeting "Chest"
    Then the mass of "Chest" is "1.0"

  Scenario: Muscle mass decays over time when inactive
    Given the mass of "Arms" is "0.8"
    And the user has not trained "Arms" for several days
    When the decay is applied for the elapsed inactive period
    Then the mass of "Arms" is less than "0.8"

  Scenario: Decay is clamped at the minimum mass
    Given the mass of "Legs" is "0.02"
    When the decay is applied
    Then the mass of "Legs" is "0.0"

  Scenario: Muscle size scales with its mass
    Given the mass of "Chest" is "0.8"
    And the mass of "Core" is "0.2"
    When the avatar is rendered
    Then the "Chest" region is rendered larger than the "Core" region

  Scenario: Muscle colour reflects its tier
    Given the mass of "Legs" is "0.1"
    And the mass of "Arms" is "0.5"
    And the mass of "Core" is "0.75"
    And the mass of "Chest" is "0.95"
    When the avatar is rendered
    Then the "Legs" region is coloured "Red"
    And the "Arms" region is coloured "Yellow"
    And the "Core" region is coloured "Green"
    And the "Chest" region is coloured "Gold"

  Scenario: The tamagotchi state persists across sessions
    Given the user has grown "Chest" to "0.9"
    When the avatar state is reloaded from storage
    Then the mass of "Chest" is restored to "0.9"
