import '@angular/compiler';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { Injector, runInInjectionContext } from '@angular/core';

import { AuditLogStore } from './audit-log.store';

const input = {
  query: 'Recovery routine?',
  systemPrompt: 'You are an expert',
  temperature: 0.7,
  similarityThreshold: 0.8,
  latencyMs: 1842,
  topMatchScore: 0.94,
  status: 'success' as const,
};

function setup(): AuditLogStore {
  const injector = Injector.create({ providers: [AuditLogStore] });
  return runInInjectionContext(injector, () => injector.get(AuditLogStore));
}

describe('AuditLogStore', () => {
  let store: AuditLogStore;

  beforeEach(() => {
    store = setup();
  });

  it('starts empty and collapsed', () => {
    expect(store.count()).toBe(0);
    expect(store.hasEntries()).toBe(false);
    expect(store.expanded()).toBe(false);
  });

  it('appends entries with generated id and timestamp', () => {
    const entry = store.log(input);
    expect(entry.id).toMatch(/^audit-/);
    expect(new Date(entry.timestamp).toString()).not.toBe('Invalid Date');
    expect(store.count()).toBe(1);
    expect(store.hasEntries()).toBe(true);
    expect(store.entries()[0].query).toBe('Recovery routine?');
  });

  it('toggles the expansion state', () => {
    store.toggle();
    expect(store.expanded()).toBe(true);
    store.toggle();
    expect(store.expanded()).toBe(false);
  });

  it('clears all entries but keeps the expansion state', () => {
    store.log(input);
    store.toggle();
    store.clear();
    expect(store.count()).toBe(0);
    expect(store.hasEntries()).toBe(false);
    expect(store.expanded()).toBe(true);
  });

  it('caps the log at the newest 100 entries', () => {
    for (let i = 0; i < 105; i++) {
      store.log({ ...input, query: `q${i}` });
    }
    expect(store.count()).toBe(100);
    expect(store.entries()[0].query).toBe('q5');
    expect(store.entries()[99].query).toBe('q104');
  });

  it('exportCsv downloads entries as a dated CSV file', async () => {
    const createObjectURL: ReturnType<typeof vi.fn> = vi.fn(() => 'blob:mock-url');
    URL.createObjectURL = createObjectURL as unknown as typeof URL.createObjectURL;
    const clickSpy = vi.fn();
    const originalClick = HTMLAnchorElement.prototype.click;
    HTMLAnchorElement.prototype.click = clickSpy as unknown as () => void;
    const appendChild = vi.spyOn(document.body, 'appendChild');
    try {
      store.log(input);
      store.log({ ...input, query: 'Say "hi", now', status: 'error', latencyMs: null, topMatchScore: null });

      store.exportCsv();

      expect(createObjectURL).toHaveBeenCalledTimes(1);
      const blob = createObjectURL.mock.calls[0][0] as Blob;
      expect(blob.type).toBe('text/csv;charset=utf-8;');
      const content = await blob.text();
      const lines = content.split('\n');
      expect(lines[0]).toBe(
        'Timestamp,Status,Query,Temperature,SimilarityThreshold,LatencyMs,TopMatchScore',
      );
      expect(lines).toHaveLength(3);
      expect(lines[1]).toContain('success');
      expect(lines[1]).toContain('1842');
      expect(lines[2]).toContain('"Say ""hi"", now"');
      expect(lines[2]).toContain('N/A');

      const anchor = appendChild.mock.calls[0][0] as HTMLAnchorElement;
      expect(anchor.getAttribute('href')).toBe('blob:mock-url');
      expect(anchor.getAttribute('download')).toMatch(/^rag_audit_log_\d{4}-\d{2}-\d{2}\.csv$/);
      expect(clickSpy).toHaveBeenCalledTimes(1);
      expect(document.body.contains(anchor)).toBe(false);
    } finally {
      HTMLAnchorElement.prototype.click = originalClick;
      appendChild.mockRestore();
    }
  });

  it('exportCsv does nothing when the log is empty', () => {
    const createObjectURL = vi.fn(() => 'blob:mock-url');
    URL.createObjectURL = createObjectURL as unknown as typeof URL.createObjectURL;
    const clickSpy = vi.fn();
    const originalClick = HTMLAnchorElement.prototype.click;
    HTMLAnchorElement.prototype.click = clickSpy as unknown as () => void;
    try {
      store.exportCsv();

      expect(createObjectURL).not.toHaveBeenCalled();
      expect(clickSpy).not.toHaveBeenCalled();
    } finally {
      HTMLAnchorElement.prototype.click = originalClick;
    }
  });
});
