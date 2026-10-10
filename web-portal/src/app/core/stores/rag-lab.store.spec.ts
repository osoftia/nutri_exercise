import '@angular/compiler';
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { Injector, runInInjectionContext } from '@angular/core';
import { Subject } from 'rxjs';

import { MOCK_PROMPT_LAB_RESULT } from '../mocks/mock-prompt-lab.data';
import { PromptLabResult } from '../models/prompt-lab.model';
import { RagService } from '../services/rag.service';
import { AuditLogStore } from './audit-log.store';
import { RagLabStore } from './rag-lab.store';

describe('RagLabStore (Step 2 — Reactive Store)', () => {
  let ragService: { runPromptLab: ReturnType<typeof vi.fn> };
  let auditLog: AuditLogStore;
  let store: RagLabStore;

  beforeEach(() => {
    ragService = { runPromptLab: vi.fn() };

    const injector = Injector.create({
      providers: [
        RagLabStore,
        AuditLogStore,
        { provide: RagService, useValue: ragService },
      ],
    });
    runInInjectionContext(injector, () => {
      store = injector.get(RagLabStore);
      auditLog = injector.get(AuditLogStore);
    });
  });

  it('initializes input signals with clean defaults', () => {
    expect(store.systemPrompt()).toBe('');
    expect(store.temperature()).toBe(0.7);
    expect(store.similarityThreshold()).toBe(0.8);
    expect(store.query()).toBe('');
  });

  it('initializes request state as idle with no results or error', () => {
    expect(store.isLoading()).toBe(false);
    expect(store.results()).toBeNull();
    expect(store.error()).toBeNull();
    expect(store.hasResults()).toBe(false);
    expect(store.latencyMs()).toBeNull();
    expect(store.tokensPerSecond()).toBeNull();
    expect(store.topMatchScore()).toBeNull();
  });

  it('updates writable input signals via setters', () => {
    store.setSystemPrompt('You are a sports nutrition expert');
    store.setTemperature(1.2);
    store.setSimilarityThreshold(0.9);
    store.setQuery('Recovery routine?');

    expect(store.systemPrompt()).toBe('You are a sports nutrition expert');
    expect(store.temperature()).toBe(1.2);
    expect(store.similarityThreshold()).toBe(0.9);
    expect(store.query()).toBe('Recovery routine?');
  });

  it('ignores blank queries without calling the service', () => {
    store.setQuery('   ');
    store.executeQuery();

    expect(ragService.runPromptLab).not.toHaveBeenCalled();
    expect(store.isLoading()).toBe(false);
  });

  it('ignores re-entrant calls while a query is in flight', () => {
    const pending$ = new Subject<PromptLabResult>();
    ragService.runPromptLab.mockReturnValue(pending$);
    store.setQuery('Recovery routine?');

    store.executeQuery();
    store.executeQuery();

    expect(ragService.runPromptLab).toHaveBeenCalledTimes(1);
    expect(store.isLoading()).toBe(true);
  });

  it('executeQuery() updates results and appends a success audit entry with telemetry', () => {
    const pending$ = new Subject<PromptLabResult>();
    ragService.runPromptLab.mockReturnValue(pending$);
    store.setQuery('Recovery routine?');
    store.setSystemPrompt('expert');
    store.setTemperature(0.7);
    store.setSimilarityThreshold(0.8);

    store.executeQuery();
    expect(store.isLoading()).toBe(true);
    expect(store.error()).toBeNull();

    pending$.next(MOCK_PROMPT_LAB_RESULT);
    pending$.complete();

    expect(store.isLoading()).toBe(false);
    expect(store.results()).toEqual(MOCK_PROMPT_LAB_RESULT);
    expect(store.hasResults()).toBe(true);
    expect(store.latencyMs()).toBe(1842);
    expect(store.tokensPerSecond()).toBe(38);
    expect(store.topMatchScore()).toBeCloseTo(0.94);

    expect(ragService.runPromptLab).toHaveBeenCalledWith({
      query: 'Recovery routine?',
      systemPrompt: 'expert',
      temperature: 0.7,
      similarityThreshold: 0.8,
    });
    expect(auditLog.count()).toBe(1);
    expect(auditLog.entries()[0]).toMatchObject({
      query: 'Recovery routine?',
      latencyMs: 1842,
      topMatchScore: 0.94,
      status: 'success',
    });
  });

  it('records null topMatchScore when the response has no matched sources', () => {
    const pending$ = new Subject<PromptLabResult>();
    ragService.runPromptLab.mockReturnValue(pending$);
    store.setQuery('q');

    store.executeQuery();
    pending$.next({ ...MOCK_PROMPT_LAB_RESULT, matchedSources: [] });
    pending$.complete();

    expect(store.topMatchScore()).toBeNull();
    expect(auditLog.entries()[0]).toMatchObject({
      topMatchScore: null,
      status: 'success',
    });
  });

  it('surfaces an error and appends an error audit entry on failure', () => {
    const pending$ = new Subject<PromptLabResult>();
    ragService.runPromptLab.mockReturnValue(pending$);
    store.setQuery('Recovery routine?');

    store.executeQuery();
    pending$.error(new Error('backend down'));

    expect(store.isLoading()).toBe(false);
    expect(store.error()).toBe('Could not execute the RAG query.');
    expect(store.results()).toBeNull();
    expect(auditLog.count()).toBe(1);
    expect(auditLog.entries()[0]).toMatchObject({
      query: 'Recovery routine?',
      latencyMs: null,
      topMatchScore: null,
      status: 'error',
    });
  });

  it('reset() restores every signal to its default', () => {
    const pending$ = new Subject<PromptLabResult>();
    ragService.runPromptLab.mockReturnValue(pending$);
    store.setQuery('q');
    store.executeQuery();
    pending$.next(MOCK_PROMPT_LAB_RESULT);
    pending$.complete();

    store.reset();

    expect(store.systemPrompt()).toBe('');
    expect(store.temperature()).toBe(0.7);
    expect(store.similarityThreshold()).toBe(0.8);
    expect(store.query()).toBe('');
    expect(store.isLoading()).toBe(false);
    expect(store.results()).toBeNull();
    expect(store.error()).toBeNull();
    expect(store.hasResults()).toBe(false);
  });
});
