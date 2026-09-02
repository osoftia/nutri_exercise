# MILESTONE WEB-3 — Technical Blueprint
## Data Fetching & UI Binding — Dashboard ↔ `InteractionService` (Angular Web Portal)

**Acceptance criteria:** `test/features/dashboard_binding.feature`

---

## 0. DESIGN TOKEN REFERENCE (from `design-system/design-tokens.json`)

| Role | Token | Hex |
|---|---|---|
| Canvas BG | `surface.900` | `#0F172A` |
| Card surface | `surface.800` | `#1E293B` |
| Border / divider | `surface.700` | `#334155` |
| Primary | `primary.500` | `#3B82F6` |
| Primary light | `primary.300` | `#93C5FD` |
| Accent CTA | `accent` | `#F97316` |
| Text high / medium / low | `text.high/medium/low` | `#F8FAFC` / `#CBD5E1` / `#64748B` |
| Success | `success` | `#22C55E` |
| Warning | `warning` | `#EAB308` |
| Danger | `danger` | `#EF4444` |
| Neutral muscle | `neutral.muscle` | `#94A3B8` |

Spacing `xs=4 … xxl=32`, radius `sm=8 / md=12 / lg=20`, motion `fast=150ms / normal=250ms`, curve `ease-out`. Typography **Inter**, 12/14/16/20/24/32, weights 400–700.

---

## 1. PREREQUISITE — `InteractionService` (Milestone 2 deliverable)

Milestone 2 ships the `.NET API Integration Setup` and the Angular `InteractionService`.
This milestone consumes it **as-is**; do not rewrite it. **Verify before coding** that the
delivered service, model, and mock exist with the contract below (paths per the repo
kebab-case / `.service.ts` naming):

| Assumed artifact | Path |
|---|---|
| `InteractionService` | `src/app/core/services/interaction.service.ts` |
| `AiInteraction` model | `src/app/core/models/ai-interaction.model.ts` |
| Mock data + apply helpers | `src/app/core/mocks/mock-ai-interactions.data.ts` |

### 1a. Expected service surface (only the parts M3 uses)

```ts
@Service()
export class InteractionService {
  getInteractions(): Observable<AiInteraction[]>;            // newest-first
  submitFeedback(id: string, feedback: string): Observable<AiInteraction>;
  rate(id: string, rating: AiRating): Observable<AiInteraction>; // deferred, unused in M3
}
```

- Follows the existing `Routine` / `Diet` pattern (`environment.useMocks` toggle + `delay()` on mock responses). The mock list MUST contain at least: several `completed` interactions with distinct `createdAt` values (to prove newest-first), an interaction with `feedback` set (for the edit scenario), and an unrated interaction.
- If a signature or field name differs from this contract, **stop and reconcile** — do not silently adapt the UI to a guessed shape.

### 1b. Wire format (existing contract, unchanged)

```json
{
  "id": "guid",
  "prompt": "Age: 28, Goal: build_muscle, Level: intermediate, Days: 4",
  "response": "Weekly routine...\n\nDay 1 - Push: ...",
  "model": "llama3.2",
  "status": "completed",
  "rating": "thumbs_up",
  "feedback": "Great volume but reduce rest to 60s.",
  "createdAt": "2026-08-17T09:30:00Z",
  "ratingAt": "2026-08-17T10:00:00Z",
  "feedbackAt": "2026-08-17T10:05:00Z"
}
```

---

## 2. PROJECT STATE & CONVENTIONS (verified against the repo)

- Angular 22.1, **Material v22** already in `package.json` (`@angular/material`, `@angular/cdk`).
- Unit tests via **Vitest** (`ng test`); specs are colocated (`*.spec.ts`).
- Signal-native codebase: `signal` / `computed`, `input()` / `model()` / `output()`,
  `@if` / `@else if` / `@for` control flow, `inject()` DI, `@Service()` decorator. **No NgRx.**
- Existing services: `Routine` (`getWeeklyRoutine()`), `Diet` (`getDailyMenus()`) with the
  `environment.useMocks` mock-first pattern (`src/app/core/services/`).
- Existing dashboard route component: `DashboardHome`
  (`src/app/pages/admin-dashboard/dashboard-home/`, route `/admin-dashboard`).
  This is the **DashboardComponent** referenced in the milestone brief — do not create a duplicate.
