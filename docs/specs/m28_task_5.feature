Feature: Share progress

  As a user, I want to share my avatar and streak as an image, so I can post
  it on social media.

  Scenario: A Share Progress button is available
    Given the Home dashboard is rendered
    Then a Share Progress button is shown

  Scenario: The hidden share card is mounted
    Given the Home dashboard is rendered
    Then a hidden SocialShareCard with the current streak is present

  Scenario: Tapping Share captures and shares the PNG
    Given the share card is mounted
    When I tap Share Progress
    Then the card is captured as a PNG
    And the OS share sheet is opened with the PNG file