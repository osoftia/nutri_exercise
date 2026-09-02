---

# MILESTONE 6 — Technical Blueprint
## Continuous Integration (CI) Pipelines via GitHub Actions

---

## 0. BDD ENTRY POINT

Per `mobile_app/BDD_WORKFLOW.md`, the acceptance criteria for this milestone
are defined FIRST in:

- **`mobile_app/test/features/m6_continuous_integration.feature`**

The Coder MUST satisfy every Scenario in that file before considering the
milestone complete. The feature contract, in one line: **two path-filtered
workflows that build, analyze, and test each stack, fail PRs on any error, and
use caching to stay fast.**

---

## 1. CURRENT STATE (verified against the repo)

- **Monorepo layout**
  ```
  .github/workflows/          (does NOT exist yet — created in M6)
  backend/
    NutriExercise.sln         (Net 8 solution)
    NutriExercise.Api/        (ASP.NET Core Web API)
    NutriExercise.Core/       (domain entities/interfaces)
    NutriExercise.Infrastructure/ (EF Core + Ollama AI service)
    NutriExercise.Tests/      (xUnit test project, GlobalUsings: xunit)
  mobile_app/                 (Flutter app, flavors dev/local/qa/prod)
  docs/
  ```
- **Backend**: `TargetFramework=net8.0`, `Nullable=enable`, `ImplicitUsings=enable`.
  Test framework: **xUnit**. PostgreSQL (pgvector) + Ollama are **runtime**
  concerns — tests are smoke/entity tests and must run without a live DB.
- **Mobile**: Flutter, `flutter_lints` v5, `provider` DI, tests under
  `mobile_app/test/` (4 widget tests; 1 known pre-existing failure documented in
  M4/M5 logs). Android APK build targets `main.dart` entrypoints; flavor
  entrypoints (`main_dev.dart`, `main_local.dart`, etc.) exist.
- **`.gitignore`** already excludes `bin/`, `obj/`, `.dart_tool/`, `build/`,
  `*.log` — good, CI artifacts won't pollute the repo.
- No GitHub Actions workflows exist yet.

---

## 2. WORKFLOW FILE STRUCTURE

Two independent workflows, each scoped to its own directory via path filters:

```
.github/workflows/
  mobile_ci.yml     # Flutter: analyze, test, build APK
  backend_ci.yml    # .NET 8: restore, build, test, publish
```

**Why two files?** Path filtering on `on.pull_request.paths` gives the cheapest
form of "run only what changed". A single monorepo workflow would run both
stacks for any change; two files let each pipeline stay independent, with its
own triggers, caching, and required status checks in branch protection.

### 2a. Common workflow skeleton (both files)

```yaml
name: ...
on:
  push:
    branches: [ main ]
    paths:
      - '<scope>/**'          # mobile_app/  or  backend/
      - '.github/workflows/<this-file>'   # CI config changes retrigger CI
  pull_request:
    paths:
      - '<scope>/**'
      - '.github/workflows/<this-file>'

concurrency:
  group: <scope>-ci-${{ github.ref }}
  cancel-in-progress: true
```

Key decisions:

- **`paths`** (not `paths-ignore`) is the primary trigger filter — a PR touching
  `docs/` or `.gitignore` skips both pipelines entirely (Scenario: root/docs-only
  change triggers neither).
- Trigger on **push to main** + **pull_request** so both merge-time and
  PR-time coverage exist.
- Include the workflow file itself in `paths` so CI config edits are validated.
- `concurrency` cancels stale runs on the same ref — saves runner minutes when
  a PR is force-pushed (keeps the "fast thanks to caching" scenarios honest).

---

## 3. PATH FILTERING CONFIGURATION

| Directory | Workflow | `paths` filter |
|---|---|---|
| `backend/` | `backend_ci.yml` | `backend/**` |
| `mobile_app/` | `mobile_ci.yml` | `mobile_app/**` |
| both | both | a change under both dirs runs both (per-file filter) |

Rules that guarantee the feature scenarios:

1. `backend/**` matches every C# file, the `.sln`, `.csproj` files, and
   `appsettings*.json`. It does NOT match `mobile_app/**`.
2. `mobile_app/**` matches Dart sources, `pubspec.yaml`, and the `test/features/`
   BDD docs. It does NOT match `backend/**`.
3. A file at the repo root (`.gitignore`, `README.md`) or under `docs/` matches
   **neither** filter → no CI run (Scenario: root/docs-only change).
4. A PR with `backend/X.cs` + `mobile_app/Y.dart` matches both → both
   workflows run (Scenario: change spanning both directories).

> Note: `paths` on `push`/`pull_request` only affects *triggering*. It is not a
> substitute for a `paths-filter` action on downstream steps; for M6 the
> trigger-level filter is sufficient and simplest.

---

## 4. BACKEND CI (`backend_ci.yml`)

Ubuntu latest runner. Steps:

1. **Checkout** — `actions/checkout@v4`.
2. **Setup .NET 8** — `actions/setup-dotnet@v4` with `dotnet-version: 8.0.x`.
   The SDK pin matches `TargetFramework=net8.0`.
