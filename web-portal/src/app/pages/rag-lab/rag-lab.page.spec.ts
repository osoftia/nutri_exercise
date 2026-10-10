import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Subject } from 'rxjs';

import { MOCK_PROMPT_LAB_RESULT } from '../../core/mocks/mock-prompt-lab.data';
import { PromptLabResult } from '../../core/models/prompt-lab.model';
import { RagService } from '../../core/services/rag.service';
import { RagLabStore } from '../../core/stores/rag-lab.store';
import { RagLabPage } from './rag-lab.page';

describe('RagLabPage (Final RAG Lab Page Container)', () => {
  let fixture: ComponentFixture<RagLabPage>;
  let store: RagLabStore;
  let resultSubject: Subject<PromptLabResult>;
  let ragService: { runPromptLab: ReturnType<typeof vi.fn> };

  function statusText(): string {
    return (
      fixture.nativeElement.querySelector('.rag-lab-page__status')?.textContent ?? ''
    );
  }

  beforeEach(async () => {
    resultSubject = new Subject<PromptLabResult>();
    ragService = { runPromptLab: vi.fn(() => resultSubject.asObservable()) };

    await TestBed.configureTestingModule({
      imports: [RagLabPage],
      providers: [{ provide: RagService, useValue: ragService }],
    }).compileComponents();

    store = TestBed.inject(RagLabStore);
    fixture = TestBed.createComponent(RagLabPage);
    fixture.detectChanges();
  });

  it('renders the brutalist page header with title and subtitle', () => {
    const text = fixture.nativeElement.textContent as string;
    expect(text).toContain('Retrieval-Augmented Generation');
    expect(fixture.nativeElement.querySelector('.rag-lab-page__title')?.textContent).toContain(
      'RAG Lab',
    );
    expect(text).toContain('pgvector');
  });

  it('integrates the controls, results, and audit-log components', () => {
    expect(fixture.nativeElement.querySelector('app-rag-lab-controls')).not.toBeNull();
    expect(fixture.nativeElement.querySelector('app-rag-lab-results')).not.toBeNull();
    expect(fixture.nativeElement.querySelector('app-audit-log')).not.toBeNull();
  });

  it('reports an idle status before any query runs', () => {
    expect(store.hasResults()).toBe(false);
    expect(statusText()).toContain('Idle');
  });

  it('reports the executing status while the store is loading', () => {
    store.setQuery('Recovery routine after intense dance rehearsal');
    fixture.detectChanges();
    store.executeQuery();
    fixture.detectChanges();

    expect(store.isLoading()).toBe(true);
    expect(statusText()).toContain('Executing semantic search');
  });

  it('summarizes match count, top score, and latency once results land', () => {
    store.results.set(MOCK_PROMPT_LAB_RESULT);
    fixture.detectChanges();

    expect(statusText()).toContain('3 matches');
    expect(statusText()).toContain('top 94.0%');
    expect(statusText()).toContain('1842ms');
  });

  it('reports no scored match when results carry zero sources', () => {
    store.results.set({ ...MOCK_PROMPT_LAB_RESULT, matchedSources: [] });
    fixture.detectChanges();

    expect(statusText()).toContain('0 matches');
    expect(statusText()).toContain('no scored match');
  });
});
