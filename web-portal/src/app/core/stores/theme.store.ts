import { DOCUMENT } from '@angular/common';
import { computed, inject, Injectable, signal } from '@angular/core';

export type AppTheme = 'editorial' | 'apple';

const STORAGE_KEY = 'nutri_exercise_theme';

@Injectable({ providedIn: 'root' })
export class ThemeStore {
  private readonly document = inject(DOCUMENT);
  private readonly currentTheme = signal<AppTheme>(this.hydrateTheme());

  readonly theme = this.currentTheme.asReadonly();
  readonly isApple = computed(() => this.theme() === 'apple');

  constructor() {
    this.applyTheme(this.theme());
  }

  toggleTheme(): void {
    this.setTheme(this.theme() === 'editorial' ? 'apple' : 'editorial');
  }

  setTheme(theme: AppTheme): void {
    this.currentTheme.set(theme);
    this.applyTheme(theme);
    try {
      this.document.defaultView?.localStorage.setItem(STORAGE_KEY, theme);
    } catch {
      // Storage can be unavailable in privacy-restricted or server contexts.
    }
  }

  private hydrateTheme(): AppTheme {
    try {
      return this.document.defaultView?.localStorage.getItem(STORAGE_KEY) === 'apple'
        ? 'apple'
        : 'editorial';
    } catch {
      return 'editorial';
    }
  }

  private applyTheme(theme: AppTheme): void {
    const body = this.document.body;
    body?.classList.toggle('theme-editorial', theme === 'editorial');
    body?.classList.toggle('theme-apple', theme === 'apple');
  }
}
