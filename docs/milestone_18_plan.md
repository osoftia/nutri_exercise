# Milestone 18 — AI Backend Integration (C# .NET & Ollama)

> **Author:** @Architect
> **Status:** Ready for @Coder implementation (strict TDD)
> **Branch:** `feature/m18-ai-backend-integration`
> **Contract:** `mobile_app/test/features/m18_ai_integration.feature`

## 1. Scope

The neumorphic AI chat (M17) currently talks to `MockRoutineRepository`. This
milestone replaces that mock path with a real end-to-end flow:

1. A new **`AiChatService`** (Flutter HTTP service) that sends the user prompt
   to the C# .NET API endpoint `POST /api/ai/chat` and parses the JSON reply.
2. A new **`AiChatController`** (`ChangeNotifier`) that owns chat state —
   messages, loading, success and error — so the UI reacts cleanly instead of
   juggling local `_loading` flags.
3. A new **C# `AiController`** (`api/ai`) exposing the `chat` action that
   bridges to the local Ollama service and returns a structured JSON payload.

The mock `generateRoutine` path is removed from the chat's runtime path (the
mock repository stays for unrelated tests). The M17 `AiService.ensureOnline()`
guard remains the pre-flight connectivity check.

---

## 2. Backend contract (C# .NET API)

The existing backend already bridges to Ollama through `OllamaAiService`
(`IAiService`), with a placeholder `AiProxyController` (`api/aiproxy`) that has
no actions. This milestone adds a dedicated chat endpoint on a new controller.

### Endpoint

| Method | Route | Description |
|--------|-------|-------------|
| `POST` | `/api/ai/chat` | Sends the user's message (+ optional history) to Ollama and returns the assistant reply |

### Request JSON

```json
{
  "message": "Push pull 4 days",
  "history": [
    { "role": "user", "content": "Push pull 4 days" },
    { "role": "assistant", "content": "Here is a 4-day push/pull split…" }
  ]
}
```

- `message` (string, **required**): the current user prompt. The controller
  returns `400 Bad Request` when it is null or whitespace.
- `history` (array of `{ role, content }`, optional, default empty): prior
  turns so Ollama can maintain conversational context. `role` is
  `"user" | "assistant"`.

### Success response (`200 OK`)

```json
{
  "id": "7f1e9c2b-3a4d-4e5f-8a6b-0c1d2e3f4a5b",
  "message": "Here is your 4-day push/pull split…",
  "model": "llama3",
  "createdAt": "2026-09-02T10:15:30Z"
}
```

- `id` (string, GUID): the persisted `AiInteraction` id (mirrors the existing
  `AiInteraction` entity so feedback can be submitted later).
- `message` (string): the assistant's reply text rendered inline in the chat.
- `model` (string): the Ollama model used.
- `createdAt` (string, ISO-8601 UTC): server timestamp.

### Error responses

| Status | Body (shape) | Trigger |
|--------|--------------|---------|
| `400` | `{ "error": "Message is required." }` | empty `message` |
| `500` | `{ "error": "The assistant is unavailable right now." }` | Ollama call failed |
| `502` | `{ "error": "The assistant is unavailable right now." }` | Ollama unreachable / bad gateway |

The C# `AiController` orchestrates: validate `message` → call
`IAiService.GenerateRoutineAsync` (RAG-augmented prompt optional) → persist an
`AiInteraction` → return the JSON above. A `ChatRequest` DTO
(`string Message`, `List<ChatMessageDto> History`) and a `ChatMessageDto`
(`string Role`, `string Content`) are declared alongside the controller,
matching the existing `GenerateRoutineRequest` inline-DTO convention.

> **Note (RAG):** `RoutineController.Generate` already demonstrates the
> embedding → `ResearchDocumentRepository` → augmented-prompt pipeline. The
> `chat` action may reuse the same augmentation; this is an implementation
> detail for @Coder and does not change the wire contract.

---

## 3. Flutter `AiChatService`

New file `mobile_app/lib/core/services/ai_chat_service.dart`.

Responsibility: translate a user message into an HTTP round-trip and back into
a typed result. It is **pure Dart** (no Flutter imports) so it is unit-testable
with a mocked `http.Client`.

```dart
class AiChatService {
  AiChatService({required String baseUrl, http.Client? client, Duration timeout});

  Future<String> sendMessage({
    required String message,
    List<ChatTurn> history = const [],
  });
}
```

Design rules:

- **Transport:** `http` package (already a dependency) against
  `$baseUrl/api/ai/chat`. Base URL comes from `ApiConstants.baseUrl`
  (port `5039`).
- **Request body:** `jsonEncode` of `{ "message": …, "history": […] }` with a
  `Content-Type: application/json` header.
- **Timeout:** `.timeout(...)` applied to the future. Ollama generation is slow,
  so use a generous chat timeout (e.g. 60 s) rather than the 10 s used by
  `HttpRoutineRepository`.
- **Typed failures:** throw dedicated exceptions so the controller can map them
  to user-facing copy without inspecting raw responses:
  - `AiChatTimeoutException` — `.timeout` fired.
  - `AiChatHttpException(statusCode)` — non-`200` response.
  - `AiChatParseException` — `200` but the body is not valid JSON / missing
    `message`.
