# Changelog

Todos los cambios notables del **NutriExercise Web Portal** se documentan en este archivo.

## Visión General

Panel de administración web construido en **Angular** (standalone components, signals y estilos con Atomic Design) para gestionar rutinas, nutrición y el ciclo de Reinforcement Learning from Human Feedback (RLHF).

## [2026-08-14]

### Añadido

- Creación del panel de control **RLHF** (Reinforcement Learning from Human Feedback) en Angular para revisar el historial de interacciones con la IA y calificar cada respuesta como Correcta o Incorrecta.
- Conexión del historial con la API de C# mediante `InteractionService` (`GET /api/interaction/history` y `PUT /api/interaction/{id}/feedback`).

### Cambiado

- Configuración del enrutador (`/admin-dashboard` y `/history`) y limpieza de la plantilla por defecto.
- Navegación lateral actualizada con enlace al historial RLHF y enrutado dinámico por cada ítem del menú.
