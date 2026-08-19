# Milestone 9 — Voice Input (Speech-to-Text) for the Mobile App Wizard

> **Author:** @Architect
> **Status:** Ready for @Coder implementation (strict TDD)
> **Scope:** Add voice-to-text input to the wizard's text fields using the `speech_to_text` Flutter package.
> **Contract:** `mobile_app/test/features/m9_voice_input.feature`

---

## 1. Integration of the `speech_to_text` package

### 1.1 Dependency

Add to `mobile_app/pubspec.yaml` under `dependencies` (Coder must pick the latest stable at install time):

```yaml
dependencies:
  speech_to_text: ^latest_stable
```

Run `flutter pub get` after editing `pubspec.yaml`.

### 1.2 Platform support

`speech_to_text` is supported on **Android (≥ 5.0 / API 21)**, **iOS (≥ 10)** and desktop/web where the OS provides a recognizer. The CI pipeline (`mobile_cd.yml`) builds only the Android APK, so Android is the primary verification target. iOS configuration is still required so the code compiles and the app is ready for a future iOS build.

### 1.3 Runtime surface

The package exposes the `SpeechToText` class with:

- `initialize(onStatus:, onError:)` — warm up the recognizer and request permission.
- `hasPermission` — whether microphone access was granted.
- `listen(onResult:, listenFor:, localeId:, partialResults:)` — begin recognition; results delivered via `SpeechRecognitionResult.recognizedWords` (and `transcript`).
- `stop()` — end recognition and finalize the transcript.
- `SpeechRecognitionStatus` (`listening`, `done`, `notListening`, `unavailable`) surfaced through `onStatus`.

---

## 2. Required OS permissions

### 2.1 Android — `mobile_app/android/app/src/main/AndroidManifest.xml`

Add **before** the `<application>` tag, next to the existing `POST_NOTIFICATIONS` / `RECEIVE_BOOT_COMPLETED` permissions:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.BLUETOOTH"/>
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT"/>
```

Notes for the Coder:

- `RECORD_AUDIO` is **mandatory** for microphone capture.
- `INTERNET` is required by the on-device/network speech recognizer on some Android versions.
- `BLUETOOTH` + `BLUETOOTH_CONNECT` are needed only for Bluetooth headset microphones; add them only if device support is in scope. If omitted, the feature still works with the built-in microphone.

### 2.2 iOS — `mobile_app/ios/Runner/Info.plist`

Add inside the top-level `<dict>`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>NutriExercise uses the microphone so you can fill in the wizard by voice.</string>
```

`NSMicrophoneUsageDescription` is **mandatory**; iOS terminates the app on first mic access if it is missing.

### 2.3 Permission-request strategy

- On **first tap** of the microphone icon, call `SpeechToText.initialize(...)` which triggers the OS permission prompt (Scenario 1 of the contract).
- Cache the permission result in the service. Do **not** re-prompt once granted (Scenario 2 assumes "already granted").
- On denial, surface the denial UI state without crashing (Scenario 4 of the contract).

---

## 3. Mocking strategy for testing

The codebase already follows **constructor-based dependency injection** (`app.dart` chooses repository implementations from `AppConfig`). Voice input must follow the same pattern so widget tests never touch the real platform channel.

### 3.1 Abstraction to introduce

- **`VoiceInputService`** (abstract, in `lib/core/services/voice_input_service.dart`):

  - `Future<bool> initialize()` — warm-up + permission request; returns `true` when permission granted.
  - `Future<void> startListening({ValueChanged<String>? onPartial, VoidCallback? onStatusChanged})`.
  - `Future<String?> stopListening()` — returns the final transcript (`null` when nothing was recognized).
  - `bool get isListening`.
  - A callback/stream carrying status changes (`listening`, `done`, `notListening`, `unavailable`) so the UI can render the pulsing/"Listening..." state.

- **`SpeechToTextVoiceInputService`** (real implementation) wraps the `speech_to_text` plugin. Lives in `lib/core/services/` and is the only class that imports `package:speech_to_text/speech_to_text.dart`.

- **`MockVoiceInputService`** (test double, in `test/` or `lib/core/mocks/` mirroring the existing `mock_routine_repository.dart` convention) that simulates:

  - granted / denied permission outcomes,
  - a scripted transcript sequence,
  - unrecognized-speech (`null` transcript) and error outcomes.

### 3.2 Why this strategy

- `speech_to_text` uses a **platform channel** (`plugins.flutter.io/speech_to_text`). In widget tests there is no real recognizer and the channel returns nothing, so any code calling the plugin directly would hang or throw.
- Abstracting behind an interface means widget tests **inject `MockVoiceInputService`** into the wizard widget exactly like `MockDietRepository` is injected into `HomePage` today — no platform-channel mocking, no real hardware, fully deterministic scenarios.
- Widget tests then cover: icon tap → listening state, transcript → field population, denial → error message, unrecognized speech → retry message.

### 3.3 Test doubles to provide

In `mobile_app/test/` (Coder decides exact filenames; proposal):

- `test/mocks/mock_voice_input_service.dart` — a configurable fake (`denyPermission: bool`, `transcript`, `throwError: bool`, `unrecognized: bool`).

### 3.4 What is NOT mocked

`SpeechToTextVoiceInputService` (the thin plugin adapter) is verified manually on a physical Android device; it is excluded from widget tests by design because the contract's scenarios are all UI/state-level.

---

## 4. TDD Execution Order (for @Coder)

