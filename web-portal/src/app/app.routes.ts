import { Routes } from '@angular/router';
import { DashboardHome } from './pages/admin-dashboard/dashboard-home/dashboard-home';

export const routes: Routes = [
  {
    path: 'admin-dashboard',
    component: DashboardHome,
  },
  { path: '', redirectTo: '/admin-dashboard', pathMatch: 'full' },
];
