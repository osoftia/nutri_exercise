# MILESTONE WEB-1 — Technical Blueprint
## RLHF Panel — `/history` Route (Angular Web Portal)

---

## 0. DESIGN TOKEN REFERENCE (from `design-system/design-tokens.json` + mobile `app_theme.dart`)

| Role | Token | Hex | Material Mapping |
|---|---|---|---|
| Canvas BG | `surface.900` | `#0F172A` | `mat-app-background` / page background |
| Card surface | `surface.800` | `#1E293B` | `mat-card`, inputs, surfaces |
| Border / divider | `surface.700` | `#334155` | dividers, outlined controls |
| Primary | `primary.500` | `#3B82F6` | Material primary palette |
| Primary light | `primary.300` | `#93C5FD` | active/selected tints |
| Primary mid | `primary.400` | `#60A5FA` | icons inside active elements |
| Accent CTA | `accent` | `#F97316` | accent palette, focus rings |
| Text high | `text.high` | `#F8FAFC` | headings, values |
| Text medium | `text.medium` | `#CBD5E1` | secondary info |
| Text low | `text.low` | `#64748B` | captions, tertiary labels |
| Success | `success` | `#22C55E` | saved confirmation, thumbs-up active |
| Warning | `warning` | `#EAB308` | pending / partial states |
| Danger | `danger` | `#EF4444` | thumbs-down active, errors |
| Neutral muscle | `neutral.muscle` | `#94A3B8` | muted icons, empty-state glyphs |

| Spacing | Value | | Radius | Value |
|---|---|---|---|---|
| `xs` | 4 px | | `sm` | 8 px |
| `sm` | 8 px | | `md` | 12 px |
| `md` | 12 px | | `lg` | 20 px |
| `lg` | 16 px | | | |
| `xl` | 24 px | | Motion: fast 150 ms / normal 250 ms, `ease-out` | |
| `xxl` | 32 px | | | |

Typography: **Inter**, 12/14/16/20/24/32 px; weights 400/500/600/700.

---

## 1. DOMAIN CONTRACT — `AiInteractions` (assumed API shape)

The backend does **not yet** ship an `AiInteractions` entity. This plan defines the
contract the portal will consume; it must be confirmed against the backend Swagger
(`http://localhost:5039/swagger`) once the backend milestone lands. The frontend is
built **mock-first** (`environment.useMocks = true`) and only switches to HTTP when
the endpoints exist, exactly like the existing `Routine`/`Diet` services.

### 1a. Endpoints (proposed, under the existing `api/aiproxy` controller route)

| Method | Path | Purpose | Body / Response |
|---|---|---|---|
| GET | `/api/aiproxy/interactions` | List AI interactions (newest first) | `200 → AiInteraction[]` |
| POST | `/api/aiproxy/interactions/{id}/rating` | Set 👍/👎 rating | `{ "rating": "thumbs_up" \| "thumbs_down" }` → `200 → AiInteraction` |
| POST | `/api/aiproxy/interactions/{id}/feedback` | Save written DPO feedback | `{ "feedback": string }` → `200 → AiInteraction` |

### 1b. Wire format (JSON the TS interfaces must map)

