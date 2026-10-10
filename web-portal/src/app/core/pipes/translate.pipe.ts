import { Pipe, PipeTransform, inject } from '@angular/core';
import { LocaleStore } from '../stores/locale.store';
import { translations } from '../i18n/translations';

@Pipe({ name: 'translate', pure: false, standalone: true })
export class TranslatePipe implements PipeTransform {
  private readonly localeStore = inject(LocaleStore);

  transform(value: unknown, params?: Record<string, string | number>): string {
    const locale = this.localeStore.locale();
    const key = String(value ?? '');
    const count = /^(\d+) (exercises|meals)$/.exec(key);
    const lookup = count
      ? count[2] === 'exercises' ? 'history.routineCount' : 'history.mealCount'
      : key;
    const values = count ? { count: count[1] } : params;
    const text = translations[locale][lookup] ?? translations.en[lookup] ?? key;
    return values
      ? text.replace(/\{\{(\w+)\}\}/g, (_match, name: string) => String(values[name] ?? ''))
      : text;
  }
}
