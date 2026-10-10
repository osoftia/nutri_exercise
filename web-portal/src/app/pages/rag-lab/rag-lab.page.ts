import { Component, computed, inject } from '@angular/core';

import { AuditLog } from '../../components/organisms/audit-log/audit-log';
import { RagLabControls } from '../../components/organisms/rag-lab-controls/rag-lab-controls';
import { RagLabResults } from '../../components/organisms/rag-lab-results/rag-lab-results';
import { RagLabStore } from '../../core/stores/rag-lab.store';

/**
 * Final RAG Lab page container ("Editorial Tech" brutalist).
 *
 * Pure composition view: the header owns the page title/subtitle plus a
 * live status line derived from {@link RagLabStore}, while the controls
 * panel, semantic results, and traceability audit log own their own state.
 * No local state, no constructor injection.
 */
@Component({
  selector: 'app-rag-lab-page',
  imports: [RagLabControls, RagLabResults, AuditLog],
  templateUrl: './rag-lab.page.html',
  styleUrl: './rag-lab.page.scss',
})
export class RagLabPage {
  readonly store = inject(RagLabStore);

  readonly status = computed(() => {
    if (this.store.isLoading()) {
      return 'Executing semantic search…';
    }
    const results = this.store.results();
    if (!results) {
      return 'Idle — tune the controls and run a query';
    }
    const top = this.store.topMatchScore();
    const topLabel = top === null ? 'no scored match' : `top ${(top * 100).toFixed(1)}%`;
    return `${results.matchedSources.length} matches · ${topLabel} · ${results.latencyMs}ms`;
  });
}
