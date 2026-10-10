# Changelog

Todos los cambios notables del **NutriExercise Web Portal** se documentan en este archivo.

## Visión General

Panel de administración web construido en **Angular** (standalone components, signals y estilos con Atomic Design) para gestionar rutinas, nutrición y el ciclo de Reinforcement Learning from Human Feedback (RLHF).

## [Unreleased]

### Añadido

- Tablero Trello-style de rutinas (`/routine-board`): `organisms/routine-board`, `molecules/board-column` (cdkDropList), `molecules/exercise-card` (checkbox bulk-select, edición inline con form-input), `core/stores/routine-board.store.ts` con fallback a mocks, `core/services/exercise-routine.service.ts` y `core/services/database.service.ts`, `core/utils/routine-drag.util.ts` y `core/utils/exercise.mapper.ts`, contrato Gherkin `features/routine-board.feature` y specs `routine-board.store.spec.ts`, `routine-drag.util.spec.ts`, `exercise.mapper.spec.ts`.
- Endpoints del catálogo genérico: `GET/POST /api/v1/exercises/generic`, `PATCH /api/v1/exercises/generic/{id}`, `POST /api/v1/exercises/generic/bulk-delete`.
- `TelemetryService` como logger global (`debug/info/warn/error()` con prefijo `[Telemetry:<level>]`); `error.interceptor.ts` ahora reporta vía `telemetry.error()`; spec `telemetry.service.spec.ts`.

### Cambiado

- Enlace `Routines` del sidebar apunta a `/routine-board`; nueva ruta lazy `/routine-board` en `app.routes.ts`.

## [2026-08-14]

### Añadido

- Creación del panel de control **RLHF** (Reinforcement Learning from Human Feedback) en Angular para revisar el historial de interacciones con la IA y calificar cada respuesta como Correcta o Incorrecta.
- Conexión del historial con la API de C# mediante `InteractionService` (`GET /api/interaction/history` y `PUT /api/interaction/{id}/feedback`).

### Cambiado

- Configuración del enrutador (`/admin-dashboard` y `/history`) y limpieza de la plantilla por defecto.
- Navegación lateral actualizada con enlace al historial RLHF y enrutado dinámico por cada ítem del menú.
