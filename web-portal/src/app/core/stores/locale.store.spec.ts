import '@angular/compiler';
import { DOCUMENT } from '@angular/common';
import { Injector, runInInjectionContext } from '@angular/core';
import { beforeEach, describe, expect, it } from 'vitest';

import { LocaleStore } from './locale.store';

function setup(): LocaleStore {
  const injector = Injector.create({
    providers: [{ provide: DOCUMENT, useValue: document }, LocaleStore],
  });
  return runInInjectionContext(injector, () => injector.get(LocaleStore));
}

describe('LocaleStore', () => {
  beforeEach(() => localStorage.clear());

  it('toggles between English and Spanish', () => {
    const store = setup();

    expect(store.locale()).toBe('en');
    store.toggleLocale();
    expect(store.locale()).toBe('es');
    store.toggleLocale();
    expect(store.locale()).toBe('en');
  });

  it('persists the selected locale using the application storage key', () => {
    const store = setup();

    store.setLocale('es');

    expect(localStorage.getItem('nutri_exercise_locale')).toBe('es');
  });

  it('hydrates the previously saved locale', () => {
    localStorage.setItem('nutri_exercise_locale', 'es');

    expect(setup().locale()).toBe('es');
  });
});
