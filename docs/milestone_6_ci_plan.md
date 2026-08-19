# Milestone 6 - CI Pipeline Plan

## Overview

This document defines the Continuous Integration (CI) pipeline for the NutriExercise project. The pipeline automates build, test, and quality checks for both the backend (.NET 8.0) and mobile (Flutter/Dart) projects.

## Pipeline Architecture

### Triggers
- **Push to `main`**: Full pipeline execution
- **Pull Request to `main`**: Full pipeline execution

### Backend CI (`.NET 8.0`)

| Step | Description |
|------|-------------|
| 1. Checkout | Clone repository |
| 2. Setup .NET | Install .NET 8.0 SDK |
| 3. Restore | `dotnet restore` NuGet packages |
| 4. Build | `dotnet build --no-restore` |
| 5. Test | `dotnet test --no-build --verbosity normal --collect:"XPlat Code Coverage"` |
| 6. Code Coverage | Generate and upload coverage report |

### Mobile CI (`Flutter/Dart`)

| Step | Description |
|------|-------------|
| 1. Checkout | Clone repository |
| 2. Setup Flutter | Install Flutter SDK (stable channel) |
| 3. Flutter Doctor | Verify Flutter installation |
| 4. Install Dependencies | `flutter pub get` |
| 5. Analyze | `flutter analyze` (static analysis) |
| 6. Test | `flutter test --coverage` |
| 7. Coverage | Generate and upload coverage report |

## Environment Variables

| Variable | Description |
|----------|-------------|
| `DOTNET_VERSION` | .NET SDK version (8.0.x) |
| `FLUTTER_VERSION` | Flutter SDK version (stable) |

## Quality Gates

- **Backend**: All xUnit tests must pass
- **Mobile**: All Flutter tests must pass, no analysis errors

## Files to Create

```
.github/workflows/
├── backend-ci.yml    # Backend CI pipeline
└── mobile-ci.yml     # Mobile CI pipeline
```
