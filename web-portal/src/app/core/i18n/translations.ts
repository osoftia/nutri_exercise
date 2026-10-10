import { AppLocale } from '../stores/locale.store';
import { EN_TRANSLATIONS } from './translations.en';
import { ES_TRANSLATIONS } from './translations.es';

export const translations: Record<AppLocale, Record<string, string>> = {
  en: EN_TRANSLATIONS,
  es: ES_TRANSLATIONS,
};
