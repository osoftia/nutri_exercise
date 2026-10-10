import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ComponentFixture, TestBed } from '@angular/core/testing';

import { AuditLogStore } from '../../../core/stores/audit-log.store';
import { AuditLog } from './audit-log';

const success = {
  query: 'Recovery routine?',
  systemPrompt: 'You are an expert',
  temperature: 0.7,
  similarityThreshold: 0.8,
  latencyMs: 1842,
  topMatchScore: 0.94,
  status: 'success' as const,
};

describe('AuditLog', () => {
  let fixture: ComponentFixture<AuditLog>;
  let store: AuditLogStore;

  beforeEach(async () => {
    await TestBed.configureTestingModule({ imports: [AuditLog] }).compileComponents();
    store = TestBed.inject(AuditLogStore);
    fixture = TestBed.createComponent(AuditLog);
    fixture.detectChanges();
  });

  it('starts collapsed with a zero count', () => {
    const text = fixture.nativeElement.textContent as string;
    expect(text).toContain('RAG Traceability');
    expect(text).toContain('0');
    expect(text).toContain('▸');
    expect(text).not.toContain('Clear Logs');
  });

  it('expands to reveal entries with monospace metrics', () => {
    store.log(success);
    store.toggle();
    fixture.detectChanges();

    const text = fixture.nativeElement.textContent as string;
    expect(text).toContain('▾');
    expect(text).toContain('Recovery routine?');
    expect(text).toContain('1842');
    expect(text).toContain('94.0%');
    expect(text).toContain('OK');
  });

  it('renders error entries with the ERR badge', () => {
    store.log({ ...success, status: 'error', latencyMs: null, topMatchScore: null });
    store.toggle();
    fixture.detectChanges();

    const text = fixture.nativeElement.textContent as string;
    expect(text).toContain('ERR');
    expect(text).toContain('n/a');
    expect(text).toContain('no match');
  });

  it('toggles via the header button and clears via Clear Logs', () => {    store.log(success);
    const header = fixture.nativeElement.querySelector('.audit-log__header') as HTMLButtonElement;
    header.click();
    fixture.detectChanges();
    expect(store.expanded()).toBe(true);

    const clear = Array.from(
      fixture.nativeElement.querySelectorAll('button'),
    ).find((b) => (b as HTMLButtonElement).textContent?.trim() === 'Clear Logs');
    (clear as HTMLButtonElement).click();
    fixture.detectChanges();

    expect(store.count()).toBe(0);
    expect(fixture.nativeElement.textContent).toContain('No queries recorded yet');
  });

  it('reveals the EXPORT AUDIT CSV action once expanded with entries', () => {
    store.log(success);
    store.toggle();
    fixture.detectChanges();

    expect(fixture.nativeElement.textContent).toContain('EXPORT AUDIT CSV');
  });

  it('triggers a CSV download via the EXPORT AUDIT CSV button', () => {
    const createObjectURL = vi.fn(() => 'blob:mock-url');
    URL.createObjectURL = createObjectURL as unknown as typeof URL.createObjectURL;
    const clickSpy = vi.fn();
    const originalClick = HTMLAnchorElement.prototype.click;
    HTMLAnchorElement.prototype.click = clickSpy as unknown as () => void;
    try {
      store.log(success);
      store.toggle();
      fixture.detectChanges();

      const exportButton = Array.from(
        fixture.nativeElement.querySelectorAll('button'),
      ).find((b) => (b as HTMLButtonElement).textContent?.trim() === 'EXPORT AUDIT CSV');
      expect(exportButton).toBeDefined();
      (exportButton as HTMLButtonElement).click();
      fixture.detectChanges();

      expect(createObjectURL).toHaveBeenCalledTimes(1);
      expect(clickSpy).toHaveBeenCalledTimes(1);
      expect(store.count()).toBe(1);
    } finally {
      HTMLAnchorElement.prototype.click = originalClick;
    }
  });
});
