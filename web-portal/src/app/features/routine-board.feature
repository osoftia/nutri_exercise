Feature: Trello-style Exercise Routine Creator
  As a coach I want to drag exercises between muscle-group columns
  so that I can compose reusable routines quickly

  Scenario: Board loads with muscle-group columns
    Given the generic exercise catalog is available
    When the board initializes
    Then 3 columns are visible with exercises grouped by muscle

  Scenario: Reorder columns via cdkDropListGroup
    Given the board shows columns A B C
    When I drag column A after column C
    Then columns order becomes B C A and persists

  Scenario: Move card within same column
    Given column "Chest" has 3 cards
    When I drag card 0 to position 2
    Then the column order updates via moveItemInArray

  Scenario: Move card across columns
    Given card "Bench Press" in "Chest"
    When I drag it to "Triceps"
    Then it is removed from source and inserted in target via transferArrayItem

  Scenario: Inline editing of exercise name
    Given a card is in edit mode
    When I change name to "Incline Press" and blur
    Then the exercise name updates and persists to generic table

  Scenario: Bulk delete with checkboxes
    Given 2 cards are selected via checkboxes
    When I confirm bulk delete
    Then both cards are removed from board and catalog

  Scenario: Add custom exercise persists to generic table
    Given I fill name "Hip Thrust" muscleGroup "Glutes"
    When I submit add-custom-exercise
    Then the exercise appears in backlog and is stored for future reuse