- **Success:** decode the response and return `body['message']` as `String`.

A small `ChatTurn { String role; String content; }` value type accompanies the
service (or lives in `core/models/`).

---

## 4. State management — `AiChatController`

New file `mobile_app/lib/core/state/ai_chat_controller.dart` (sits alongside
`nutrition_controller.dart` etc., same `ChangeNotifier` pattern — **no
third-party state library**).

```dart
enum AiChatStatus { idle, loading, success, error }

class AiChatMessage {
  const AiChatMessage({required this.text, required this.isUser});
  final String text;
  final bool isUser;
}

class AiChatController extends ChangeNotifier {
  AiChatController({required AiChatService service});

  List<AiChatMessage> get messages;
  AiChatStatus get status;
  String? get errorMessage;
  bool get isLoading;          // status == loading

  Future<void> send(String text);   // no-op when text is empty or already loading
  void dispose();
}
```

Behaviour contract (drives the UI elegantly):

1. **Loading:** `send()` appends the user message, sets `status = loading`,
   `errorMessage = null`, notifies, then awaits the service.
2. **Success:** appends the assistant reply from `AiChatService`, sets
   `status = success`, notifies.
3. **Error:** sets `status = error` and maps exceptions to copy:
   - `AiChatTimeoutException` → `"The assistant is taking too long. Please try again."`
   - `AiChatHttpException` / `AiChatParseException` / any other →
     `"The assistant is unavailable right now."`
   The user message stays visible; only the transient error is surfaced.
4. **Re-entrancy:** `send()` is ignored while `isLoading` (prevents parallel
   requests).

`AiChatSheet` (M17) is refactored to consume the controller: its private
`List<_AiChatMessage>` and `_loading` flag move into the controller, and the
widget rebuilds via `ListenableBuilder`/`AnimatedBuilder`. The connectivity
guard (`AiService.ensureOnline`) stays in the sheet's `_send` pre-flight and
still opens `OfflineAiDialog` when offline; the HTTP request itself is the
controller's job.

---

## 5. Wiring

- `app.dart` (`NutriApp`) constructs `AiChatService(baseUrl: ApiConstants.baseUrl)`
  and `AiChatController(service: …)`, then passes the controller to
  `MainShellPage` → `showAiChatSheet`.
- `main_shell_page.dart` and `ai_chat_sheet.dart` drop the `RoutineRepository`
  dependency for chat and use the controller instead.
- `ApiConstants` gains `static String get aiChatPath => '/api/ai/chat';`
  (mirrors `generateRoutinePath`).

### Environment (from `.opencode.md`)

- **Backend API & Ollama live on the Mac local IP, port `5039`.** Do **not**
  use `localhost`. Physical devices/emulators reach the API via
  `--dart-define=API_BASE_URL=http://<mac-ip>:5039` (already supported by
  `ApiConstants`). `Program.cs` already binds the API on `5039`.
- The backend's Ollama `HttpClient` base address is currently hardwired to
  `http://localhost:11434`; if Ollama runs on the Mac (not on the API host),
  this must point at the Mac IP. Flagged as a backend config follow-up, not a
  mobile change.

---

## 6. Files

**New**
- `mobile_app/lib/core/services/ai_chat_service.dart` — HTTP service + typed exceptions + `ChatTurn`.
- `mobile_app/lib/core/state/ai_chat_controller.dart` — `ChangeNotifier` chat state.
- `backend/NutriExercise.Api/Controllers/AiController.cs` — `POST api/ai/chat` + `ChatRequest`/`ChatMessageDto`.

**Modified**
- `mobile_app/lib/ui/molecules/ai_chat_sheet.dart` — consume `AiChatController`.
- `mobile_app/lib/ui/pages/main_shell_page.dart` — pass the controller.
- `mobile_app/lib/app.dart` — instantiate service + controller.
- `mobile_app/lib/core/constants/api_constants.dart` — add `aiChatPath`.

---

## 7. Testability

- **Service unit tests** use a mocked `http.Client` (or `http.testing`'s
  `MockClient`): assert request URL `…/api/ai/chat`, method `POST`, request body
  `message`/`history`, and that success / timeout / `500` / malformed JSON map
  to the right result or exception.
- **Controller unit tests** drive `send()` against a fake `AiChatService` and
  assert status transitions (`loading` → `success`/`error`), message ordering,
  and that a second `send()` during `loading` is a no-op.
- **Widget tests** (`ai_chat_sheet_test.dart`) inject the controller: assert the
  loading indicator appears, the assistant reply renders as a left bubble, and
  timeout/HTTP errors show the exact error copy without leaking a controller.
- Feature keys to reuse: input `ai_chat_input`, send via the `NeumorphicFab`
  `Send` tooltip, bubbles `ai_chat_bubble_<index>`; add a `Key` for the loading
  indicator (e.g. `ai_chat_loading`) and error message (e.g. `ai_chat_error`).

---

## 8. Out of scope

- Streaming (token-by-token) responses — this milestone is single-shot
  request/response.
- Persisting chat history on-device.
- Moving Ollama base URL/model into `appsettings.json` (flagged as a backend
  config follow-up in §5).
