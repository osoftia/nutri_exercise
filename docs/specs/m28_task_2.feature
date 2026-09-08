Feature: Streak calculator engine

  As the app, I want to compute the current workout/nutrition streak, so that
  the share card can display how many consecutive days I have been active.

  Scenario: No activity means a zero streak
    Given no days have activity
    Then the current streak is 0

  Scenario: Consecutive active days count the streak
    Given today and the two previous days have an exercise or healthy meal
    Then the current streak is 3

  Scenario: A gap resets the streak
    Given today has activity but two days ago the activity stops
    Then the current streak is 1

  Scenario: Only exercises or healthy meals count
    Given a day logged calories but no exercise or healthy meal
    Then that day does not extend the streak

  Scenario: An inactive today still counts yesterday onward
    Given today has no activity but yesterday and before are active
    Then the streak starts from yesterday