- `app.config.ts` currently has `provideRouter` + `provideHttpClient` only.
- `styles.scss` is a plain dark base (bg `#0F172A`); the M3 Material theme from the M1 plan
  and `provideAnimationsAsync()` are **not yet applied**.
- `app.html` still contains the Angular scaffold placeholder above `<router-outlet />`.

---

## 3. SERVICE INJECTION

Inject the store's dependency through the DI container; components never construct services.

```ts
@Service()
export class DashboardStore {
  private readonly interactionService = inject(InteractionService);
}
```

`DashboardHome` gets the store the same way:

```ts
@Component({ selector: 'app-dashboard-home', standalone: true, /* ... */ })
export class DashboardHome implements OnInit {
  readonly store = inject(DashboardStore);
  ngOnInit(): void { this.store.load(); }
}
```

- Register nothing manually: `@Service()` provides at root like `@Injectable({ providedIn: 'root' })`.
- `HttpClient` is already provided by `provideHttpClient()` in `app.config.ts`.

---

## 4. SIGNAL STATE MODEL — `DashboardStore`

New file `src/app/core/stores/dashboard.store.ts` (naming rule: `.store.ts`).

```ts
@Service()
export class DashboardStore {
  private readonly interactionService = inject(InteractionService);

  readonly interactions = signal<AiInteraction[]>([]);
  readonly loading = signal(true);
  readonly error = signal<string | null>(null);
  readonly submittingIds = signal<ReadonlySet<string>>(new Set());

  readonly total = computed(() => this.interactions().length);
  readonly hasFeedback = computed(
    () => this.interactions().filter((i) => i.feedback !== null).length,
  );
}
```

### 4a. Behaviors (map 1:1 to the `.feature` scenarios)

| Method | Scenario | Behavior |
|---|---|---|
| `load()` | Load on init | `loading=true`, `error=null`; on success `interactions.set(data)` sorted newest-first, on failure `error.set(msg)`; `finally` `loading=false` |
| `retry()` | Retry after error | Delegates to `load()` |
| `submitFeedback(id, text)` | Submit / edit / failure | Adds `id` to `submittingIds`; on success patches `feedback`/`feedbackAt` and emits a snackbar; on failure surfaces a snackbar and leaves the form text untouched (card keeps the value via `@Input()`) |
| `reset()` | Route cleanup | Clears signals (used on destroy) |

### 4b. Subscription hygiene

- `load()` guards against concurrent calls (`if (this.loading()) return`).
- Subscribe with `.subscribe({ next, error, complete })` and set `loading=false` in the
  `complete` handler (matches the existing `DashboardHome` pattern at
  `dashboard-home.ts:61-66`).
- The store is a root-level singleton; no `takeUntilDestroyed` needed for the singleton
  fetch, but `reset()` is still called from the page's `ngOnDestroy` for testability.

---

## 5. COMPONENT WIRING & DATA FLOW

Data flows **one way**: page → store → dumb children. Children emit events; the page
(which owns the store) performs mutations.

```
DashboardHome (page, owns DashboardStore)
 ├─ @if (store.loading())            → <mat-spinner>
 ├─ @else if (store.error())         → error panel + "Retry" → store.retry()
 ├─ @else if (store.total() === 0)   → empty state (neutral.muscle glyph + copy)
 └─ @else                            → @for (interaction of store.interactions(); track interaction.id)
      └─ <app-routine-card [interaction]="interaction"
                            [submitting]="store.submittingIds().has(interaction.id)"
                            (feedbackSubmitted)="store.submitFeedback($event.id, $event.text)" />
```

### 5a. `RoutineCard` (`src/app/features/dashboard/components/routine-card/`)

- `interaction = input.required<AiInteraction>()`
- `submitting = input(false)`
- `feedbackSubmitted = output<{ id: string; text: string }>()`
- Renders a `mat-card` bound to the interaction: prompt (header), model + status
  (`mat-chip` or styled badge), response body (`white-space: pre-wrap`), and hosts
  `FeedbackForm` below the response.
- Never touches the HTTP layer.

### 5b. `FeedbackForm` — the **FeedbackFormComponent** from the brief
(`src/app/features/dashboard/components/feedback-form/`)

- `initialFeedback = input<string | null>(null)`
- `submitting = input(false)`
- `feedbackSubmitted = output<string>()`
- Owns its `FormGroup`; emits the text only after local validation passes.
- See §7 for the Reactive Form contract.

### 5c. Existing dashboard sections

