# Changelog

All notable changes to the **NutriExercise** backend are documented in this file. Entries are appended automatically by the `post-commit` Git hook.

## Overview

The backend is a **Clean Architecture** solution built on **ASP.NET Core** (.NET):

- **Clean Architecture**: `Api` / `Core` / `Infrastructure` projects with a clear separation of concerns, dependency inversion, and interface-driven design.
- **EF Core + PostgreSQL**: relational data layer powered by Entity Framework Core.
- **pgvector**: vector similarity search configured alongside the PostgreSQL migration pipeline.
- **Supabase**: cloud-hosted Postgres placeholder for managed database infrastructure.
- **Ollama**: local AI service integration powering the routine-generation endpoint.
- **CORS & API contracts**: CORS policy wired for Flutter/web clients with HTTP client endpoints connected end-to-end.


## [2026-08-14]

- \`ed1fa78\` feat(backend): add pgvector support and schema for RAG (ResearchDocument) and RL (AiInteraction)

## [2026-08-14]

### Added

- `feat(integration)` — CORS policy in the C# API and wired Flutter HTTP client endpoints (`be55b86`).
- `feat(backend)` — local Ollama AI service integration and routine generation endpoint (`5fcc6c0`).
- `chore(backend)` — cloud PostgreSQL placeholder configuration, Docker removal, and initial EF Core migrations (`24dcee8`).

### Changed

- `refactor(backend)` — migrated EF Core to PostgreSQL and configured pgvector support (`47c7f2b`).
- `docs` — architecture and directory tree documentation for backend (`6828750`).
