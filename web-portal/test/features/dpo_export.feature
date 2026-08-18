@milestone_web_5 @rlhf @dpo @export @jsonl @angular @web
Feature: DPO Dataset Export Module

  As an administrator
  I want to export the reviewed interactions as a JSONL dataset
  So that the local Llama3 model can be fine-tuned with Direct Preference Optimization

  Background:
    Given the administrator is on the RLHF dashboard of the Web Portal
    And the portal is configured with the "Dark Anatomy" theme
    And the interaction service has recorded AI-generated routines

  Scenario: Show the export action with the eligible count
    Given some interactions have both a rating and a feedback text
    Then an "Export DPO Dataset" action is displayed
    And the action shows how many interactions are ready to export

  Scenario: Disable export when nothing is eligible
    Given no interaction has both a rating and a feedback text
    Then the "Export DPO Dataset" action is disabled
    And clicking it does not trigger a download

  Scenario: Export only rated interactions that have feedback
    Given a mix of rated-with-feedback, rated-without-feedback, and unrated interactions
    When the administrator exports the dataset
    Then only interactions that have a rating and a feedback text are included
    And interactions missing a rating or a feedback text are excluded

  Scenario: Download a JSONL file
    When the administrator clicks "Export DPO Dataset"
    Then a file download is triggered
    And the downloaded file is named "dpo-dataset-<today's date>.jsonl"

  Scenario: Each line is a JSON object in DPO format
    Then every line of the exported file is a valid JSON object
    And every object contains "prompt", "chosen", and "rejected" fields
    And the "prompt" field holds the user prompt of the interaction

  Scenario: A thumbs-up interaction maps the routine as chosen
    Given an interaction rated thumbs-up with a feedback text
    Then its exported line has the generated routine as "chosen"
    And its feedback text as "rejected"

  Scenario: A thumbs-down interaction maps the feedback as chosen
    Given an interaction rated thumbs-down with a feedback text
    Then its exported line has the feedback text as "chosen"
    And the generated routine as "rejected"