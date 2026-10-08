import '@angular/compiler';
import { DOCUMENT } from '@angular/common';
import { Injector, runInInjectionContext } from '@angular/core';
import { beforeEach, describe, expect, it } from 'vitest';

import { ThemeStore } from './theme.store';

function setup(): ThemeStore {
  const injector = Injector.create({
    providers: [{ provide: DOCUMENT, useValue: document }, ThemeStore],
  });
  return runInInjectionContext(injector, () => injector.get(ThemeStore));
}

describe('ThemeStore', () => {
  beforeEach(() => {
    localStorage.clear();
    document.body.classList.remove('theme-editorial', 'theme-apple');
  });

  it('toggles between editorial and apple and updates the body class', () => {
    const store = setup();

    expect(store.theme()).toBe('editorial');
    store.toggleTheme();
    expect(store.theme()).toBe('apple');
    expect(document.body.classList.contains('theme-apple')).toBe(true);
    store.toggleTheme();
    expect(store.theme()).toBe('editorial');
    expect(document.body.classList.contains('theme-editorial')).toBe(true);
  });

  it('persists selected theme using the application storage key', () => {
    const store = setup();

    store.setTheme('apple');

    expect(localStorage.getItem('nutri_exercise_theme')).toBe('apple');
  });

  it('hydrates the saved theme and applies its class to the body', () => {
    localStorage.setItem('nutri_exercise_theme', 'apple');

    const store = setup();

    expect(store.theme()).toBe('apple');
    expect(document.body.classList.contains('theme-apple')).toBe(true);
    expect(document.body.classList.contains('theme-editorial')).toBe(false);
  });
});
