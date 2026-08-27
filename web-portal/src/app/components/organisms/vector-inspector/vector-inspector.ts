import { Component, OnInit, inject, signal } from '@angular/core';

import { VectorInspectorStore } from '../../../core/stores/vector-inspector.store';

@Component({
  selector: 'app-vector-inspector',
  imports: [],
  templateUrl: './vector-inspector.html',
  styleUrl: './vector-inspector.scss',
})
export class VectorInspector implements OnInit {
  readonly store = inject(VectorInspectorStore);
  readonly query = signal('');

  ngOnInit(): void {
    this.store.loadTables();
  }

  onTableChange(event: Event): void {
    const name = (event.target as HTMLSelectElement).value;
    if (name) {
      this.store.selectTable(name);
    }
  }

  onQueryInput(event: Event): void {
    this.query.set((event.target as HTMLInputElement).value);
  }

  onSearch(): void {
    this.store.search(this.query());
  }

  onRetry(): void {
    this.store.retry();
  }

  vectorPreview(value: unknown): string {
    if (!Array.isArray(value)) {
      return String(value ?? '');
    }
    return `${value.slice(0, 3).map((n) => n.toFixed(4)).join(', ')}, …`;
  }
}