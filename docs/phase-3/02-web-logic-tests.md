# PHASE 3 — Angular Web App (Services, Routing, State, Jasmine/Karma)

> **Author:** [Qwen] (Development & QA Lead)
> **Status:** Draft — pending approval
> **Depends on:** `docs/phase-3/01-web-ui.md` (UI), `docs/phase-1/02-sdd-contracts.md` (API)
> **Scope:** Angular structure, feature modules, routing/guards, services (HTTP + caching), NgRx state, typed API models, and the Jasmine/Karma test suite.

---

## 1. Angular Project Layout

```text
web/
├── angular.json                      # 3 projects: nutri-web, nutri-design-system, nutri-web-e2e
├── src/
│   ├── app/
│   │   ├── core/                     # DI singletons: http, auth, api-client, error-handler
│   │   │   ├── http/ (ApiHttpClient, error interceptor, auth interceptor)
│   │   │   └── guards/ (auth.guard, onboarding.guard)
│   │   ├── shared/                   # atoms + molecules (design system, pure)
│   │   ├── features/
│   │   │   ├── onboarding/           # feature module: components + store
│   │   │   ├── explore/              # body-map driven exercise browser
│   │   │   ├── workouts/
│   │   │   ├── nutrition/
│   │   │   ├── schedule/
│   │   │   ├── assistant/
│   │   │   └── profile/
│   │   ├── state/                    # root NgRx store (auth, sync)
│   │   └── app.routes.ts             # lazy routes
│   └── environments/                 # apiUrl, offlineTimeoutMs
└── projects/nutri-design-system/     # standalone component library (atoms/molecules)
```

- Angular 18+, standalone components, `provideRouter` + `provideStore` in `app.config.ts`.
- Strict mode (`strictTemplates: true`).

---

## 2. Routing & Guards

```ts
export const routes: Routes = [
  { path: '', component: LandingPage, canActivate: [GuestGuard] },
  { path: 'onboarding', component: OnboardingPage, canActivate: [AuthGuard] },
  { path: 'explore', loadComponent: () => import('./features/explore/explore.page').then(m => m.ExplorePage),
    canActivate: [AuthGuard, OnboardingGuard] },
  { path: 'workouts/:id', loadChildren: () => import('./features/workouts/workouts.routes') },
  { path: 'nutrition', loadChildren: () => import('./features/nutrition/nutrition.routes') },
  { path: 'schedule', loadChildren: () => import('./features/schedule/schedule.routes') },
  { path: 'assistant', loadChildren: () => import('./features/assistant/assistant.routes') },
  { path: 'profile', loadChildren: () => import('./features/profile/profile.routes') },
  { path: '**', redirectTo: '' },
];

export const authGuard: CanActivateFn = () => inject(AuthStore).user() ? true : inject(Router).createUrlTree(['/']);
export const onboardingGuard: CanActivateFn = () => inject(ProfileStore).hasProfile() ? true : inject(Router).createUrlTree(['/onboarding']);
```

- Lazy-loaded feature modules; `preloadStrategy: PreloadAllModules` after first paint (Explore prefetched since it is the core flow).

---

## 3. Typed API Models + Api Client

```ts
// shared/models (mirror contract §3)
export interface ProfileRequest { userId: string; profile: ProfileDto }
export interface ProfileResponse { profileId: string; bmr: number; tdee: number; macroSplit: MacroSplitDto }
export interface MuscleRegion { id: MuscleGroupId; label: string; d: string; view: 'FRONT'|'BACK'; fill: string; neighbors: MuscleGroupId[]; exerciseCount: number }
export interface ExerciseDto { exerciseId: string; name: string; muscles: MuscleGroupId[]; sets: number; reps: string; restSeconds: number; equipment: Equipment }

// core/http/api-http-client.ts
@Injectable({ providedIn: 'root' })
export class ApiHttpClient {
  private base = inject(ENVIRONMENT).apiUrl;
  get<T>(path: string, params?: HttpParams) { /* envelope unwrap, requestId logging */ }
  post<T>(path: string, body: unknown) { /* 201 → parse Location */ }
}
```

- Interceptors: `AuthInterceptor` (JWT header), `ErrorInterceptor` (maps `errors[]` → typed `ApiError`, HTTP codes), `CacheInterceptor` (GET `/api/v1/muscles` 24h TTL).

---

## 4. State Management (NgRx Signals)

```ts
// state/explore/explore.store.ts
export const exploreStore = signalStore(
  withState({ view: 'FRONT' as BodyView, selected: [] as MuscleGroupId[],
              catalog: [] as ExerciseDto[], loading: false, error: null }),
  withComputed(({ selected }) => ({ count: computed(() => selected().length) })),
  withMethods((store) => ({
    selectMuscle(id: MuscleGroupId) {
      patchState(store, { selected: toggle(store.selected(), id) });
    },
    async loadCatalog() {
      patchState(store, { loading: true });
      const muscles = store.selected().join(',');
      const catalog = await inject(ExerciseService).getByMuscles(muscles).toPromise();
      patchState(store, { catalog, loading: false });
    },
  })),
);
```

Stores per feature (all signal-store based, no async pipelines leaking into templates):

