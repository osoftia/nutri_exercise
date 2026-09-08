Feature: Social share card

  As a user, I want a polished vertical card with my avatar and streak, so it
  can be captured and shared as an Instagram story.

  Scenario: The card is a repaint boundary
    Given a share card is built
    Then it is wrapped in a RepaintBoundary with a GlobalKey

  Scenario: The card shows the body map
    Given the card is built with a tamagotchi state
    Then the InteractiveBodyMap is rendered inside the card

  Scenario: The card shows the streak count
    Given a streak of 5
    Then the card shows "🔥 5"

  Scenario: The card shows a motivational summary
    Given the card is built
    Then a motivational message is displayed