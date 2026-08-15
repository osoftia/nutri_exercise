import { Component } from '@angular/core';
import { RouterLink, RouterLinkActive } from '@angular/router';
import { Icon, IconName } from '../../atoms/icon/icon';

interface NavItem {
  label: string;
  icon: IconName;
  link: string;
}

@Component({
  selector: 'app-admin-sidebar',
  imports: [RouterLink, RouterLinkActive, Icon],
  templateUrl: './admin-sidebar.html',
  styleUrl: './admin-sidebar.scss',
})
export class AdminSidebar {
  readonly navItems: NavItem[] = [
    { label: 'Dashboard', icon: 'dashboard', link: '/admin-dashboard' },
    { label: 'History', icon: 'trend-up', link: '/history' },
    { label: 'Routines', icon: 'workout', link: '/admin-dashboard' },
    { label: 'Nutrition', icon: 'nutrition', link: '/admin-dashboard' },
    { label: 'Schedule', icon: 'schedule', link: '/admin-dashboard' },
    { label: 'Profile', icon: 'profile', link: '/admin-dashboard' },
  ];
}
