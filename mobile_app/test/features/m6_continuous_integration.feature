@milestone_6 @devops @ci @github_actions
Feature: Continuous Integration Pipelines

  As a developer
  I want automated CI pipelines for the .NET backend and the Flutter mobile app
  So that regressions are caught before they reach the main branch

  Background:
    Given the repository is a monorepo with the "mobile_app/" and "backend/" directories
    And GitHub Actions is enabled on the repository

  Scenario: Mobile CI triggers only when mobile app files change
    Given a pull request modifies a file under "mobile_app/"
    When the pull request is opened or updated
    Then the Mobile CI workflow runs automatically
    And the Backend CI workflow does not run

  Scenario: Backend CI triggers only when backend files change
    Given a pull request modifies a file under "backend/"
    When the pull request is opened or updated
    Then the Backend CI workflow runs automatically
    And the Mobile CI workflow does not run

  Scenario: A monorepo root or docs-only change triggers neither pipeline
    Given a pull request modifies only files outside "mobile_app/" and "backend/", such as "docs/" or ".gitignore"
    When the pull request is opened or updated
    Then neither the Mobile CI nor the Backend CI workflow runs

  Scenario: A change spanning both directories triggers both pipelines
    Given a pull request modifies files under both "mobile_app/" and "backend/"
    When the pull request is opened or updated
    Then the Mobile CI workflow runs
    And the Backend CI workflow runs

  Scenario: Failed flutter analyze fails the Mobile CI pipeline
    Given a pull request modifies Flutter source with an analyzer error or warning
    When the Mobile CI workflow runs flutter analyze
    Then the workflow exits with a non-zero status
    And the pull request is marked as failing its required Mobile CI check

  Scenario: Failed flutter test fails the Mobile CI pipeline
    Given a pull request introduces a failing Flutter widget or unit test
    When the Mobile CI workflow runs flutter test
    Then the workflow exits with a non-zero status
    And the pull request is marked as failing its required Mobile CI check

  Scenario: Failed dotnet build fails the Backend CI pipeline
    Given a pull request introduces a C# compilation error
    When the Backend CI workflow runs dotnet build
    Then the workflow exits with a non-zero status
    And the pull request is marked as failing its required Backend CI check

  Scenario: Failed dotnet test fails the Backend CI pipeline
    Given a pull request introduces a failing backend test
    When the Backend CI workflow runs dotnet test
    Then the workflow exits with a non-zero status
    And the pull request is marked as failing its required Backend CI check

  Scenario: Successful Mobile CI builds the Android APK
    Given a pull request with valid Flutter code
    When the Mobile CI workflow runs
    Then flutter pub get resolves dependencies successfully
    And flutter analyze reports zero errors
    And flutter test passes
    And the Android debug APK is built and uploaded as a workflow artifact

  Scenario: Successful Backend CI builds the .NET binaries
    Given a pull request with valid C# code
    When the Backend CI workflow runs
    Then dotnet restore resolves NuGet packages successfully
    And dotnet build compiles the solution without errors
    And dotnet test passes all backend tests
    And the built .NET binaries are published as a workflow artifact

  Scenario: CI execution is fast thanks to caching
    Given the CI workflows are configured with caching
    When a workflow runs for a second time with unchanged dependencies
    Then NuGet package cache is reused for the backend
    And Flutter pub cache is reused for the mobile app

  Scenario: CI results are enforced on pull requests
    Given the repository branch protection requires status checks to pass
    When a pull request fails a CI workflow
    Then the pull request cannot be merged
    When all CI workflows pass
    Then the pull request can be merged