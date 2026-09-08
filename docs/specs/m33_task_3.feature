Feature: Muscle color overrides rendering fix

  As a user, I want the selected or logged exercise's muscles to paint in
  their override colors (red primary, orange secondary), not the tier colors.

  Scenario: The selected region uses its override color
    Given an exercise with a red chest override is selected
    Then the selection highlight is based on red, not the tier color

  Scenario: Unselected regions still fade but keep override hues
    Given overrides are active and another region is selected
    Then non-selected regions render faded override hues

  Scenario: Repaints trigger on collection content changes
    Given the active region set changes content
    Then the painter repaints even if the set instance is reused
