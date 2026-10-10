import { describe, it, expect, beforeEach } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { Router, provideRouter } from '@angular/router';

import { routes } from './app.routes';
import { MainLayout } from './components/organisms/main-layout/main-layout';
import { DashboardHome } from './pages/admin-dashboard/dashboard-home/dashboard-home';

const layoutRoute = routes.find((route) => route.component === MainLayout);

describe('app routes', () => {
  let router: Router;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [DashboardHome],
      providers: [provideRouter(routes)],
    }).compileComponents();
    router = TestBed.inject(Router);
  });

  it('loads the dashboard home at /history', async () => {
    await router.navigateByUrl('/history');

    expect(router.url).toBe('/history');
    const shell = router.routerState.root.firstChild;
    expect(shell?.component).toBe(MainLayout);
    expect(shell?.firstChild?.component).toBe(DashboardHome);
  });

  it('redirects the root path to /history', async () => {
    await router.navigateByUrl('/');

    expect(router.url).toBe('/history');
  });

  it('redirects the legacy /admin-dashboard path to /history', async () => {
    await router.navigateByUrl('/admin-dashboard');

    expect(router.url).toBe('/history');
  });

  it('registers a lazy route for /analytics', async () => {
    await router.navigateByUrl('/analytics');

    const route = router.routerState.root.firstChild?.firstChild;
    expect(router.url).toBe('/analytics');
    expect(route?.routeConfig?.loadComponent).toBeDefined();
  });

  it('places all workspace pages under the sidebar layout', () => {
    const childPaths = layoutRoute?.children?.map((route) => route.path);
    expect(childPaths).toEqual(expect.arrayContaining([
      'history', 'analytics', 'routine-board', 'rag-lab', 'rag-ingest', 'health-ai', 'settings',
    ]));
    expect(layoutRoute?.component).toBe(MainLayout);
  });
});
