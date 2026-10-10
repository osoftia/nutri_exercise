import { Service, inject } from '@angular/core';
import { Observable } from 'rxjs';

import { PromptLabRequest, PromptLabResult } from '../models/prompt-lab.model';
import { RagService } from './rag.service';

/**
 * Facade used by the Prompt Lab store. Delegates to {@link RagService},
 * which talks to the .NET 8 RAG backend (or local mocks in dev).
 */
@Service()
export class PromptLabService {
  private readonly rag = inject(RagService);

  runQuery(request: PromptLabRequest): Observable<PromptLabResult> {
    return this.rag.runPromptLab(request);
  }
}
