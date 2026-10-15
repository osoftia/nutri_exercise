Feature: HTTP Request and Response File Logging
  As a backend developer debugging mobile-to-API connectivity
  I want every inbound request and outbound response written to rolling log files
  So that I can trace Flutter payloads and Ollama connectivity failures without a database round-trip

  Scenario: Capturing an inbound request for mobile debugging
    Given a mobile client at IP "10.0.2.2" sends a "POST" request to "/api/Rag/query"
    And the request carries the header "X-Platform" with value "Flutter"
    And the request body is '{"query":"creatina"}'
    When the HTTP logging middleware processes the request
    Then the log should contain a "[HTTP-REQUEST]" entry with the remote IP "10.0.2.2"
    And the log should contain the header "X-Platform: Flutter"
    And the log should contain the request body "creatina"

  Scenario: Capturing the outgoing response and status code
    Given a mobile client at IP "127.0.0.1" sends a "POST" request to "/api/Rag/query"
    When the HTTP logging middleware processes the request
    Then the log should contain a "[HTTP-RESPONSE]" entry with status code 200

  Scenario: Tracing an unhandled Ollama connectivity failure
    Given a mobile client at IP "10.0.2.2" sends a "POST" request to "/api/AiProxy/generate"
    When the downstream pipeline throws a "HttpRequestException" mentioning "Ollama"
    Then the HTTP logging middleware should rethrow the exception
    And the log should contain an "[HTTP-ERROR]" entry with the stack trace
