import { describe, it, expect, beforeEach, vi } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { Subject } from 'rxjs';

import { DatabaseService } from '../services/database.service';
import { mockDbTables, mockRowsByTable, mockSemanticSearch } from '../mocks/mock-analytics.data';
import { DbTable, DbTableRow } from '../models/analytics.model';
import { VectorInspectorStore } from './vector-inspector.store';

describe('VectorInspectorStore', () => {
  let tablesSubject: Subject<DbTable[]>;
  let rowsSubject: Subject<DbTableRow[]>;
  let searchSubject: Subject<ReturnType<typeof mockSemanticSearch>>;
  let databaseService: {
    getTables: ReturnType<typeof vi.fn>;
    getTableRows: ReturnType<typeof vi.fn>;
    searchVectors: ReturnType<typeof vi.fn>;
  };
  let store: VectorInspectorStore;

  beforeEach(() => {
    tablesSubject = new Subject<DbTable[]>();
    rowsSubject = new Subject<DbTableRow[]>();
    searchSubject = new Subject<ReturnType<typeof mockSemanticSearch>>();
    databaseService = {
      getTables: vi.fn(() => tablesSubject.asObservable()),
      getTableRows: vi.fn(() => rowsSubject.asObservable()),
      searchVectors: vi.fn(() => searchSubject.asObservable()),
    };

    TestBed.configureTestingModule({
      providers: [{ provide: DatabaseService, useValue: databaseService }],
    });

    store = TestBed.inject(VectorInspectorStore);
  });

  it('loads the database tables', () => {
    store.loadTables();
    expect(store.loading()).toBe(true);

    tablesSubject.next(mockDbTables);
    tablesSubject.complete();

    expect(store.loading()).toBe(false);
    expect(store.tables()).toEqual(mockDbTables);
    expect(store.error()).toBeNull();
  });

  it('surfaces an error when loading tables fails', () => {
    store.loadTables();
    tablesSubject.error(new Error('boom'));

    expect(store.error()).toBe('Could not load database tables.');
    expect(store.loading()).toBe(false);
    expect(store.tables()).toHaveLength(0);
  });

  it('retry reloads the tables after an error', () => {
    store.loadTables();
    tablesSubject.error(new Error('boom'));

    store.retry();

    expect(databaseService.getTables).toHaveBeenCalledTimes(2);
  });

  it('selecting a table sets it and fetches its rows', () => {
    store.loadTables();
    tablesSubject.next(mockDbTables);
    tablesSubject.complete();

    store.selectTable('routine_embeddings');

    expect(databaseService.getTableRows).toHaveBeenCalledWith('routine_embeddings');
    expect(store.selectedTable()?.name).toBe('routine_embeddings');
    expect(store.vectorColumns()).toEqual([{ name: 'embedding', dimensions: 1536 }]);
  });

  it('stores the rows of the selected table', () => {
    store.loadTables();
    tablesSubject.next(mockDbTables);
    tablesSubject.complete();

    store.selectTable('routine_embeddings');
    rowsSubject.next(mockRowsByTable['routine_embeddings']);
    rowsSubject.complete();

    expect(store.rows().length).toBe(mockRowsByTable['routine_embeddings'].length);
  });

  it('runs a semantic search with a query and stores the matches', () => {
    const matches = mockSemanticSearch('push day');
    store.loadTables();
    tablesSubject.next(mockDbTables);
    tablesSubject.complete();

    store.search('push day', 3);
    searchSubject.next(matches);
    searchSubject.complete();

    expect(databaseService.searchVectors).toHaveBeenCalledWith('push day', 3);
    expect(store.searchResults()).toEqual(matches);
  });

  it('clears the search results for an empty query', () => {
    store.search('   ', 5);

    expect(databaseService.searchVectors).not.toHaveBeenCalled();
    expect(store.searchResults()).toEqual([]);
  });

  it('reset clears all state', () => {
    store.loadTables();
    tablesSubject.next(mockDbTables);
    tablesSubject.complete();
    store.selectTable('routine_embeddings');
    rowsSubject.next(mockRowsByTable['routine_embeddings']);
    rowsSubject.complete();
    store.search('push', 3);
    searchSubject.next(mockSemanticSearch('push'));
    searchSubject.complete();

    store.reset();

    expect(store.tables()).toHaveLength(0);
    expect(store.selectedTable()).toBeNull();
    expect(store.rows()).toHaveLength(0);
    expect(store.searchResults()).toHaveLength(0);
    expect(store.error()).toBeNull();
  });
});