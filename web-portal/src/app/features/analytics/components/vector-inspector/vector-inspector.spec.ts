import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { Subject } from 'rxjs';

import { DatabaseService } from '../../../../core/services/database.service';
import { mockDbTables, mockRowsByTable } from '../../../../core/mocks/mock-analytics.data';
import { DbTable } from '../../../../core/models/analytics.model';
import { VectorInspectorStore } from '../../../../core/stores/vector-inspector.store';
import { VectorInspector } from './vector-inspector';

describe('VectorInspector', () => {
  let fixture: ComponentFixture<VectorInspector>;
  let store: VectorInspectorStore;
  let tablesSubject: Subject<DbTable[]>;
  let databaseService: { getTables: ReturnType<typeof vi.fn> };

  beforeEach(async () => {
    tablesSubject = new Subject<DbTable[]>();
    databaseService = { getTables: vi.fn(() => tablesSubject.asObservable()) };

    await TestBed.configureTestingModule({
      imports: [VectorInspector],
      providers: [{ provide: DatabaseService, useValue: databaseService }],
    }).compileComponents();

    store = TestBed.inject(VectorInspectorStore);
    fixture = TestBed.createComponent(VectorInspector);
    fixture.detectChanges();
  });

  it('lists the database tables with their row counts in the selector', () => {
    tablesSubject.next(mockDbTables);
    tablesSubject.complete();
    fixture.detectChanges();

    expect(store.tables().length).toBe(mockDbTables.length);
    expect(fixture.nativeElement.textContent).toContain('routine_embeddings');
    expect(fixture.nativeElement.textContent).toContain('24 rows');
  });

  it('shows the embedding dimensions as metadata', () => {
    tablesSubject.next(mockDbTables);
    tablesSubject.complete();
    fixture.detectChanges();

    store.selectTable('routine_embeddings');
    fixture.detectChanges();

    expect(fixture.nativeElement.textContent).toContain('embedding');
    expect(fixture.nativeElement.textContent).toContain('1536 dims');
  });

  it('renders the rows of the selected table', () => {
    tablesSubject.next(mockDbTables);
    tablesSubject.complete();
    fixture.detectChanges();

    store.selectTable('routine_embeddings');
    fixture.detectChanges();

    expect(store.rows().length).toBe(mockRowsByTable['routine_embeddings'].length);
    expect(fixture.nativeElement.querySelectorAll('tbody tr').length).toBe(
      mockRowsByTable['routine_embeddings'].length,
    );
  });

  it('shows an error state with a retry action when loading fails', () => {
    tablesSubject.error(new Error('boom'));
    fixture.detectChanges();

    const el = fixture.nativeElement as HTMLElement;
    expect(el.textContent).toContain('Could not load database tables.');
    expect(Array.from(el.querySelectorAll('button')).some((b) => b.textContent?.trim() === 'Retry')).toBe(
      true,
    );
  });

  it('runs a semantic search and shows the matches', () => {
    tablesSubject.next(mockDbTables);
    tablesSubject.complete();
    fixture.detectChanges();

    store.search('push day', 3);
    fixture.detectChanges();

    expect(fixture.nativeElement.textContent).toContain('Similarity');
    expect(store.searchResults().length).toBeGreaterThan(0);
  });
});