```json
{
  "id": "f3c2...-guid",
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

- `rating`: `null` when the admin has not rated yet; `"thumbs_up"` / `"thumbs_down"` once rated.
- `feedback`: `null` until a written feedback is submitted; then the text.
- `status`: lifecycle of the generation (`pending` / `completed` / `failed`).

---

## 2. PROJECT STATE & SETUP STEPS

### 2a. Current scaffold (already present — do not regenerate)

```
web-portal/
├─ angular.json                     (application builder, SCSS, budgets)
├─ package.json                     (Angular 22, RxJS 7, vitest unit tests)
├─ tsconfig.json                    (strict-ish: noImplicitOverride, isolatedModules…)
├─ src/
│  ├─ index.html
│  ├─ main.ts                       (bootstrapApplication + appConfig)
│  ├─ styles.scss                   (dark base: bg #0F172A, color #F8FAFC)
│  ├─ environments/                 (environment / .development / .qa / .prod / .model)
│  └─ app/
│     ├─ app.ts / app.html / app.scss / app.routes.ts / app.config.ts / app.spec.ts
│     ├─ components/                (atomic: atoms / molecules / organisms)
│     │  ├─ atoms/    icon, custom-button, form-input
│     │  ├─ molecules/ search-bar, stat-card
│     │  └─ organisms/ admin-sidebar, top-navbar, data-table
│     ├─ core/
│     │  ├─ mocks/    mock-diet.data.ts, mock-routine.data.ts
│     │  └─ services/ auth.ts, diet.ts, routine.ts   (HttpClient + useMocks toggle)
│     └─ pages/
│        └─ admin-dashboard/dashboard-home/          (existing shell route)
```

Conventions to preserve:
- Standalone components only; `@Service()` decorator + `inject()` (not constructor DI).
- Signals (`signal`, `computed`) for UI state; no NgRx — the codebase is signal-native.
- `environment.useMocks` toggle in every HTTP service; mock data under `core/mocks`.
- SCSS for styling; design tokens applied as hex values or CSS custom properties.

### 2b. Initialization steps for this milestone (ordered)

1. **Install Angular Material** (Angular 22 → Material v22):
   ```
   npm i @angular/material @angular/cdk
   ```
2. **Add Material theme to `src/styles.scss`** using the M3 theming API with a custom
   dark palette that maps the design tokens (see §3).
3. **Register animations** in `app.config.ts`: import
   `provideAnimationsAsync` from `@angular/platform-browser/animations/async`.
4. **Add routes** in `app.routes.ts`: lazily load the `/history` page (see §4).
5. **Add the "History" nav item** to `admin-sidebar` (`link: '/history'`, icon `history`).
6. **Add the icon** to the `IconName` union in `components/atoms/icon/icon.ts`.
7. **Create the feature tree** under `src/app/features/rlhf/` (see §5).
8. **Set the environment API URL** in `environment.ts` / `environment.development.ts`:
   `apiUrl: 'http://localhost:5039'` (keep `useMocks: true` for this milestone).

> The portal is served on `http://localhost:4200` (`ng serve`); CORS is already
> configured for that origin in `backend/Program.cs`.

---

## 3. ANGULAR MATERIAL INTEGRATION

### 3a. Theme strategy — Dark Anatomy M3 theme

Create `src/styles.scss` with an M3 Material theme whose palettes are derived from the
design tokens. Use `mat.define-theme` with a dark color-scheme so `MatCard`,
`MatFormField`, `MatButton`, and `MatSnackBar` all inherit the tokens without
per-component theming.

- `primary` palette: base `#3B82F6` (primary.500), with lighter `#60A5FA` / `#93C5FD` tones.
- `tertiary`/accent: `#F97316` (accent).
- `error`: `#EF4444` (danger).
- `surface`: `#1E293B` (surface.800); `app-background`: `#0F172A` (surface.900).
- Apply `color-scheme: dark` and keep `font-family: Inter`.

### 3b. Material components to use in the RLHF panel

| Material component | Role |
|---|---|
| `mat-card` / `mat-card-header` / `mat-card-content` | One card per AI interaction |
| `mat-icon-button` (thumbs up/down) | Rating controls; `color="primary"` when active, `matTooltip` for affordance |
| `mat-progress-spinner` (or `mat-spinner`) | Loading state on first load and per-card submission |
| `mat-form-field` + `matInput` (`textarea`) | Reactive feedback form |
| `mat-snack-bar` | Success / error toasts (e.g. "Feedback saved") |
| `mat-error` | Validation message ("Feedback required") |
| `mat-chip` (optional) | Model / status badges |
| `mat-paginator` (optional, deferred) | If the list grows beyond one screen |

### 3c. Reactive Forms

- Import `ReactiveFormsModule` in the standalone components that own forms.
- Feedback form model (per expanded card, built with `FormBuilder`):
  - `feedback: ['', [Validators.required, Validators.maxLength(2000)]]`
- Submit is disabled while `form.invalid` or while the card is submitting.

---

## 4. ROUTING — `/history`

### 4a. Route registration (`app.routes.ts`)

```ts
export const routes: Routes = [
  {
    path: 'history',
    loadComponent: () =>
      import('./features/rlhf/pages/history/history.page').then(
        (m) => m.HistoryPage,
      ),
  },
  { path: 'admin-dashboard', component: DashboardHome },
  { path: '', redirectTo: '/history', pathMatch: 'full' },  // main route is /history
];
```

- Lazy `loadComponent` keeps the RLHF domain out of the initial bundle.
- The existing `admin-dashboard` shell route stays; `/history` becomes the app's main route.

### 4b. Nav integration

`admin-sidebar.ts` adds:

```ts
{ label: 'History', icon: 'history', link: '/history' },
```

The template binds `item.link` in `routerLink` (currently hard-coded to
`/admin-dashboard` — must be updated to use `item.link`).

---

## 5. FEATURE / DOMAIN-ORIENTED FOLDER STRUCTURE

Add a `features/` tree for the RLHF domain (new domain code goes here; existing
`components/` atomic shell and `pages/admin-dashboard` remain untouched).

```
src/app/
├─ core/                                   (cross-cutting, shared)
│  ├─ config/
│  │  └─ api.constants.ts                  (endpoint paths, central)
│  ├─ models/
│  │  └─ ai-interaction.model.ts           (AiInteraction + payload interfaces)
│  ├─ mocks/
│  │  └─ mock-ai-interactions.data.ts      (mirrors §1b JSON)
│  └─ services/
│     └─ ai-interaction.service.ts         (HTTP + useMocks fallback)
├─ features/
│  └─ rlhf/                                (RLHF domain — feature-oriented)
│     ├─ pages/
│     │  └─ history/
│     │     ├─ history.page.ts             (route component; owns the store)
│     │     ├─ history.page.html
│     │     ├─ history.page.scss
│     │     └─ history.page.spec.ts        (unit tests)
│     ├─ components/
│     │  ├─ interaction-card/              (card: prompt, response, model, status)
│     │  │  ├─ interaction-card.ts
│     │  │  ├─ interaction-card.html
│     │  │  └─ interaction-card.scss
│     │  ├─ rating-control/                (👍/👎 segmented buttons)
│     │  │  ├─ rating-control.ts
│     │  │  ├─ rating-control.html
│     │  │  └─ rating-control.scss
│     │  └─ feedback-form/                 (Reactive Form: textarea + submit)
│     │     ├─ feedback-form.ts
│     │     ├─ feedback-form.html
│     │     └─ feedback-form.scss
│     └─ stores/
│        └─ history.store.ts               (signal-based state, @Service())
├─ components/                             (existing atomic shell — unchanged)
└─ pages/                                  (existing admin-dashboard — unchanged)
```

Naming rules for this codebase: kebab-case files, PascalCase classes/components,
`suffix` `.page.ts` for routed components, `.store.ts` for signal stores,
`.service.ts` for HTTP/domain services.

---

## 6. TYPESCRIPT INTERFACES — `ai-interaction.model.ts`

```ts
export type AiRating = 'thumbs_up' | 'thumbs_down';
export type AiInteractionStatus = 'pending' | 'completed' | 'failed';

export interface AiInteraction {
  id: string;
  prompt: string;                 // preferences sent to the AI
  response: string;               // generated routine text
  model: string;                  // e.g. 'llama3.2'
  status: AiInteractionStatus;
  rating: AiRating | null;        // null = not rated yet
  feedback: string | null;        // null = no written feedback yet
  createdAt: string;              // ISO-8601
  ratingAt: string | null;        // ISO-8601 when rated
  feedbackAt: string | null;      // ISO-8601 when feedback saved
}

export interface RateInteractionRequest {
  rating: AiRating;
}

export interface FeedbackRequest {
  feedback: string;
}

export interface HistoryFilters {
  rating?: AiRating | null;
  status?: AiInteractionStatus | null;
}
```

- Keep interfaces free of classes; the service maps wire JSON 1:1 (field names match
  the backend contract in §1b).
- `createdAt` / `ratingAt` / `feedbackAt` are ISO strings; format for display with the
  platform `Intl.DateTimeFormat` (no extra library).

---

## 7. HTTP SERVICE STRATEGY — `ai-interaction.service.ts`

Follows the existing `Routine`/`Diet` service pattern exactly.

```ts
@Service()
export class AiInteractionService {
  private readonly http = inject(HttpClient);

  getInteractions(): Observable<AiInteraction[]> {
    if (environment.useMocks) {
      return of(mockAiInteractions).pipe(delay(500));
    }
    return this.http.get<AiInteraction[]>(`${environment.apiUrl}${ApiConstants.interactionsPath}`);
  }

  rate(id: string, rating: AiRating): Observable<AiInteraction> {
    const body: RateInteractionRequest = { rating };
    if (environment.useMocks) {
      return of(mockApplyRating(id, rating)).pipe(delay(300));
    }
    return this.http.post<AiInteraction>(
      `${environment.apiUrl}${ApiConstants.ratePath(id)}`, body);
  }

  submitFeedback(id: string, feedback: string): Observable<AiInteraction> {
    const body: FeedbackRequest = { feedback };
    if (environment.useMocks) {
      return of(mockApplyFeedback(id, feedback)).pipe(delay(300));
    }
    return this.http.post<AiInteraction>(
      `${environment.apiUrl}${ApiConstants.feedbackPath(id)}`, body);
  }
}
```

- `ApiConstants` centralizes endpoint paths (`/api/aiproxy/interactions`,
  `.../{id}/rating`, `.../{id}/feedback`).
- Mock helpers (`mockApplyRating`, `mockApplyFeedback`) mutate copies in
  `mock-ai-interactions.data.ts` so consecutive calls behave realistically.
- No HTTP interceptor, auth, or error interceptor in this milestone — keep it minimal.

---

## 8. STATE MANAGEMENT — SIGNAL STORE

The codebase is signal-native, so the RLHF panel state lives in a `@Service()`
store (`history.store.ts`) consumed by `HistoryPage`.

### 8a. Store shape

```ts
@Service()
export class HistoryStore {
  private readonly service = inject(AiInteractionService);

  readonly interactions = signal<AiInteraction[]>([]);
  readonly loading = signal(false);
  readonly error = signal<string | null>(null);
  readonly submittingIds = signal<ReadonlySet<string>>(new Set());

  readonly total = computed(() => this.interactions().length);
  readonly ratedCount = computed(
    () => this.interactions().filter((i) => i.rating !== null).length,
  );
}
```

### 8b. Behaviors (map 1:1 to the `.feature` contract)

| Method | BDD scenario | Behavior |
|---|---|---|
| `load()` | Load history | Sets `loading=true`, clears `error`; on success replaces `interactions` (newest first), on failure sets `error` |
| `retry()` | Error → Retry | Delegates to `load()` |
| `rate(id, rating)` | Thumbs up/down, change, rollback, disabled | **Optimistic**: patch the local interaction immediately, add `id` to `submittingIds`; on API failure revert to previous rating and surface an error; always remove from `submittingIds` when settled |
| `submitFeedback(id, text)` | Submit, edit, failure-preserve | Sends request; on success patches `feedback`/`feedbackAt` and emits a snackbar; on failure keeps text in the form and shows an error snackbar |
| `reset()` | (route leave) | Clears signals |

### 8c. Optimistic rating flow

```
click 👍/👎
  → store.rate(id, rating)
  → interactions.update( patch that card's rating )
  → submittingIds.add(id)                      // disables both buttons
  → service.rate(id, rating)
      ├─ next   → commit server response (authoritative)
      └─ error  → revert previous rating + error snackbar
  → finally    → submittingIds.delete(id)
```

- `HistoryPage` renders through the store only; components (`RatingControl`,
  `FeedbackForm`, `InteractionCard`) receive inputs/emits and never touch the HTTP layer.
- Per-card form state lives inside `FeedbackForm`; only submitted text flows up via
  `(submitted)` output.

---

## 9. COMPONENT BREAKDOWN

### 9a. `HistoryPage` (route component)

- Owns `HistoryStore` via `inject`.
- Template flow:
  - `@if (store.loading())` → centered `mat-spinner`.
  - `@else if (store.error())` → error card + "Retry" button → `store.retry()`.
  - `@else if (store.total() === 0)` → empty state (muted `neutral.muscle` glyph + copy).
  - `@else` → header with "N interactions · M rated" + `@for (interaction of store.interactions())` → `app-interaction-card`.
- Calls `store.load()` in `ngOnInit` (or constructor — Angular 22 signal style).

### 9b. `InteractionCard`

- `@Input()` interaction; emits `(rated)` and `(feedbackSubmitted)`.
- Displays prompt (`mat-card-header`), model + status (`mat-chip`), response body
  (pre-wrap), and delegates rating/feedback to the two child components.

### 9c. `RatingControl`

- Two `mat-icon-button`s (`thumb_up` / `thumb_down`).
- Active rating: primary color for up, danger for down; otherwise `textLow`.
- `disabled` when `submitting` (the card id is in `submittingIds`).

### 9d. `FeedbackForm`

- `@Input()` initial feedback + submitting flag; emits `(submitted: string)`.
- `FormGroup` built in the component; expandable (toggles open/closed).
- On submit: `markAsTouched`, if invalid show `mat-error` ("Feedback required"),
  else emit and reset dirty state (keep the submitted text on the card).

---

## 10. FILE MANIFEST — New & Modified

| Action | Path | Purpose |
|---|---|---|
| **CREATE** | `src/app/core/config/api.constants.ts` | Central endpoint paths |
| **CREATE** | `src/app/core/models/ai-interaction.model.ts` | `AiInteraction` + request interfaces (§6) |
| **CREATE** | `src/app/core/mocks/mock-ai-interactions.data.ts` | Mock payload mirroring §1b + mock apply helpers |
| **CREATE** | `src/app/core/services/ai-interaction.service.ts` | HTTP + `useMocks` fallback (§7) |
| **CREATE** | `src/app/features/rlhf/stores/history.store.ts` | Signal store (§8) |
| **CREATE** | `src/app/features/rlhf/pages/history/history.page.{ts,html,scss,spec.ts}` | Route component + tests |
| **CREATE** | `src/app/features/rlhf/components/interaction-card/*` | Card organism |
| **CREATE** | `src/app/features/rlhf/components/rating-control/*` | 👍/👎 control |
| **CREATE** | `src/app/features/rlhf/components/feedback-form/*` | Reactive feedback form |
| **MODIFY** | `package.json` | Add `@angular/material`, `@angular/cdk` |
| **MODIFY** | `src/styles.scss` | Dark Anatomy M3 Material theme (§3) |
| **MODIFY** | `src/app/app.config.ts` | Add `provideAnimationsAsync()` |
| **MODIFY** | `src/app/app.routes.ts` | Add lazy `/history` route; make it the default (§4) |
| **MODIFY** | `src/app/components/organisms/admin-sidebar/*` | History nav item + use `item.link` |
| **MODIFY** | `src/app/components/atoms/icon/icon.ts` | Extend `IconName` with `history` (and thumb icons if used via Material) |
| **MODIFY** | `src/environments/environment.ts` + `.development.ts` | `apiUrl: 'http://localhost:5039'` (mocks stay on) |
| **MODIFY** | `src/app/app.html` | Replace the Angular placeholder template with `<router-outlet />` + minimal shell |
| **MODIFY** | `src/app/app.spec.ts` | Update to render a simple shell (no placeholder h1 assertions) |

---

## 11. IMPLEMENTATION ORDER (Recommended for @Coder)

```
PHASE 1 — Foundation
  ├─ Step 1.1: npm i @angular/material @angular/cdk
  ├─ Step 1.2: Dark Anatomy M3 theme in styles.scss; provideAnimationsAsync()
  ├─ Step 1.3: Replace app.html placeholder with router-outlet shell; fix app.spec.ts
  └─ Step 1.4: Env apiUrl -> http://localhost:5039 (mocks stay on)

PHASE 2 — Domain Core
  ├─ Step 2.1: api.constants.ts + ai-interaction.model.ts
  ├─ Step 2.2: mock-ai-interactions.data.ts (5–6 fixtures incl. unrated / rated / feedback cases)
  └─ Step 2.3: ai-interaction.service.ts (useMocks pattern)

PHASE 3 — State + Route
  ├─ Step 3.1: history.store.ts (load/rate/submitFeedback/retry, optimistic rating)
  ├─ Step 3.2: history.page.* (loading / error / empty / list states)
  └─ Step 3.3: routes + sidebar nav + icon union

PHASE 4 — Components
  ├─ Step 4.1: interaction-card
  ├─ Step 4.2: rating-control (disabled while submitting, active colors)
  └─ Step 4.3: feedback-form (Reactive Forms, validation, expand/collapse)

PHASE 5 — Verification
  ├─ Step 5.1: npm run build   (no errors)
  ├─ Step 5.2: npm test        (history.page.spec.ts + existing specs green)
  ├─ Step 5.3: ng serve → /history → mock list, rate, submit feedback manually
  └─ Step 5.4: Run every scenario in rlhf_panel.feature against mocks
```

---

## 12. TESTING CHECKLIST (maps to `rlhf_panel.feature`)

| # | Scenario (feature) | Expected |
|---|---|---|
| 1 | Load history successfully | Spinner → cards newest-first; header shows total |
| 2 | Empty history | Empty-state copy, no cards |
| 3 | History request fails | Error card + Retry; Retry reloads |
| 4 | Thumbs up | Rating patched immediately; request sent; button active |
| 5 | Thumbs down | Rating patched immediately; request sent; button active |
| 6 | Change rating | Old rating replaced; new request sent |
| 7 | Rating fails | Reverted to previous value; error surfaced; card remains |
| 8 | Rating in flight | Both buttons disabled; no duplicate requests |
| 9 | Submit feedback | Saved to API; snackbar; text shown on card |
| 10 | Empty feedback | Form invalid; "Feedback required"; no request |
| 11 | Feedback fails | Error snackbar; entered text preserved in form |
| 12 | Edit feedback | Form pre-filled; resubmission updates card |
| 13 | `npm run build` | 0 errors (budgets respected) |
| 14 | `npm test` | unit specs green |

---

## 13. RISKS & NOTES

- **Backend contract not final**: `AiInteractions` does not exist in the C# API yet.
  The frontend is mock-first; when the backend milestone lands, flip `useMocks: false`
  and validate against Swagger. Field names must match §1b.
- **Angular Material version**: Angular 22 pairs with Material v22 (M3 theming). Use
  `mat.define-theme` / `mat.theme`; avoid the legacy `mat-indigo-pink` import.
- **`app.html` placeholder**: the current scaffold still contains the default Angular
  landing template — it must be stripped to a `<router-outlet />` shell or the history
  route renders beneath placeholder content.
- **Sidebar links are hard-coded**: update `admin-sidebar.html` to bind `item.link` so
  the new `/history` entry works (existing items can keep `/admin-dashboard`).
- **Signals, not NgRx**: keep state in a signal store; do not introduce a state library.
- **Strict TS**: interfaces must not use index signatures for known fields
  (`noPropertyAccessFromIndexSignature`).
- **Budgets**: component styles cap at 4 kB warning / 8 kB error — keep SCSS lean.

---

_Generated by @Architect. Hand off to @Coder with this file + `test/features/rlhf_panel.feature` as acceptance criteria._