3. **Cache NuGet** — `actions/cache@v4` keyed on
   `nuget-${{ runner.os }}-${{ hashFiles('backend/**/*.csproj') }}`
   (restore path `~/.nuget/packages`). Speeds up step 4 on repeat runs
   (Scenario: NuGet package cache is reused).
4. **Restore** — `dotnet restore backend/NutriExercise.sln`
   (fails fast on the same package set CI will build).
5. **Build** — `dotnet build backend/NutriExercise.sln --configuration Release
   --no-restore`. `--no-restore` keeps the build off the network and
   deterministic after step 4. Non-zero exit fails the PR (Scenario: failed
   dotnet build fails the Backend CI).
6. **Test** — `dotnet test backend/NutriExercise.sln --configuration Release
   --no-build`. Runs the xUnit suite. Non-zero exit fails the PR (Scenario:
   failed dotnet test fails the Backend CI).
7. **Publish binaries** — `dotnet publish backend/NutriExercise.Api
   --configuration Release --no-build -o <staging>` then upload the staging
   directory via `actions/upload-artifact@v4` (Scenario: .NET binaries
   published as an artifact).

> No PostgreSQL/Ollama are required for CI: `dotnet test` targets the
> smoke/entity tests. If a future integration test needs the DB, it must be
> gated behind a build-time flag or `Docker service` so the default CI path
> stays green offline.

---

## 5. MOBILE CI (`mobile_ci.yml`)

Ubuntu latest runner. Steps:

1. **Checkout** — `actions/checkout@v4` with `submodules: false`.
2. **Setup Java** — `actions/setup-java@v4` with `distribution: temurin`,
   `java-version: 17` (Android Gradle Plugin for recent Flutter requires JDK 17).
3. **Setup Flutter** — `subosito/flutter-action@v2` with `channel: stable` and a
   pinned `flutter-version` (match the version used in `mobile_app/`, see
   `.metadata`/lockfile). This also caches the Flutter SDK.
4. **Cache pub dependencies** — the `flutter-action` sets up a pub cache; add an
   explicit `actions/cache@v4` on `~/.pub-cache` keyed on
   `pub-${{ runner.os }}-${{ hashFiles('mobile_app/pubspec.lock') }}`
   (Scenario: Flutter pub cache is reused).
5. **Get dependencies** — `flutter pub get` in `mobile_app/`.
6. **Analyze** — `flutter analyze`. Non-zero exit fails the PR (Scenario:
   failed flutter analyze fails Mobile CI). Note: M5 baseline has **6
   info-level** notices (deprecations) — `flutter analyze` exits 0 with infos,
   so CI stays green unless new errors/warnings appear.
7. **Test** — `flutter test`. Non-zero exit fails the PR (Scenario: failed
   flutter test fails Mobile CI).
8. **Build APK** — `flutter build apk --debug` (or `--release`) in
   `mobile_app/`. Output lands in `mobile_app/build/app/outputs/flutter-apk/`.
9. **Upload artifact** — `actions/upload-artifact@v4` uploading the APK
   (Scenario: Android APK uploaded as a workflow artifact).

### 5a. Flavor/build variant

- The FAB/home entry is `lib/main.dart`; the debug APK build uses it directly.
- If the pipeline must exercise a flavor (`--flavor dev`), add the matching
  `--dart-define=API_BASE_URL` and ensure Android `productFlavors` exist in
  `android/app/build.gradle`. For M6 the default `flutter build apk` suffices;
  flavor matrix builds can be added in a later milestone.

---

## 6. FAIL-FAST / PR GATING

- Every check command (`flutter analyze`, `flutter test`, `flutter build apk`,
  `dotnet restore/build/test/publish`) uses default shell semantics: a
  non-zero exit **aborts the job** and marks the GitHub check as failed
  (Scenarios: failing checks block the PR).
- **Branch protection** on `main` should require:
  - `Mobile CI` status check
  - `Backend CI` status check
  - and mark them as required for merge (Scenario: CI results enforced on PRs).
- Because of path filtering, a backend-only PR will not produce a Mobile CI
  check. To avoid the "waiting for a check that never runs" problem, either
  enable *required* checks with the "require branches to be up to date"
  tolerant mode, or keep both workflows as non-required but default-running on
  `main`. Document the chosen branch-protection rule in the PR template.

---

## 7. CACHING STRATEGY

| Layer | Cache key | Restore path | Hits on |
|---|---|---|---|
| NuGet | `nuget-${{ runner.os }}-${{ hashFiles('backend/**/*.csproj') }}` | `~/.nuget/packages` | unchanged `.csproj` files |
| pub | `pub-${{ runner.os }}-${{ hashFiles('mobile_app/pubspec.lock') }}` | `~/.pub-cache` | unchanged `pubspec.lock` |
| Flutter SDK | handled by `subosito/flutter-action` | — | unchanged Flutter version |
| Gradle (optional) | `gradle-${{ runner.os }}-${{ hashFiles('mobile_app/android/**/*.gradle*') }}` | `~/.gradle/caches` | unchanged Android Gradle config |

