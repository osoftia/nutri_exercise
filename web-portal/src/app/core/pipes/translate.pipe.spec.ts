import '@angular/compiler';
import { DOCUMENT } from '@angular/common';
import { Injector, runInInjectionContext } from '@angular/core';
import { beforeEach, describe, expect, it } from 'vitest';
import { LocaleStore } from '../stores/locale.store';
import { TranslatePipe } from './translate.pipe';

describe('TranslatePipe', () => {
  beforeEach(() => localStorage.clear());

  it('reflects locale changes on subsequent translations', () => {
    const injector = Injector.create({
      providers: [{ provide: DOCUMENT, useValue: document }, LocaleStore, TranslatePipe],
    });
    const { pipe, locale } = runInInjectionContext(injector, () => ({
      pipe: injector.get(TranslatePipe),
      locale: injector.get(LocaleStore),
    }));

    expect(pipe.transform('nav.settings')).toBe('Settings');
    locale.setLocale('es');
    expect(pipe.transform('nav.settings')).toBe('Configuración');
  });
});
