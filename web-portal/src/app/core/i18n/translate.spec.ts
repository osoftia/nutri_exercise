import { describe, expect, it } from 'vitest';

import { translate } from './translate';

describe('translate', () => {
  it('resolves keys for each locale', () => {
    expect(translate('en', 'metrics.title')).toBe('Health Metrics Overview');
    expect(translate('es', 'metrics.title')).toBe('Resumen de métricas de salud');
  });

  it('falls back to the key when missing', () => {
    expect(translate('en', 'totally.unknown.key')).toBe('totally.unknown.key');
  });

  it('interpolates parameters', () => {
    expect(translate('en', 'history.routineCount', { count: 3 })).toBe('3 exercises');
  });
});
