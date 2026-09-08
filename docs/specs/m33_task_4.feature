Feature: Split anatomy vector rendering

  As a user, I want Upper Arms, Forearms, Thighs and Calves as separate
  tappable and colorable regions, not unified limb blocks.

  Scenario: Each split region exists on both views
    Given the muscle vector registry
    Then upper_arms, forearms, thighs and calves each have front and back
    entries with distinct labels and non-empty paths

  Scenario: No unified limb blocks remain
    Given the muscle vector registry
    Then no region uses the exact ids "arms" or "legs"

  Scenario: Taps resolve to the split regions
    Given a tap inside a forearm-only area of the front view
    Then the hit region id is "forearms"

  Scenario: Taps hit the topmost painted region at seams
    Given a tap where the shoulder band overlaps the upper arm
    Then the hit region id is "shoulders"
