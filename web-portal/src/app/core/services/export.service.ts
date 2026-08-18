import { Service } from '@angular/core';

import { AiInteraction } from '../models/interaction.model';
import { buildDpoFileName, buildDpoJsonl } from '../utils/dpo-export.util';

@Service()
export class ExportService {
  downloadDpoDataset(interactions: AiInteraction[]): void {
    const content = buildDpoJsonl(interactions);
    if (content === '') {
      return;
    }
    const blob = new Blob([content], { type: 'application/x-ndjson' });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement('a');
    anchor.href = url;
    anchor.download = buildDpoFileName();
    document.body.appendChild(anchor);
    anchor.click();
    document.body.removeChild(anchor);
    URL.revokeObjectURL(url);
  }
}