import { Component, inject } from '@angular/core';
import { ThemeStore } from '../../../core/stores/theme.store';

@Component({
  selector: 'app-theme-switcher',
  templateUrl: './theme-switcher.html',
  styleUrl: './theme-switcher.scss',
})
export class ThemeSwitcher {
  readonly store = inject(ThemeStore);
}
