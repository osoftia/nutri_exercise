import { Component, input } from '@angular/core';

export type IconName =
  | 'dashboard'
  | 'workout'
  | 'nutrition'
  | 'schedule'
  | 'profile'
  | 'search'
  | 'users'
  | 'trend-up'
  | 'trend-down'
  | 'logout';

@Component({
  selector: 'app-icon',
  imports: [],
  templateUrl: './icon.html',
  styleUrl: './icon.scss',
})
export class Icon {
  readonly name = input<IconName>('dashboard');
}
