Feature: Daily Log History
  As a mobile app user
  I want to retrieve my saved daily logs
  So that I can review my nutrition and workout history

  Scenario: Retrieve all saved logs
    Given the database contains 2 saved daily logs
    When the user requests the daily log history
    Then the response should return 200 OK
    And the response should contain 2 logs
    And each log should include calories, protein, carbs, fats, and muscle groups