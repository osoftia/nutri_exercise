import { Routes } from '@angular/router';
import { DashboardHome } from './pages/admin-dashboard/dashboard-home/dashboard-home';
import { InteractionHistory } from './pages/interaction-history/interaction-history';

export const routes: Routes = [
  {
    path: 'admin-dashboard',
    component: DashboardHome,
  },
  {
    path: 'history',
    component: InteractionHistory,
  },
  { path: '', redirectTo: '/admin-dashboard', pathMatch: 'full' },
];
