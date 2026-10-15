Feature: Health data synchronization
  As the NutriExercise backend
  I want to receive health metrics collected from Apple HealthKit and Google Fit
  So that mobile readings are stored exactly once even when the app retries the sync

  Scenario: Saving new health metrics
    Given the health sync API is running with an empty store
    When the mobile app syncs the following metrics:
      | metricType      | value | unit  | timestamp                 |
      | steps           | 8500  | count | 2026-10-01T08:00:00+00:00 |
      | calories_burned | 320.5 | kcal  | 2026-10-01T08:00:00+00:00 |
      | sleep_duration  | 7.5   | hours | 2026-10-01T07:00:00+00:00 |
    Then the sync response should report 3 received, 3 inserted and 0 updated
    And the store should contain 3 health metrics

  Scenario: Ignoring a duplicate metric when the mobile app retries
    Given the health sync API is running with an empty store
    And the mobile app has already synced "steps" with value 8500 at "2026-10-01T08:00:00+00:00"
    When the mobile app retries syncing "steps" with value 8500 at "2026-10-01T08:00:00+00:00"
    Then the sync response should report 1 received, 0 inserted and 1 updated
    And the store should contain 1 health metrics

  Scenario: Updating the value of an existing metric on re-sync
    Given the health sync API is running with an empty store
    And the mobile app has already synced "steps" with value 8500 at "2026-10-01T08:00:00+00:00"
    When the mobile app retries syncing "steps" with value 9000 at "2026-10-01T08:00:00+00:00"
    Then the store should contain 1 health metrics
    And the "steps" metric should have value 9000
