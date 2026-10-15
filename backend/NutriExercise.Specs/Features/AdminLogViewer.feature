Feature: Admin Log Viewer API
  As an administrator
  I want to filter the application logs through the API
  So that I can inspect errors without accessing the server files manually

  Scenario: Returning only error logs within a date range
    Given the log fixtures:
      | file                        | timestamp                 | level       | message                                  |
      | nutriexercise-20260930.json | 2026-09-30T08:00:00+00:00 | Information | [RAG-INFO]: Vector inserted.             |
      | nutriexercise-20260930.json | 2026-09-30T09:15:00+00:00 | Error       | [RAG-ERROR]: pgvector similarity failed. |
      | nutriexercise-20261001.json | 2026-10-01T10:00:00+00:00 | Error       | [HTTP-ERROR]: Ollama unreachable.        |
      | nutriexercise-20261001.json | 2026-10-01T11:30:00+00:00 | Information | [RAG-INFO]: Routine generated.           |
    When I request logs from "2026-09-30T00:00:00+00:00" to "2026-10-01T23:59:59+00:00" filtered by level "Error"
    Then the response should contain 2 log entries
    And every entry in the response should have level "Error"

  Scenario: Filtering by the RAG error tag
    Given the log fixtures:
      | file                        | timestamp                 | level | message                                  |
      | nutriexercise-20260930.json | 2026-09-30T09:15:00+00:00 | Error | [RAG-ERROR]: pgvector similarity failed. |
      | nutriexercise-20261001.json | 2026-10-01T10:00:00+00:00 | Error | [HTTP-ERROR]: Ollama unreachable.        |
    When I request logs filtered by tag "[RAG-ERROR]"
    Then the response should contain 1 log entries
    And the first entry message should contain "[RAG-ERROR]"

  Scenario: Logs are returned in reverse chronological order
    Given the log fixtures:
      | file                        | timestamp                 | level       | message                   |
      | nutriexercise-20260930.json | 2026-09-30T08:00:00+00:00 | Information | [RAG-INFO]: Oldest entry. |
      | nutriexercise-20261001.json | 2026-10-01T11:30:00+00:00 | Information | [RAG-INFO]: Newest entry. |
    When I request all logs
    Then the first entry timestamp should be "2026-10-01T11:30:00+00:00"

  Scenario Outline: Paginating the log stream
    Given the log fixtures:
      | file                        | timestamp                 | level       | message                  |
      | nutriexercise-20261001.json | 2026-10-01T09:00:00+00:00 | Information | [RAG-INFO]: Entry one.   |
      | nutriexercise-20261001.json | 2026-10-01T10:00:00+00:00 | Information | [RAG-INFO]: Entry two.   |
      | nutriexercise-20261001.json | 2026-10-01T11:00:00+00:00 | Information | [RAG-INFO]: Entry three. |
      | nutriexercise-20261001.json | 2026-10-01T12:00:00+00:00 | Information | [RAG-INFO]: Entry four.  |
    When I request page <Page> with page size 2
    Then the response should contain <Count> log entries
    And the first entry message should contain "<First>"

    Examples:
      | Page | Count | First      |
      | 1    | 2     | Entry four |
      | 2    | 2     | Entry two  |
