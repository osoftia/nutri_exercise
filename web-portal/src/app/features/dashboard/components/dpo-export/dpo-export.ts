import { Component, computed, inject, input } from '@angular/core';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';

import { AiInteraction } from '../../../../core/models/interaction.model';
import { ExportService } from '../../../../core/services/export.service';
import { isDpoEligible } from '../../../../core/utils/dpo-export.util';

@Component({
  selector: 'app-dpo-export',
  imports: [MatButtonModule, MatIconModule],
  templateUrl: './dpo-export.html',
  styleUrl: './dpo-export.scss',
})
export class DpoExport {
  readonly interactions = input<AiInteraction[]>([]);
  private readonly exportService = inject(ExportService);

  readonly ready = computed(() => this.interactions().filter(isDpoEligible).length);

  export(): void {
    this.exportService.downloadDpoDataset(this.interactions());
  }
}