import { Service, computed, signal } from '@angular/core';

import { AuditLogEntry, AuditLogInput, createAuditLogEntry } from '../models/audit-log.model';

const MAX_ENTRIES = 100;

@Service()
export class AuditLogStore {
  readonly entries = signal<AuditLogEntry[]>([]);
  readonly expanded = signal(false);

  readonly count = computed(() => this.entries().length);
  readonly hasEntries = computed(() => this.entries().length > 0);

  log(input: AuditLogInput): AuditLogEntry {
    const entry = createAuditLogEntry(input);
    this.entries.update((list) => [...list, entry].slice(-MAX_ENTRIES));
    return entry;
  }

  toggle(): void {
    this.expanded.update((value) => !value);
  }

  clear(): void {
    this.entries.set([]);
  }

  exportCsv(): void {
    const entries = this.entries();
    if (entries.length === 0) {
      return;
    }
    const headers = [
      'Timestamp',
      'Status',
      'Query',
      'Temperature',
      'SimilarityThreshold',
      'LatencyMs',
      'TopMatchScore',
    ];
    const rows = entries.map((e) => [
      e.timestamp,
      e.status,
      `"${e.query.replace(/"/g, '""')}"`, // Escapar comillas dobles
      e.temperature,
      e.similarityThreshold,
      e.latencyMs ?? 'N/A',
      e.topMatchScore ?? 'N/A',
    ]);
    const csvContent = [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.setAttribute('href', url);
    link.setAttribute('download', `rag_audit_log_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }
}
