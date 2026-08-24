import { Component, inject } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { MatSelectModule } from '@angular/material/select';

import { VectorInspectorStore } from '../../../../core/stores/vector-inspector.store';

@Component({
  selector: 'app-vector-inspector',
  imports: [
    MatSelectModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    FormsModule,
  ],
  templateUrl: './vector-inspector.html',
  styleUrl: './vector-inspector.scss',
})
export class VectorInspector {
  readonly store = inject(VectorInspectorStore);
  protected readonly query = '';
  protected readonly searchK = 5;

  onTableChange(name: string): void {
    this.store.selectTable(name);
  }

  onSearch(): void {
    this.store.search(this.query, this.searchK);
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