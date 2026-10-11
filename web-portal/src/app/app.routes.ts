import { Routes } from '@angular/router';
import { MainLayout } from './components/organisms/main-layout/main-layout';
import { DashboardHome } from './pages/admin-dashboard/dashboard-home/dashboard-home';

export const routes: Routes = [
  {
    path: '',
    component: MainLayout,
    children: [
      { path: 'history', component: DashboardHome },
      {
        path: 'analytics',
        loadComponent: () => import('./pages/analytics/analytics.page').then((m) => m.AnalyticsPage),
      },
      {
        path: 'clinical-evolution',
        loadComponent: () =>
          import('./pages/clinical-evolution/clinical-evolution.page').then(
            (m) => m.ClinicalEvolutionPage,
          ),
      },
      {
        path: 'rag-lab',
        loadComponent: () => import('./components/organisms/prompt-lab/prompt-lab').then((m) => m.PromptLab),
      },
      {
        path: 'rag-ingest',
        loadComponent: () => import('./components/organisms/rag-ingest/rag-ingest').then((m) => m.RagIngest),
      },
      {
        path: 'routine-board',
        loadComponent: () => import('./components/organisms/routine-board/routine-board').then((m) => m.RoutineBoard),
      },
      {
        path: 'health-ai',
        loadComponent: () => import('./pages/health-ai/health-ai.page').then((m) => m.HealthAiPage),
      },
      {
        path: 'settings',
        loadComponent: () => import('./pages/settings/settings.page').then((m) => m.SettingsPage),
      },
      { path: 'admin-dashboard', redirectTo: '/history', pathMatch: 'full' },
      { path: '', redirectTo: 'history', pathMatch: 'full' },
    ],
  },
];
