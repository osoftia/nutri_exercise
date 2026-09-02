import { Service, computed, inject, signal } from '@angular/core';
import { finalize } from 'rxjs';

import { DbTable, DbTableRow, VectorMatch } from '../models/analytics.model';
import { DatabaseService } from '../services/database.service';

@Service()
export class VectorInspectorStore {
  private readonly databaseService = inject(DatabaseService);

  readonly tables = signal<DbTable[]>([]);
  readonly selectedTable = signal<DbTable | null>(null);
  readonly rows = signal<DbTableRow[]>([]);
  readonly searchResults = signal<VectorMatch[]>([]);
  readonly loading = signal(false);
  readonly error = signal<string | null>(null);

  readonly vectorColumns = computed(() => this.selectedTable()?.vectorColumns ?? []);

  loadTables(): void {
    if (this.loading()) {
      return;
    }
    this.loading.set(true);
    this.error.set(null);
    this.databaseService
      .getTables()
      .pipe(finalize(() => this.loading.set(false)))
      .subscribe({
        next: (tables) => this.tables.set(tables),
        error: () => this.error.set('Could not load database tables.'),
      });
  }

  selectTable(name: string): void {
    const table = this.tables().find((candidate) => candidate.name === name);
    if (!table) {
      return;
    }
    this.selectedTable.set(table);
    this.rows.set([]);
    this.loading.set(true);
    this.error.set(null);
    this.databaseService
      .getTableRows(name)
      .pipe(finalize(() => this.loading.set(false)))
      .subscribe({
        next: (rows) => this.rows.set(rows),
        error: () => this.error.set(`Could not load rows for "${name}".`),
      });
  }

  search(query: string, k = 5): void {
    if (query.trim() === '') {
      this.searchResults.set([]);
      return;
    }
    this.loading.set(true);
    this.error.set(null);
    this.databaseService
      .searchVectors(query, k)
      .pipe(finalize(() => this.loading.set(false)))
      .subscribe({
        next: (results) => this.searchResults.set(results),
        error: () => this.error.set('Could not run the semantic search.'),
      });
  }

  retry(): void {
    if (this.selectedTable()) {
      this.selectTable(this.selectedTable()!.name);
    } else {
      this.loadTables();
    }
  }

  reset(): void {
    this.tables.set([]);
    this.selectedTable.set(null);
    this.rows.set([]);
    this.searchResults.set([]);
    this.loading.set(false);
    this.error.set(null);
  }
}