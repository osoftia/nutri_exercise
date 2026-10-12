import { describe, expect, it, vi } from 'vitest';

import { PdfLine, buildPdf, downloadPdf, paginateLines } from './pdf.util';

describe('paginateLines', () => {
  it('splits lines into fixed-size pages', () => {
    const lines: PdfLine[] = Array.from({ length: 10 }, (_, index) => ({ text: `line ${index}` }));
    const pages = paginateLines(lines, 4);
    expect(pages).toHaveLength(3);
    expect(pages[0].lines).toHaveLength(4);
    expect(pages[2].lines).toHaveLength(2);
  });

  it('always returns at least one page', () => {
    expect(paginateLines([], 4)).toEqual([{ lines: [] }]);
  });
});

describe('buildPdf', () => {
  it('produces a valid PDF envelope with an xref table', () => {
    const pdf = buildPdf(
      paginateLines([
        { text: 'Health RAG Report', bold: true, size: 18 },
        { text: 'Executive summary' },
      ]),
    );
    expect(pdf.startsWith('%PDF-1.4')).toBe(true);
    expect(pdf).toContain('1 0 obj');
    expect(pdf).toContain('/Type /Catalog');
    expect(pdf).toContain('xref');
    expect(pdf).toContain('trailer');
    expect(pdf.trimEnd().endsWith('%%EOF')).toBe(true);
  });

  it('escapes parentheses and strips non-ascii characters', () => {
    const pdf = buildPdf(paginateLines([{ text: 'Sodium (high) — 3.8 g/day' }]));
    expect(pdf).toContain('Sodium \\(high\\) - 3.8 g/day');
  });

  it('paginates multi-page content', () => {
    const lines: PdfLine[] = Array.from({ length: 60 }, (_, index) => ({ text: `row ${index}` }));
    const pdf = buildPdf(paginateLines(lines, 46));
    expect(pdf).toContain('/Count 2');
  });
});

describe('downloadPdf', () => {
  it('creates and clicks an anchor without throwing', () => {
    const originalCreate = URL.createObjectURL;
    const originalRevoke = URL.revokeObjectURL;
    const clickSpy = vi
      .spyOn(HTMLAnchorElement.prototype, 'click')
      .mockImplementation(() => undefined);
    Object.defineProperty(URL, 'createObjectURL', { configurable: true, value: () => 'blob:mock' });
    Object.defineProperty(URL, 'revokeObjectURL', { configurable: true, value: () => undefined });
    try {
      expect(() => downloadPdf('health_rag_report.pdf', [{ text: 'x' }])).not.toThrow();
      expect(clickSpy).toHaveBeenCalledTimes(1);
    } finally {
      clickSpy.mockRestore();
      Object.defineProperty(URL, 'createObjectURL', { configurable: true, value: originalCreate });
      Object.defineProperty(URL, 'revokeObjectURL', { configurable: true, value: originalRevoke });
    }
  });
});
