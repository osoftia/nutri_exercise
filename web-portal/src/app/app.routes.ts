import { Routes } from '@angular/router';
import { DashboardHome } from './pages/admin-dashboard/dashboard-home/dashboard-home';

export const routes: Routes = [
  { path: 'history', component: DashboardHome },
  {
    path: 'analytics',
    loadComponent: () =>
      import('./features/analytics/pages/analytics/analytics.page').then(
        (m) => m.AnalyticsPage,
      ),
  },
  { path: 'admin-dashboard', redirectTo: '/history', pathMatch: 'full' },
  { path: '', redirectTo: '/history', pathMatch: 'full' },
];