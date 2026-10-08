import { Component, inject } from '@angular/core';
import { TranslatePipe } from '../../../core/pipes/translate.pipe';
import { AppLocale, LocaleStore } from '../../../core/stores/locale.store';

@Component({
  selector: 'app-language-switcher',
  imports: [TranslatePipe],
  templateUrl: './language-switcher.html',
  styleUrl: './language-switcher.scss',
})
export class LanguageSwitcher {
  readonly store = inject(LocaleStore);
  readonly locales: AppLocale[] = ['en', 'es'];

  setLocale(locale: AppLocale): void {
    this.store.setLocale(locale);
  }
}
