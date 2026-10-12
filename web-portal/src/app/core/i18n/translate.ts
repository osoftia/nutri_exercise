import { AppLocale } from '../stores/locale.store';
import { translations } from './translations';

export function translate(
  locale: AppLocale,
  key: string,
  params?: Record<string, string | number>,
): string {
  const text = translations[locale][key] ?? translations.en[key] ?? key;
  return params
    ? text.replace(/\{\{(\w+)\}\}/g, (_match, name: string) => String(params[name] ?? ''))
    : text;
}
