import { Pipe, PipeTransform, inject } from '@angular/core';
import { LocaleStore } from '../stores/locale.store';
import { translations } from '../i18n/translations';

@Pipe({ name: 'translate', pure: false, standalone: true })
export class TranslatePipe implements PipeTransform {
  private readonly localeStore = inject(LocaleStore);

  transform(key: string): string {
    const locale = this.localeStore.locale();
    return translations[locale][key] ?? translations.en[key] ?? key;
  }
}
