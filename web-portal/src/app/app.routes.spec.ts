import { describe, it, expect, beforeEach } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { Router, provideRouter } from '@angular/router';

import { routes } from './app.routes';
import { DashboardHome } from './pages/admin-dashboard/dashboard-home/dashboard-home';

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
    expect(router.routerState.root.firstChild?.component).toBe(DashboardHome);
  });

  it('redirects the root path to /history', async () => {
    await router.navigateByUrl('/');

    expect(router.url).toBe('/history');
  });

  it('redirects the legacy /admin-dashboard path to /history', async () => {
    await router.navigateByUrl('/admin-dashboard');

    expect(router.url).toBe('/history');
  });
});