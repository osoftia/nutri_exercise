import { Component, signal } from '@angular/core';
import { RouterLink, RouterLinkActive } from '@angular/router';
import { Icon, IconName } from '../../atoms/icon/icon';
import { TranslatePipe } from '../../../core/pipes/translate.pipe';

interface NavItem {
  label: string;
  icon: IconName;
  link: string;
}

@Component({
  selector: 'app-admin-sidebar',
  imports: [RouterLink, RouterLinkActive, Icon, TranslatePipe],
  templateUrl: './admin-sidebar.html',
  styleUrl: './admin-sidebar.scss',
})
export class AdminSidebar {
  readonly isCollapsed = signal(false);

  readonly navItems: NavItem[] = [
    { label: 'nav.history', icon: 'history', link: '/history' },
    { label: 'nav.analytics', icon: 'analytics', link: '/analytics' },
    {
      label: 'nav.clinicalEvolution',
      icon: 'trend-up',
      link: '/clinical-evolution',
    },
    {
      label: 'nav.healthMetrics',
      icon: 'dashboard',
      link: '/health-metrics',
    },
    { label: 'nav.routines', icon: 'workout', link: '/routine-board' },
    { label: 'nav.nutrition', icon: 'nutrition', link: '/history' },
    { label: 'nav.schedule', icon: 'schedule', link: '/history' },
    { label: 'nav.profile', icon: 'profile', link: '/history' },
    { label: 'nav.healthAi', icon: 'nutrition', link: '/health-ai' },
    { label: 'nav.settings', icon: 'settings', link: '/settings' },
  ];

  toggleCollapsed(): void {
    this.isCollapsed.update((collapsed) => !collapsed);
  }
}
