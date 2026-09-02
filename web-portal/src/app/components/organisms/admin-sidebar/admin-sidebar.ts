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
    { label: 'History', icon: 'history', link: '/history' },
    { label: 'Analytics', icon: 'analytics', link: '/analytics' },
    { label: 'Routines', icon: 'workout', link: '/history' },
    { label: 'Nutrition', icon: 'nutrition', link: '/history' },
    { label: 'Schedule', icon: 'schedule', link: '/history' },
    { label: 'Profile', icon: 'profile', link: '/history' },
  ];
}