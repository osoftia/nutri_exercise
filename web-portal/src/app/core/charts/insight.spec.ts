import { describe, expect, it } from 'vitest';

import { buildInsightRows, wrapText } from './insight';

describe('wrapText', () => {
  it('wraps long text on word boundaries', () => {
    expect(wrapText('one two three four', 7)).toEqual(['one two', 'three', 'four']);
  });

  it('keeps short text on a single line', () => {
    expect(wrapText('short', 20)).toEqual(['short']);
  });
});

describe('buildInsightRows', () => {
  it('returns no rows without an insight', () => {
    expect(buildInsightRows(undefined, 'en')).toEqual([]);
  });

  it('labels and orders risk, warning and advice', () => {
    const rows = buildInsightRows({ risk: 'high', warning: 'watch', advice: 'rest now' }, 'en');
    expect(rows).toEqual([
      { kind: 'risk', text: 'Risk: high' },
      { kind: 'warning', text: 'Warning: watch' },
      { kind: 'advice', text: 'Advice: rest now' },
    ]);
  });

  it('localizes the labels', () => {
    const rows = buildInsightRows({ warning: 'elevado' }, 'es');
    expect(rows[0]).toEqual({ kind: 'warning', text: 'Advertencia: elevado' });
  });
});
