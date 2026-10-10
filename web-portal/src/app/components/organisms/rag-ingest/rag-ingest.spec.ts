import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Subject } from 'rxjs';

import { RagIngestRequest, RagIngestResponse } from '../../../core/models/rag.model';
import { RagService } from '../../../core/services/rag.service';
import { BODY_ZONE_OPTIONS, RagIngest } from './rag-ingest';

describe('RagIngest', () => {
  let fixture: ComponentFixture<RagIngest>;
  let component: RagIngest;
  let ingestSubject: Subject<RagIngestResponse>;
  let ragService: { ingest: ReturnType<typeof vi.fn> };
  let infoSpy: ReturnType<typeof vi.spyOn>;
  let errorSpy: ReturnType<typeof vi.spyOn>;

  const titleText = 'Hip mobility basics';
  const contentText = 'Deep squat holds improve hip range of motion.';

  beforeEach(async () => {
    ingestSubject = new Subject<RagIngestResponse>();
    ragService = { ingest: vi.fn(() => ingestSubject.asObservable()) };
    infoSpy = vi.spyOn(console, 'info').mockImplementation(() => undefined);
    errorSpy = vi.spyOn(console, 'error').mockImplementation(() => undefined);

    await TestBed.configureTestingModule({
      imports: [RagIngest],
      providers: [{ provide: RagService, useValue: ragService }],
    }).compileComponents();

    fixture = TestBed.createComponent(RagIngest);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  function fillValidForm(): void {
    component.title.set(titleText);
    component.content.set(contentText);
    component.bodyZone.set('Legs');
    fixture.detectChanges();
  }

  it('loads with empty title/content, default body zone and no result panel', () => {
    expect(component.title()).toBe('');
    expect(component.content()).toBe('');
    expect(component.bodyZone()).toBe('Legs');
    expect(component.hasResult()).toBe(false);
    expect(fixture.nativeElement.textContent).not.toContain('Ingested');
  });

  it('exposes every body zone option in the select', () => {
    const options = fixture.nativeElement.querySelectorAll('select option');
    expect(options.length).toBe(BODY_ZONE_OPTIONS.length);
    expect(fixture.nativeElement.textContent).toContain('Chest');
  });

  it('advertises the automatic test-user link', () => {
    expect(fixture.nativeElement.textContent).toContain('#1');
  });

  it('binds the title input reactively', () => {
    const input = fixture.nativeElement.querySelector('.rag-ingest__input') as HTMLInputElement;
    input.value = titleText;
    input.dispatchEvent(new Event('input'));
    fixture.detectChanges();

    expect(component.title()).toBe(titleText);
  });

  it('binds the content textarea reactively', () => {
    const textarea = fixture.nativeElement.querySelector('textarea') as HTMLTextAreaElement;
    textarea.value = contentText;
    textarea.dispatchEvent(new Event('input'));
    fixture.detectChanges();

    expect(component.content()).toBe(contentText);
  });

  it('binds the body zone select reactively', () => {
    const select = fixture.nativeElement.querySelector('select') as HTMLSelectElement;
    select.value = 'Core';
    select.dispatchEvent(new Event('change'));
    fixture.detectChanges();

    expect(component.bodyZone()).toBe('Core');
  });

  it('disables submission while the form is incomplete', () => {
    const submit = fixture.nativeElement.querySelector('.rag-ingest__button--submit') as HTMLButtonElement;
    expect(component.canSubmit()).toBe(false);
    expect(submit.disabled).toBe(true);
  });

  it('rejects an empty submit with an error state and a [RAG-ERROR]: log', () => {
    component.onSubmit();
    fixture.detectChanges();

    expect(component.error()).toBe('Title, Content and Body Zone are required.');
    expect(ragService.ingest).not.toHaveBeenCalled();
    expect(errorSpy).toHaveBeenCalledWith(
      expect.stringContaining('[RAG-ERROR]:'),
      expect.objectContaining({ hasTitle: false }),
    );
    expect(fixture.nativeElement.textContent).toContain('Title, Content and Body Zone are required.');
  });

  it('shows a loading state and disables submission while ingesting', () => {
    fillValidForm();
    component.onSubmit();
    fixture.detectChanges();

    expect(component.loading()).toBe(true);
    expect(fixture.nativeElement.textContent).toContain('Embedding');
    const submit = fixture.nativeElement.querySelector('.rag-ingest__button--submit') as HTMLButtonElement;
    expect(submit.disabled).toBe(true);
  });

  it('posts the PascalCase payload and renders the success panel with a [RAG-INFO]: log', () => {
    fillValidForm();
    component.onSubmit();
    fixture.detectChanges();

    const payload: RagIngestRequest = ragService.ingest.mock.calls[0][0];
    expect(payload).toEqual({ Title: titleText, Content: contentText, BodyZone: 'Legs' });

    ingestSubject.next({ Id: 'doc-123', UserId: 1, Message: 'Document ingested successfully.' });
    ingestSubject.complete();
    fixture.detectChanges();

    expect(component.loading()).toBe(false);
    expect(component.hasResult()).toBe(true);
    expect(fixture.nativeElement.textContent).toContain('Document ingested successfully.');
    expect(fixture.nativeElement.textContent).toContain('doc-123');
    expect(infoSpy).toHaveBeenCalledWith(
      expect.stringContaining('[RAG-INFO]:'),
      expect.objectContaining({ documentId: 'doc-123', userId: 1 }),
    );
  });

  it('renders an error state with a [RAG-ERROR]: log when ingestion fails', () => {
    fillValidForm();
    component.onSubmit();
    fixture.detectChanges();

    ingestSubject.error(new Error('network down'));
    fixture.detectChanges();

    expect(component.loading()).toBe(false);
    expect(component.error()).toBe('Could not ingest the document.');
    expect(errorSpy).toHaveBeenCalledWith(
      expect.stringContaining('[RAG-ERROR]:'),
      expect.any(Error),
    );
    expect(fixture.nativeElement.textContent).toContain('Could not ingest the document.');
  });

  it('ignores duplicate submits while loading', () => {
    fillValidForm();
    component.onSubmit();
    component.onSubmit();
    expect(ragService.ingest).toHaveBeenCalledTimes(1);
  });

  it('reset restores defaults and clears the panels', () => {
    fillValidForm();
    component.onSubmit();
    ingestSubject.next({ Id: 'doc-1', UserId: 1, Message: 'ok' });
    ingestSubject.complete();
    fixture.detectChanges();

    component.onReset();
    fixture.detectChanges();

    expect(component.title()).toBe('');
    expect(component.content()).toBe('');
    expect(component.bodyZone()).toBe('Legs');
    expect(component.result()).toBeNull();
    expect(component.hasResult()).toBe(false);
    expect(fixture.nativeElement.textContent).not.toContain('Ingested');
  });

  it('clicking Ingest Document submits the form', () => {
    fillValidForm();
    const submit = fixture.nativeElement.querySelector('.rag-ingest__button--submit') as HTMLButtonElement;
    submit.click();
    fixture.detectChanges();

    expect(ragService.ingest).toHaveBeenCalled();
  });
});
