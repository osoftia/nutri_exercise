import { Component } from '@angular/core';
import { RouterLink, RouterLinkActive } from '@angular/router';
import { Icon, IconName } from '../../atoms/icon/icon';
import { ThemeSwitcher } from '../../atoms/theme-switcher/theme-switcher';

interface NavItem {
  label: string;
  icon: IconName;
  link: string;
}

@Component({
  selector: 'app-admin-sidebar',
  imports: [RouterLink, RouterLinkActive, Icon, ThemeSwitcher],
  templateUrl: './admin-sidebar.html',
  styleUrl: './admin-sidebar.scss',
})
export class AdminSidebar {
  readonly navItems: NavItem[] = [
    { label: 'History', icon: 'history', link: '/history' },
    { label: 'Analytics', icon: 'analytics', link: '/analytics' },
    { label: 'Routines', icon: 'workout', link: '/routine-board' },
    { label: 'Nutrition', icon: 'nutrition', link: '/history' },
    { label: 'Schedule', icon: 'schedule', link: '/history' },
    { label: 'Profile', icon: 'profile', link: '/history' },
    { label: 'Health AI', icon: 'nutrition', link: '/health-ai' },
  ];
}