| Store | State | Key actions |
| --- | --- | --- |
| `AuthStore` | user, token | login, logout |
| `ProfileStore` | profile, hasProfile | submit, refresh |
| `ExploreStore` | view, selected, catalog, loading | selectMuscle, toggleView, loadCatalog, reset |
| `WorkoutStore` | plan, days, completion | generate, load, toggleExercise |
| `NutritionStore` | menu, macros | generate, load |
| `ScheduleStore` | schedules | load, upsert, remove |
| `AssistantStore` | messages, offline | send, networkRequired |
| `SyncStore` | status, pendingCount, conflicts | detectChange, review |

- `SyncStore` subscribes to `window online/offline` events → sets status; drives the `SyncStatusBanner` organism.
- `AssistantStore.send()` wraps the API call in `try/catch` and surfaces the offline `NETWORK_REQUIRED` banner instead of an error stack (web mirrors mobile interceptor contract §4.4).

---

## 5. Feature Modules (representative)

### 5.1 Explore (`features/explore`)

```ts
// explore.page.ts (composition root)
@Component({ selector: 'app-explore-page', template: `
  <app-workout-layout>
    <app-body-map-canvas [view]="view" [regions]="regions"
                         (regionToggle)="store.selectMuscle($event)"
                         (viewChange)="store.toggleView($event)" />
    <app-exercise-filter-bar [selected]="store.selected()" (reset)="store.reset()" />
    <app-exercise-catalog [exercises]="store.catalog()" [loading]="store.loading()" />
  </app-workout-layout>` })
export class ExplorePage { readonly store = inject(ExploreStore); readonly regions = inject(MuscleService).regions; }
```

- `MuscleService` loads regions once, filters by `view`; memoized with `cache-manager`-like TTL.
- Catalog requests debounced 300ms after selection changes; `switchMap` cancels stale requests.

### 5.2 Onboarding

- `OnboardingStepper` holds per-step reactive forms (`FormGroup`); on final step posts `ProfileRequest`, then `ProfileStore.submit` navigates to `/explore`.
- Server-computed BMR/TDEE/macros displayed in a `MetricRing` + `StatCard` summary step.

### 5.3 Schedule / Notifications (web)

- `ScheduleService` CRUD via contract §3.5; web schedules surface as calendar chips (native local notifications are mobile-only; web uses browser `Notification` API as enhancement).

---

## 6. Jasmine/Karma Test Suite

### 6.1 Layout & Conventions

```text
src/app/features/explore/
├── explore.store.spec.ts          # pure store tests (signals)
├── explore.page.spec.ts           # component test (TestBed, mocked services)
├── organisms/body-map-canvas.spec.ts
└── molecules/muscle-region.spec.ts
```

- Karma + Jasmine headless (`ChromeHeadless`), `karma-jasmine`, `jasmine-marbles` for RxJS.
- `mock providers` via `provideMock` (`ng-mocks`) — no HTTP in component tests; HTTP mocked with `HttpTestingController`.
- Coverage (Karma): statement 80% across `app/`.

### 6.2 Store Tests

```ts
describe('ExploreStore', () => {
  it('toggle view flips FRONT->BACK', () => {
    TestBed.configureTestingModule({ providers: [exploreStore] });
    const store = TestBed.inject(exploreStore);
    store.toggleView('BACK');
    expect(store.view()).toBe('BACK');
  });

  it('selectMuscle adds and toggling again removes', () => {
    store.selectMuscle('CHEST');
    store.selectMuscle('CHEST');
    expect(store.selected()).not.toContain('CHEST');
  });

  it('loadCatalog maps server DTOs into catalog state', fakeAsync(() => {
    // HttpTestingController: flush GET /api/v1/exercises?muscle=CHEST
  }));
});
```

### 6.3 Component Tests

```ts
describe('BodyMapCanvas', () => {
  it('emits regionToggle on path click', () => {
    const regions = [fixtures.chestRegion];
    const spy = jasmine.createSpy('regionToggle');
    const fixture = TestBed.createComponent(BodyMapCanvas);
    fixture.componentRef.setInput('regions', regions);
    fixture.componentInstance.regionToggle.subscribe(spy);

    const path = fixture.nativeElement.querySelector('path.chest');
    path.dispatchEvent(new Event('click'));

    expect(spy).toHaveBeenCalledWith('CHEST');
  });

  it('applies is-selected class when region id is selected', () => {
    // assert classList contains 'is-selected' after input change
  });

  it('renders aria-pressed="true" on selected region', () => { /* a11y gate */ });
});
```

### 6.4 Service/Guard Tests

- `ApiHttpClient.get` unwraps envelope and surfaces `ApiError` on 4xx/5xx.
- `ErrorInterceptor` maps backend `errors[]` codes to typed errors (esp. `NETWORK_REQUIRED`).
- `OnboardingGuard` redirects to `/onboarding` when `hasProfile()` is false.

---

## 7. CI Integration (`ci-web.yml`)

```bash
npm ci
ng lint
ng build --configuration production
ng test --no-watch --browsers=ChromeHeadless --code-coverage
```

- Runs on every PR touching `web/**`; build artifacts published as CI cache for e2e stage (Playwright e2e optional, tracked separately).

---

## 8. Approved Decisions & Open Decisions

**Approved (PHASE 3 gate):**
1. State: **NgRx `signalStore`** (Signals-first) across all feature stores.
2. Prefetch: **Explore route eagerly prefetched** on landing.

**Open:**
1. (none blocking) — theme (Phase 1) and vector asset source remain tracked in design spec.
