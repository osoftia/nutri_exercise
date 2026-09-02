import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { firstValueFrom } from 'rxjs';

import { mockDbTables, mockRowsByTable } from '../mocks/mock-analytics.data';
import { DatabaseService } from './database.service';

describe('DatabaseService', () => {
  let service: DatabaseService;

  beforeEach(() => {
    TestBed.configureTestingModule({ providers: [DatabaseService] });
    service = TestBed.inject(DatabaseService);
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('lists the database tables with their row counts', async () => {
    vi.useFakeTimers();
    const result = firstValueFrom(service.getTables());
    await vi.advanceTimersByTimeAsync(400);

    const tables = await result;
    expect(tables).toEqual(mockDbTables);
    expect(tables.some((table) => table.name === 'routine_embeddings')).toBe(true);
    const embeddings = tables.find((table) => table.name === 'routine_embeddings');
    expect(embeddings?.vectorColumns[0].dimensions).toBe(1536);
  });

  it('returns the rows of a table', async () => {
    vi.useFakeTimers();
    const result = firstValueFrom(service.getTableRows('routine_embeddings'));
    await vi.advanceTimersByTimeAsync(400);

    const rows = await result;
    expect(rows).toEqual(mockRowsByTable['routine_embeddings']);
    expect(rows.length).toBeGreaterThan(0);
  });

  it('returns an empty list for an unknown table', async () => {
    vi.useFakeTimers();
    const result = firstValueFrom(service.getTableRows('missing'));
    await vi.advanceTimersByTimeAsync(400);

    expect(await result).toEqual([]);
  });

  it('returns semantic search matches ordered by similarity', async () => {
    vi.useFakeTimers();
    const result = firstValueFrom(service.searchVectors('push day', 3));
    await vi.advanceTimersByTimeAsync(400);

    const matches = await result;
    expect(matches).toHaveLength(3);
    expect(matches[0].score).toBeGreaterThanOrEqual(matches[1].score);
    expect(matches[1].score).toBeGreaterThanOrEqual(matches[2].score);
  });
});