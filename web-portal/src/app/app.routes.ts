import { Routes } from '@angular/router';
import { DashboardHome } from './pages/admin-dashboard/dashboard-home/dashboard-home';

export const routes: Routes = [
  { path: 'history', component: DashboardHome },
  { path: 'admin-dashboard', redirectTo: '/history', pathMatch: 'full' },
  { path: '', redirectTo: '/history', pathMatch: 'full' },
];