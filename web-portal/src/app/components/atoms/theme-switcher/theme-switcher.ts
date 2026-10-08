import { Component, inject } from '@angular/core';
import { TranslatePipe } from '../../../core/pipes/translate.pipe';
import { ThemeStore } from '../../../core/stores/theme.store';

@Component({
  selector: 'app-theme-switcher',
  imports: [TranslatePipe],
  templateUrl: './theme-switcher.html',
  styleUrl: './theme-switcher.scss',
})
export class ThemeSwitcher {
  readonly store = inject(ThemeStore);
}