Follow this exact order. **Red → Green → Refactor** at every step. Run `flutter test` and `flutter analyze` after each step. Do not skip to implementation before a failing test exists.

| Step | Action | Test to write first (RED) | Implementation (GREEN) | Verify |
|------|--------|----------------------------|------------------------|--------|
| 0 | Add `speech_to_text` dependency to `pubspec.yaml`; run `flutter pub get`. | — | — | `flutter pub get` succeeds |
| 1 | **Contract:** keep `test/features/m9_voice_input.feature` as the source of truth (already provided by @Architect). | — | — | — |
| 2 | **Service abstraction:** write a failing test that constructs `MockVoiceInputService` and asserts the `VoiceInputService` contract compiles and its simulated states behave (grant/deny/transcript/error). | `test/services/voice_input_service_test.dart` (RED: `VoiceInputService` and `MockVoiceInputService` don't exist yet) | Create `lib/core/services/voice_input_service.dart` (abstract) + `lib/core/mocks/mock_voice_input_service.dart` | `flutter test` green on this file |
| 3 | **Real adapter (platform):** write a failing test asserting `SpeechToTextVoiceInputService` exists and delegates to the plugin wrapper (compile-level contract only). | extend `test/services/voice_input_service_test.dart` (RED: adapter missing) | Create `lib/core/services/speech_to_text_voice_input_service.dart` wrapping `SpeechToText` | `flutter test` green on this file |
| 4 | **Permission UI (Scenario 1 & 4):** write a failing widget test: tap mic with `MockVoiceInputService(denyPermission: true)` → expect error message and idle icon; tap with granted → expect "Listening..." state. | `test/features/m9_voice_input_widget_test.dart` (RED: widget missing) | Create the wizard voice-input widget (mic icon, idle/listening states, error text) and wire permission flow | `flutter test` green |
| 5 | **Listening UI (Scenario 2):** extend the widget test: granted permission, tap mic → expect pulsing indicator + "Listening..." text + read-only field. | extend widget test (RED) | Add listening state animation (pulsing glow on the mic icon, `AnimatedContainer`/`AnimationController` per `app_theme.dart` tokens), disable field while listening | `flutter test` green |
| 6 | **Transcript → field (Scenario 3):** extend widget test: `MockVoiceInputService(transcript: 'Increase my weekly training volume')` → after stop, field contains the text and icon returns to idle. | extend widget test (RED) | Wire `startListening` partial/final results into the `TextEditingController` | `flutter test` green |
| 7 | **Error handling (Scenarios 5):** extend widget test: `MockVoiceInputService(unrecognized: true)` and `throwError: true` → expect "Sorry, I did not understand..." / "Voice input failed..." messages, field keeps previous value, icon idle. | extend widget test (RED) | Add unrecognized/error status handling in the widget | `flutter test` green |
| 8 | **Platform permissions:** add `RECORD_AUDIO` (AndroidManifest) and `NSMicrophoneUsageDescription` (Info.plist) per §2. | — (manual/compile check) | Edit both files | `flutter analyze` clean; Android release build (`flutter build apk --release`) compiles |
| 9 | **Integrate into wizard:** wire the new widget into the wizard input field(s). | (contract-level; covered by step 4-7 widget tests via DI) | Pass `VoiceInputService` through the same constructor-DI pattern used in `app.dart` | `flutter test` + `flutter analyze` clean |
| 10 | **Regression + log:** run the full suite (`flutter test`), `flutter analyze`, and update `mobile_app/m7_cd_execution.log` or create `mobile_app/m9_voice_input_execution.log` documenting every change. | — | — | Full suite green; log updated |

### 4.1 Definition of Done (DoD)

- All scenarios in `test/features/m9_voice_input.feature` are represented by at least one passing widget test.
- `flutter test` passes with zero failures.
- `flutter analyze` reports no issues.
- `flutter build apk --release` succeeds (Android verification of permissions).
- No real `speech_to_text` plugin call happens inside widget tests (mocks only).
- Execution changes logged in `mobile_app/m9_voice_input_execution.log`.

---

## 5. Files created by this milestone (proposal)

```
mobile_app/
├── test/
│   ├── features/
│   │   └── m9_voice_input.feature          # BDD contract (this milestone)
│   ├── mocks/
│   │   └── mock_voice_input_service.dart   # Test double for VoiceInputService
│   ├── services/
│   │   └── voice_input_service_test.dart   # Service contract tests
│   └── features/
│       └── m9_voice_input_widget_test.dart # Widget tests per contract scenario
├── lib/core/
│   ├── services/
│   │   ├── voice_input_service.dart            # Abstract contract
│   │   └── speech_to_text_voice_input_service.dart # Real plugin adapter
│   └── mocks/
│       └── mock_voice_input_service.dart   # (if mock lives in lib per repo convention)
├── android/app/src/main/AndroidManifest.xml   # + RECORD_AUDIO (modified)
├── ios/Runner/Info.plist                     # + NSMicrophoneUsageDescription (modified)
└── m9_voice_input_execution.log              # Change log (created by Coder)
```

## 6. Open decisions (for @Architect review, not blocking)

1. Whether `BLUETOOTH`/`BLUETOOTH_CONNECT` permissions are needed (Bluetooth headset support) or only the built-in microphone.
2. Whether voice input should also enable **continuous dictation** (`partialResults: true`) so the field updates live while speaking, or only on stop (final transcript).
3. Wizard locale/language for recognition (`localeId`); default to the device locale unless a Spanish-first setting is required.