Notes:

- Hash the **lockfiles / project files**, not the whole tree, so unrelated edits
  don't invalidate caches.
- Always `actions/cache@v4` with explicit `key` + `restore-keys` fallback
  (`restore-keys: nuget-${{ runner.os }}-`) so a partial change still reuses
  most of the cache.
- Cache writes happen at the end of a successful job; first run on a new key
  will be slower (expected).
- Version-pin the third-party actions (`@v4`/`@v2`) for supply-chain hygiene.

---

## 8. FILE MANIFEST — New & Modified (Coder, next phase)

| Action | Path | Purpose |
|---|---|---|
| **CREATE** | `.github/workflows/mobile_ci.yml` | Flutter: analyze, test, build APK, upload artifact |
| **CREATE** | `.github/workflows/backend_ci.yml` | .NET 8: restore, build, test, publish, upload artifact |
| **CREATE** | `docs/milestone_6_ci_plan.md` | This blueprint (written first) |
| **CREATE** | `mobile_app/test/features/m6_continuous_integration.feature` | BDD acceptance criteria (written first) |
| **CREATE** | `docs/m6_execution_changes.log` | Execution summary (Coder, end of milestone) |
| **MODIFY** (optional) | `README.md` | Badges for both workflows + required-check note |

---

## 9. IMPLEMENTATION ORDER (for the Coder)

```
PHASE 1 — Backend pipeline
  ├── Step 1.1: Create .github/workflows/backend_ci.yml (section 4 steps)
  └── Step 1.2: Push a backend-only change; verify only backend_ci runs

PHASE 2 — Mobile pipeline
  ├── Step 2.1: Create .github/workflows/mobile_ci.yml (section 5 steps)
  └── Step 2.2: Push a mobile-only change; verify only mobile_ci runs

PHASE 3 — Path filter verification
  ├── Step 3.1: Push a docs/ change; verify no workflow runs
  └── Step 3.2: Push a change touching both dirs; verify both run

PHASE 4 — Gating & hardening
  ├── Step 4.1: Configure branch protection requiring both checks
  └── Step 4.2: Verify caching on a second identical run

PHASE 5 — Documentation
  └── Step 5.1: Write docs/m6_execution_changes.log
```

---

## 10. TESTING CHECKLIST (maps to the .feature)

| # | Scenario | Verification |
|---|---|---|
| 1 | Mobile CI triggers only on `mobile_app/` | Open a mobile-only PR → mobile_ci runs, backend_ci skips |
| 2 | Backend CI triggers only on `backend/` | Open a backend-only PR → backend_ci runs, mobile_ci skips |
| 3 | Root/docs-only change triggers neither | Push to `docs/` → no workflow listed |
| 4 | Both-directories change triggers both | Combined PR → both checks appear |
| 5 | Failed `flutter analyze` fails Mobile CI | Introduce analyzer error → job red |
| 6 | Failed `flutter test` fails Mobile CI | Break a test → job red |
| 7 | Failed `dotnet build` fails Backend CI | Break a compile → job red |
| 8 | Failed `dotnet test` fails Backend CI | Fail a test → job red |
| 9 | APK built & uploaded | Artifact list shows the APK |
| 10 | .NET binaries built & uploaded | Artifact list shows publish output |
| 11 | Caching reused | Second run shows NuGet/pub cache hits |
| 12 | PR gating enforced | Failing check blocks merge; passing unblocks |

---

## 11. RISKS & NOTES

- **Flutter version drift**: pin `flutter-version` in `subosito/flutter-action`
  to the version recorded in `mobile_app/.metadata`. Unpinned `stable` can
  break builds when a new stable ships.
- **The known failing Flutter test**: `widget_test.dart` "home page renders mock
  routines and menus" fails because `HomePage` is pumped without a
  `RoutineProvider`. This is pre-existing (M4/M5). **Option A (recommended for
  M6):** keep CI green by fixing the test (wrap `HomePage` in the provider or
  pump `NutriApp`). **Option B:** leave it and accept a red Mobile CI — not
  acceptable. Plan for a tiny test fix in Phase 2.
- **JDK version**: Flutter's Android Gradle Plugin needs JDK 17; using 11/21 can
  fail the APK build. Pin 17 via `actions/setup-java`.
- **Path filter ≠ branch protection**: GitHub "required checks" apply to the
  whole repo. With path-scoped workflows, a PR that never triggers one of the
  checks can appear to skip it. Document the branch-protection strategy
  (Section 6) so reviewers don't block on a check that legitimately never ran.
- **Secrets**: no secrets are needed for M6 (public builds). If the APK build
  later needs signing (release), store `ANDROID_KEYSTORE_*` in GitHub secrets,
  never in the repo.
- **DB/Ollama in CI**: keep CI offline from PostgreSQL/Ollama. Backend tests
  are entity/smoke tests today; integration tests that need those services
  must be added behind a gate.

---