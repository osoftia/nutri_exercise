Feature: Split Arms and Legs into finer anatomical regions

  As a user exploring the muscle map,
  I want the arms split into Upper Arms and Forearms (antebrazos) and the
  legs split into Thighs and Calves (pantorrillas),
  so that the anatomy is more detailed and exercise activation is precise.

  Scenario: The body map registers the new regions
    Given the muscle vectors are built
    Then the map contains Upper Arms and Forearms regions
    And the map contains Thighs and Calves regions
    And the coarse Arms and Legs regions are removed

  Scenario: Exercise groups map onto the finer regions
    Given a triceps exercise
    Then it activates the Upper Arms region
    Given a leg exercise
    Then it activates the Thighs region

  Scenario: The tamagotchi groups cover the finer regions
    Given the tamagotchi group registry
    Then the arms group owns Upper Arms, Forearms and Shoulders
    And the legs group owns Thighs and Calves