import { DOCUMENT } from '@angular/common';
import { inject, Injectable, signal } from '@angular/core';

export type AppLocale = 'en' | 'es';

const STORAGE_KEY = 'nutri_exercise_locale';

@Injectable({ providedIn: 'root' })
export class LocaleStore {
  private readonly document = inject(DOCUMENT);
  private readonly currentLocale = signal<AppLocale>(this.hydrateLocale());

  readonly locale = this.currentLocale.asReadonly();

  constructor() {
    this.applyLocale(this.locale());
  }

  toggleLocale(): void {
    this.setLocale(this.locale() === 'en' ? 'es' : 'en');
  }

  setLocale(locale: AppLocale): void {
    this.currentLocale.set(locale);
    this.applyLocale(locale);
    try {
      this.document.defaultView?.localStorage.setItem(STORAGE_KEY, locale);
    } catch {
      // Storage can be unavailable in privacy-restricted or server contexts.
    }
  }

  private hydrateLocale(): AppLocale {
    try {
      return this.document.defaultView?.localStorage.getItem(STORAGE_KEY) === 'es' ? 'es' : 'en';
    } catch {
      return 'en';
    }
  }

  private applyLocale(locale: AppLocale): void {
    this.document.documentElement.lang = locale;
  }
}
