@milestone_40 @notifications @workout
Feature: Structured exercise payload for the 9 PM check-in

  As a user
  I want the workout check-in notification to carry my planned exercises with
  sets, reps and load
  So that confirming from the notification produces the same completion data as
  the in-app manual check-in

  Background:
    Given the app is running

  Scenario: The structured payload round-trips through its codec
    Given a check-in with "Bench Press" of "4" sets, "8" reps at "60" kg
    When the check-in is encoded and parsed again
    Then the parsed check-in has "1" exercises
    And the parsed "Bench Press" has "4" planned sets and "60" kg

  Scenario Outline: Malformed payloads are rejected
    Given the raw payload "<raw>"
    When the check-in is parsed
    Then the parsed check-in is null
    Examples:
      | raw              |
      | not json         |
      | {"type":"other"} |
      | {"type":"exercise_check_in"} |
      |                  |

  Scenario: A names-only fallback builds one-set completions
    Given the exercise names "Squat" and "Bench Press"
    When the fallback check-in is built
    Then the fallback check-in has "2" exercises
    And every fallback exercise has "1" completed set

  Scenario: The handler persists structured completions from the payload
    Given the 9 PM exercise action is answered "Yes" with a structured payload
    Then the body-detail repository saved "3" completed sets for "Bench Press"
    And the burned calories are "250"

  Scenario: The handler falls back to exercise names without a payload
    Given the 9 PM exercise action is answered "Yes" without a payload
    Then the body-detail repository saved the completed exercise names

  Scenario: The reminder schedule carries the payload
    Given a structured check-in payload
    When the daily exercise reminder is scheduled
    Then the scheduler received the payload

  Scenario: The controller can build the reminder payload
    Given a blueprint overview with planned exercises
    When the check-in payload is built
    Then the payload parses back to the planned exercises

  Scenario: The navigation controller carries the exercise payload
    Given an exercise completion request with a payload
    Then the pending action is "exerciseCompleted"
    And the pending payload is preserved