The current `Routine` / `Diet` tables (`Weekly Routines`, `Daily Menus`, stat cards) stay
untouched. The AI-generated routine cards become a new "AI-Generated Routines" panel —
do not replace the existing sections.

---

## 6. MATERIAL UI BINDING

Material v22 (M3) is installed but the theme is **not** wired yet. Required setup
(precondition for this milestone's UI):

| Setup | Where |
|---|---|
| M3 dark theme (`mat.define-theme` / `mat.theme`) mapping the §0 tokens | `src/styles.scss` |
| `provideAnimationsAsync()` | `src/app/app.config.ts` |
| Strip the scaffold placeholder (keep `<router-outlet />`) | `src/app/app.html` |
| Update `app.spec.ts` (drop the `h1 "Hello, web-portal"` assertion) | `src/app/app.spec.ts` |

Material components for the binding:

| Material component | Role |
|---|---|
| `mat-spinner` | Loading state (initial fetch + retry) |
| `mat-card` / `mat-card-header` / `mat-card-content` | One card per AI-generated routine |
| `mat-chip` (or styled badge) | Model / status display on the card |
| `mat-form-field` + `matInput` (`textarea`) | Feedback input (Reactive Form) |
| `mat-error` | "Feedback required" validation message |
| `mat-button` | "Retry" (error state) and "Submit Feedback" |
| `mat-snack-bar` | Success / error toasts ("Feedback saved", "Couldn't save feedback") |

Apply tokens as hex values or CSS custom properties in each component's SCSS; keep
component SCSS lean (budget: 4 kB warning / 8 kB error).

---

## 7. REACTIVE FORMS — `FeedbackForm`

- Import `ReactiveFormsModule` in the standalone `FeedbackForm`.
- Form model (built with `FormBuilder` / `nonNullable`):

```ts
feedback: ['', [Validators.required, Validators.maxLength(2000)]]
```

- **Pre-fill**: `ngOnChanges` (or an `effect` on `initialFeedback()`) patches the control
  when `initialFeedback()` changes, without dirtying the form.
- **Submit flow**:
  1. `form.markAsTouched()`.
  2. If invalid → show `mat-error` "Feedback required", emit nothing.
  3. If valid and not `submitting()` → emit `feedbackSubmitted(form.value.feedback)`, then
     `form.markAsPristine()` (keep the submitted text visible on the card, do not clear it).
- **Failure path**: the parent store never mutates the form; because the card keeps
  feeding the saved `feedback` back via `@Input()`, a failed submit simply leaves the
  control value intact for retry.

---

## 8. LOADING / EMPTY / ERROR STATE TEMPLATE

```html
@if (store.loading()) {
  <div class="ai-panel__loading">
    <mat-spinner diameter="40" />
  </div>
} @else if (store.error(); as message) {
  <div class="ai-panel__error">
    <p>{{ message }}</p>
    <button mat-button (click)="store.retry()">Retry</button>
  </div>
} @else if (store.total() === 0) {
  <div class="ai-panel__empty">
    <span class="ai-panel__empty-glyph">fitness_center</span>
    <p>No AI-generated routines yet.</p>
  </div>
} @else {
  <section class="ai-panel">
    <header class="ai-panel__header">
      <h2>AI-Generated Routines</h2>
      <span>{{ store.total() }} routines · {{ store.hasFeedback() }} with feedback</span>
    </header>
    @for (interaction of store.interactions(); track interaction.id) {
      <app-routine-card
        [interaction]="interaction"
        [submitting]="store.submittingIds().has(interaction.id)"
        (feedbackSubmitted)="store.submitFeedback($event.id, $event.text)"
      />
    }
  </section>
}
```

---

## 9. FILE MANIFEST

| Action | Path | Purpose |
|---|---|---|
| **VERIFY (M2)** | `src/app/core/services/interaction.service.ts` | Consume as-is; reconcile only if contract differs (§1a) |
| **VERIFY (M2)** | `src/app/core/models/ai-interaction.model.ts` | `AiInteraction` + payload types |
| **VERIFY (M2)** | `src/app/core/mocks/mock-ai-interactions.data.ts` | Fixtures incl. distinct `createdAt`, one with `feedback` |
| **CREATE** | `src/app/core/stores/dashboard.store.ts` | Signal store (§4) + `dashboard.store.spec.ts` |
| **CREATE** | `src/app/features/dashboard/components/routine-card/routine-card.{ts,html,scss,spec.ts}` | Material card per interaction |
| **CREATE** | `src/app/features/dashboard/components/feedback-form/feedback-form.{ts,html,scss,spec.ts}` | Reactive feedback form (§7) |
| **MODIFY** | `src/app/pages/admin-dashboard/dashboard-home/dashboard-home.{ts,html,scss}` | Inject `DashboardStore`, init fetch, render AI panel + states (§5, §8) + `dashboard-home.spec.ts` |
| **MODIFY** | `src/app/app.config.ts` | Add `provideAnimationsAsync()` |
| **MODIFY** | `src/styles.scss` | M3 dark Material theme (§0 tokens) |
| **MODIFY** | `src/app/app.html` | Strip scaffold placeholder → `<router-outlet />` shell |
| **MODIFY** | `src/app/app.spec.ts` | Update assertions to the shell (no `h1 "Hello, web-portal"`) |

---

## 10. IMPLEMENTATION ORDER (Recommended for @Coder)

```
PHASE 1 — Preconditions
  ├─ Step 1.1: Verify M2 artifacts (§1). If missing, flag to reviewer; do NOT invent an API.
  ├─ Step 1.2: M3 theme in styles.scss + provideAnimationsAsync() + strip app.html + fix app.spec.ts
  └─ Step 1.3: npm install (lockfile already has @angular/material/@cdk)

PHASE 2 — Store
  ├─ Step 2.1: dashboard.store.ts (load / retry / submitFeedback / reset)
  └─ Step 2.2: dashboard.store.spec.ts (load success, load failure, retry, empty, submit success/failure)

PHASE 3 — Components
  ├─ Step 3.1: feedback-form.* (Reactive Form, validation, pre-fill) + spec
  ├─ Step 3.2: routine-card.* (card binding + hosts feedback form) + spec
  └─ Step 3.3: dashboard-home wiring (states, panel, event delegation) + spec

PHASE 4 — Verification
  ├─ Step 4.1: npm run build            (0 errors, budgets respected)
  ├─ Step 4.2: npm test                 (new + existing specs green)
  ├─ Step 4.3: ng serve → /admin-dashboard → spinner → cards newest-first; retry; submit feedback
  └─ Step 4.4: Walk every scenario in dashboard_binding.feature against mocks
```

---

## 11. TESTING CHECKLIST (maps to `dashboard_binding.feature`)

| # | Scenario | Expected in unit tests |
|---|---|---|
| 1 | Load on initialization | `load()` called from `ngOnInit`; `loading` toggles; cards rendered newest-first |
| 2 | Loading spinner | `loading()` truthy until response arrives; no cards while loading |
| 3 | Empty list | `error` null, `total()===0` → empty-state branch rendered |
| 4 | Initial fetch fails | `error` set; error branch rendered; no cards |
| 5 | Retry reloads | `retry()` re-invokes service; success renders cards |
| 6 | Card binding | Card shows prompt, model, status, response text from the interaction |
| 7 | Submit feedback | `submitFeedback` called with id + text; snackbar; text shown on card |
| 8 | Empty feedback | Form invalid; "Feedback required" shown; no service call |
| 9 | Submit failure | Error snackbar; form text preserved (no reset) |
| 10 | Edit saved feedback | Form pre-filled; resubmission updates card text |

---

## 12. RISKS & NOTES

- **M2 artifacts not yet in the repo** (verified: `web-portal/src` has no
  `interaction.service.ts`, model, or mock; `AiProxyController` in the backend is still a
  placeholder). The brief states Milestone 2 is complete — if the service is missing at
  implementation time, STOP and surface it rather than inventing a fake contract.
- **Material theme is a hard prerequisite**: `mat-spinner`, `mat-card`, `mat-form-field`,
  and `mat-snack-bar` render incorrectly without the M3 theme + `provideAnimationsAsync()`.
- **Mock-first**: keep `environment.useMocks = true`; flipping to HTTP happens in a later
  milestone once the backend `aiproxy` endpoints land.
- **Signals only**: do not introduce NgRx or subscribe in child components; children are
  input/output-bound.
- **Sorting**: enforce newest-first in the store (`createdAt` desc) — never rely on API order.
- **No duplicate dashboard**: the brief's "DashboardComponent" == existing `DashboardHome`.
- **Commit hygiene**: one commit for this milestone, conventional format
  `feat(web): <description>`, after `npm run build` + `npm test` pass.

---

_Generated by @Architect. Hand off to @Coder with this file + `test/features/dashboard_binding.feature` as acceptance criteria._