# Changelog

All notable changes to the **NutriExercise** mobile app are documented in this file. Entries are appended automatically by the `post-commit` Git hook.

## Overview

The mobile app is a **Flutter** application designed for a resilient, offline-first user experience:

- **Flutter**: cross-platform UI built with a clean, layered architecture.
- **Offline-first**: SQLite local storage so routines and data remain available without connectivity.
- **AI integration**: an AI network interceptor plus an end-to-end AI routine test view wired to the backend (Ollama).
- **Local notifications**: scheduling reminders for workouts and routines.
- **Interactive UI**: vector-based interactive body map with custom hit-testing and gym-themed styling.
- **Design system**: design tokens and atomic UI scaffolding for consistent, reusable components.

## [2026-08-14]

### Added

- `feat(mobile)` — SQLite offline storage, AI network interceptor, and local notifications (`55fc5d6`).
- `feat(mobile)` — interactive vector body map with custom hit-testing and blue gym styling (`17bbf48`).
- `feat(mobile)` — design tokens, atomic UI scaffolding, and mock repositories (`fbdddd9`).
- `feat(integration)` — Flutter HTTP client endpoints wired to the C# API with CORS (`be55b86`).

### Changed

- `docs` — architecture and directory tree documentation for mobile (`6828750`).
